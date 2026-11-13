import CoreMIDI
import Foundation
import GameController
import Observation

/// A normalized note event. Timestamps stay in the mach_absolute_time clock domain.
public struct MIDINoteEvent: Sendable {
    public let note: Int
    public let velocity: Int
    public let channel: Int
    public let isNoteOn: Bool
    public let timestamp: UInt64
    public let rawTimestamp: UInt64
    public let receiptTimestamp: UInt64
    public let usedReceiptTime: Bool
    public let deviceID: String

    public init(
        note: Int,
        velocity: Int,
        channel: Int,
        isNoteOn: Bool,
        timestamp: UInt64,
        rawTimestamp: UInt64 = 0,
        receiptTimestamp: UInt64 = 0,
        usedReceiptTime: Bool = false,
        deviceID: String
    ) {
        self.note = note
        self.velocity = velocity
        self.channel = channel
        self.isNoteOn = isNoteOn
        self.timestamp = timestamp
        self.rawTimestamp = rawTimestamp
        self.receiptTimestamp = receiptTimestamp
        self.usedReceiptTime = usedReceiptTime
        self.deviceID = deviceID
    }
}

public struct MIDISource: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
}

/// MIDI and touch use this same pad-index output, ready for audio/calibration/scoring consumers.
public struct PadInputEvent: Sendable {
    public let padIndex: Int
    public let velocity: Int
    public let isNoteOn: Bool
    public let timestamp: UInt64
    public let deviceID: String
    public let rawTimestamp: UInt64
    public let receiptTimestamp: UInt64
    public let usedReceiptTime: Bool

    public init(
        padIndex: Int,
        velocity: Int,
        isNoteOn: Bool,
        timestamp: UInt64,
        deviceID: String,
        rawTimestamp: UInt64 = 0,
        receiptTimestamp: UInt64 = 0,
        usedReceiptTime: Bool = false
    ) {
        self.padIndex = padIndex
        self.velocity = velocity
        self.isNoteOn = isNoteOn
        self.timestamp = timestamp
        self.deviceID = deviceID
        self.rawTimestamp = rawTimestamp
        self.receiptTimestamp = receiptTimestamp
        self.usedReceiptTime = usedReceiptTime
    }
}

@MainActor
@Observable
public final class MIDIInput {
    private var connectedSources: [MIDISource] = []
    private var networkSourceID: String?
    public var sources: [MIDISource] {
        connectedSources.map { source in
            guard source.id == networkSourceID else { return source }
            // iPadOS exposes one default CoreMIDI network session.
            return MIDISource(id: source.id, name: settings.localized("Network MIDI"))
        }
    }
    public private(set) var lastNote: MIDINoteEvent?
    public private(set) var lastControlMessage: MIDIControlMessage?
    public private(set) var controlLearningTarget: MIDIControlLearnTarget?
    public private(set) var pendingControlSignal: MIDIControlSignal?
    public private(set) var controlLearningNotice: String?
    public private(set) var lastPad: PadInputEvent?
    public private(set) var pressedPadIndices: Set<Int> = []
    public private(set) var pressedPadVelocities: [Int: Int] = [:]
    public private(set) var pressedControlVelocities: [MIDIControlSignal: Int] = [:]
    public var isControllerMonitorActive = false
    public private(set) var noteOnCount = 0
    public private(set) var fallbackCount = 0
    public private(set) var errorMessage: String?
    public var selectedSourceID: String? {
        didSet {
            if selectedSourceID != oldValue {
                releaseHeldPads()
                cancelLearning()
            }
        }
    }
    public private(set) var learningPadCount: Int? {
        didSet { updateSoundRoute() }
    }
    public private(set) var learnedNotes: [Int] = []
    public private(set) var learningGrid: PhysicalPadGrid?
    public private(set) var learningNotice: String?
    public private(set) var lesson: Lesson?
    public private(set) var isKeyboardConnected = false
    public var isCalibratingKeyboard = false

    /// Called for both presses and releases; no calibration or scoring correction is applied here.
    @ObservationIgnored public var onPadEvent: ((PadInputEvent) -> Void)?
    /// Calibration listens before profile mapping so any controller pad can tap the pulse.
    @ObservationIgnored public var onNoteEvent: ((MIDINoteEvent) -> Void)? {
        didSet { updateSoundRoute() }
    }
    @ObservationIgnored var onPracticeAction: ((MIDIPracticeAction) -> Void)?
    @ObservationIgnored var stoppedPracticeTempo: (() -> Int?)?
    @ObservationIgnored var onPracticeTempo: ((Int) -> Void)?
    @ObservationIgnored private var controlRouter = MIDIControlRouter()
    @ObservationIgnored private let settings: SettingsManager
    @ObservationIgnored private var client: MIDIClientRef = 0
    @ObservationIgnored private var ports: [MIDIEndpointRef: MIDIPortRef] = [:]
    @ObservationIgnored private var learningDeviceID: String?
    @ObservationIgnored private var learningChannel: Int?
    @ObservationIgnored private var heldPads: [String: Int] = [:]
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var keyboardConnectObserver: (any NSObjectProtocol)?
    @ObservationIgnored private var keyboardDisconnectObserver: (any NSObjectProtocol)?
    @ObservationIgnored private let liveSound = LiveSound()
    @ObservationIgnored private var soundEngine: AudioEngine?
    @ObservationIgnored private var observingSoundSettings = false

    /// The MIDI callback only reads a routing snapshot. Observable input state,
    /// controller actions and scoring still belong to the main actor.
    private final class LiveSound: @unchecked Sendable {
        struct Route {
            let generation: UUID
            let sources: Set<String>
            let padsByNote: [Int: Int]
            let controls: Set<MIDIControlSignal>
            let audio: AudioEngine
        }

        private let lock = NSLock()
        private var route: Route?

        func update(_ route: Route?) {
            lock.lock()
            self.route = route
            lock.unlock()
        }

        func play(_ events: [InputEvent], from deviceID: String, generation: UUID) {
            lock.lock()
            defer { lock.unlock() }
            guard let route, route.generation == generation, route.sources.contains(deviceID) else { return }
            for case .note(let note) in events where note.isNoteOn {
                let signal = MIDIControlSignal(kind: .note, channel: note.channel, number: note.note)
                guard !route.controls.contains(signal), let pad = route.padsByNote[note.note] else { continue }
                route.audio.play(padIndex: pad, velocity: note.velocity)
            }
        }
    }

    public init(settings: SettingsManager) {
        self.settings = settings
    }

    public var isLearning: Bool { learningPadCount != nil }
    public var isLearningControl: Bool { controlLearningTarget != nil }
    public var learningComplete: Bool { learnedNotes.count == learningPadCount }
    public var activeProfile: ControllerProfile { settings.activeProfile() }
    public var padIndices: [Int]? { padIndices(for: activeProfile) }

    private func padIndices(for profile: ControllerProfile) -> [Int]? {
        guard profile.isEightPad else { return Array(0..<16) }
        if let lesson { return EightPadLayout.slots(for: lesson) }
        return EightPadLayout.baseSlots
    }

    func setPracticeSound(_ audio: AudioEngine?) {
        soundEngine = audio
        updateSoundRoute()
        observeSoundSettings()
    }

    private func observeSoundSettings() {
        guard soundEngine != nil, !observingSoundSettings else { return }
        observingSoundSettings = true
        withObservationTracking {
            _ = settings.midiControls
            _ = settings.activeProfile()
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observingSoundSettings = false
                self.updateSoundRoute()
                self.observeSoundSettings()
            }
        }
    }

    private func updateSoundRoute() {
        guard let soundEngine, !isLearning, !isLearningControl, onNoteEvent == nil else {
            liveSound.update(nil)
            return
        }
        let profile = activeProfile
        guard let pads = padIndices(for: profile) else {
            liveSound.update(nil)
            return
        }
        let sources = connectedSources.map(\.id).filter { selectedSourceID == nil || $0 == selectedSourceID }
        let padsByNote = profile.noteMap.compactMapValues { pads.indices.contains($0) ? pads[$0] : nil }
        let config = settings.midiControls
        var controls = Set(MIDIPracticeAction.allCases.compactMap { config.buttons[$0.rawValue]?.signal })
        if let signal = config.knob.signal { controls.insert(signal) }
        liveSound.update(.init(generation: generation, sources: Set(sources),
                               padsByNote: padsByNote, controls: controls, audio: soundEngine))
    }

    public func setLesson(_ lesson: Lesson?) {
        releaseHeldPads()
        self.lesson = lesson
        updateSoundRoute()
    }

    public func profileDidChange() {
        releaseHeldPads()
        cancelLearning()
    }

    public func start() {
        startKeyboard()
        guard client == 0 else { return }
        errorMessage = nil
        let status = MIDIClientCreateWithBlock("Smack-a-Pad" as CFString, &client) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshSources() }
        }
        guard status == noErr else {
            errorMessage = "CoreMIDI client: \(status)"
            client = 0
            return
        }
        refreshSources()
    }

    public func stop() {
        stopKeyboard()
        generation = UUID()
        releaseHeldPads()
        cancelLearning()
        for port in ports.values { MIDIPortDispose(port) }
        ports.removeAll()
        if client != 0 { MIDIClientDispose(client) }
        client = 0
        connectedSources = []
        networkSourceID = nil
        updateSoundRoute()
    }

    private func refreshSources() {
        guard client != 0 else { return }
        let endpoints = (0..<MIDIGetNumberOfSources()).map { MIDIGetSource($0) }.filter { $0 != 0 }
        let removed = ports.keys.filter { !endpoints.contains($0) }
        if !removed.isEmpty {
            releaseHeldPads()
            cancelLearning()
        }
        for endpoint in removed {
            if let port = ports.removeValue(forKey: endpoint) { MIDIPortDispose(port) }
        }
        var connected: [MIDISource] = []
        let networkEndpoint = MIDINetworkSession.default().sourceEndpoint()
        networkSourceID = nil
        for endpoint in endpoints {
            var uniqueID: MIDIUniqueID = 0
            let idStatus = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
            let deviceID = idStatus == noErr ? "midi:\(uniqueID)" : "endpoint:\(endpoint)"
            if endpoint == networkEndpoint { networkSourceID = deviceID }
            var displayName: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &displayName)
            let name = displayName?.takeRetainedValue() as String? ?? deviceID
            if ports[endpoint] == nil {
                var port: MIDIPortRef = 0
                let session = generation
                // CoreMIDI translates MIDI 1.0/2.0 sources into MIDI 1.0 UMP packets.
                let status = MIDIInputPortCreateWithProtocol(
                    client, name as CFString, ._1_0, &port
                ) { [weak self, liveSound] eventList, _ in
                    let receipt = mach_absolute_time()
                    let events = Self.inputEvents(in: eventList, receipt: receipt, deviceID: deviceID)
                    guard !events.isEmpty else { return }
                    liveSound.play(events, from: deviceID, generation: session)
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == session,
                              self.sources.contains(where: { $0.id == deviceID }) else { return }
                        for event in events {
                            switch event {
                            case .note(let note): self.receive(note)
                            case .cc(let message): self.receiveControlChange(message)
                            }
                        }
                    }
                }
                guard status == noErr else {
                    errorMessage = "MIDI input port (\(name)): \(status)"
                    continue
                }
                let connectionStatus = MIDIPortConnectSource(port, endpoint, nil)
                guard connectionStatus == noErr else {
                    MIDIPortDispose(port)
                    errorMessage = "MIDI connection (\(name)): \(connectionStatus)"
                    continue
                }
                ports[endpoint] = port
            }
            connected.append(MIDISource(id: deviceID, name: name))
        }
        connectedSources = connected
        if let selectedSourceID, !sources.contains(where: { $0.id == selectedSourceID }) {
            self.selectedSourceID = nil
        }
        updateSoundRoute()
    }

    private enum InputEvent: Sendable {
        case note(MIDINoteEvent)
        case cc(MIDIControlMessage)
    }

    /// Copies note and CC messages in packet order; never keeps packet pointers.
    nonisolated private static func inputEvents(
        in list: UnsafePointer<MIDIEventList>, receipt: UInt64, deviceID: String
    ) -> [InputEvent] {
        var events: [InputEvent] = []
        withUnsafePointer(to: list.pointee.packet) { first in
            var packet = first
            for _ in 0..<list.pointee.numPackets {
                let rawTimestamp = packet.pointee.timeStamp
                let resolved = MIDITimestamp.resolve(rawTimestamp, receivedAt: receipt, deviceID: deviceID)
                withUnsafePointer(to: packet.pointee.words) { tuple in
                    tuple.withMemoryRebound(to: UInt32.self, capacity: Int(packet.pointee.wordCount)) { words in
                        var index = 0
                        while index < Int(packet.pointee.wordCount) {
                            let word = words[index]
                            let type = Int(word >> 28)
                            // UMP lengths, including non-note utility, system and SysEx messages.
                            let lengths = [1, 1, 1, 2, 2, 4, 1, 1, 2, 2, 2, 3, 3, 4, 4, 4]
                            let length = lengths[type]
                            guard index + length <= Int(packet.pointee.wordCount) else { break }
                            if type == 2 {
                                let status = (word >> 20) & 0xF
                                if status == 0x8 || status == 0x9 {
                                    let velocity = Int(word & 0x7F)
                                    events.append(.note(MIDINoteEvent(
                                        note: Int((word >> 8) & 0x7F), velocity: velocity,
                                        channel: Int((word >> 16) & 0xF) + 1,
                                        isNoteOn: status == 0x9 && velocity > 0,
                                        timestamp: resolved.timestamp, rawTimestamp: rawTimestamp, receiptTimestamp: receipt,
                                        usedReceiptTime: resolved.usedReceiptTime, deviceID: deviceID
                                    )))
                                } else if status == 0xB {
                                    events.append(.cc(MIDIControlMessage(
                                        signal: MIDIControlSignal(kind: .cc, channel: Int((word >> 16) & 0xF) + 1,
                                                                  number: Int((word >> 8) & 0x7F)),
                                        value: Int(word & 0x7F), deviceID: deviceID, timestamp: resolved.timestamp
                                    )))
                                }
                            }
                            index += length
                        }
                    }
                }
                packet = UnsafePointer(MIDIEventPacketNext(packet))
            }
        }
        return events
    }

    private func receive(_ event: MIDINoteEvent) {
        guard selectedSourceID == nil || selectedSourceID == event.deviceID else { return }
        lastNote = event
        if event.usedReceiptTime { fallbackCount += 1 }
        if event.isNoteOn { noteOnCount += 1 }
        let message = MIDIControlMessage(
            signal: MIDIControlSignal(kind: .note, channel: event.channel, number: event.note),
            value: event.isNoteOn ? event.velocity : 0, deviceID: event.deviceID, timestamp: event.timestamp)
        lastControlMessage = message
        if isLearningControl { learnControl(message); return }
        if isLearning {
            if event.isNoteOn { learn(event) }
            return
        }
        guard !routeControl(message) else { return }
        onNoteEvent?(event)
        let key = "\(event.deviceID)/\(event.channel)/\(event.note)"
        let padIndex: Int
        if event.isNoteOn {
            guard let target = activeProfile.target(forMidiNote: event.note),
                  let pads = padIndices, pads.indices.contains(target) else { return }
            padIndex = pads[target]
            heldPads[key] = padIndex
        } else {
            guard let held = heldPads.removeValue(forKey: key) else { return }
            padIndex = held
        }
        emit(PadInputEvent(
            padIndex: padIndex, velocity: event.velocity,
            isNoteOn: event.isNoteOn, timestamp: event.timestamp, deviceID: event.deviceID,
            rawTimestamp: event.rawTimestamp, receiptTimestamp: event.receiptTimestamp,
            usedReceiptTime: event.usedReceiptTime
        ))
    }

    private func receiveControlChange(_ message: MIDIControlMessage) {
        guard selectedSourceID == nil || selectedSourceID == message.deviceID else { return }
        lastControlMessage = message
        if isLearningControl { learnControl(message); return }
        guard !isLearning else { return }
        _ = routeControl(message)
    }

    /// Returning true prevents the message from ever reaching pad/audio/scoring consumers.
    private func routeControl(_ message: MIDIControlMessage) -> Bool {
        if settings.midiControls.buttons.values.contains(where: { $0.signal == message.signal }) {
            pressedControlVelocities[message.signal] = message.value > 0 ? message.value : nil
        }
        switch controlRouter.route(message, configuration: settings.midiControls,
                                   stoppedTempo: stoppedPracticeTempo?()) {
        case .pad: return false
        case .consumed: return true
        case .action(let action):
            if !isControllerMonitorActive { onPracticeAction?(action) }
            return true
        case .tempo(let bpm):
            if !isControllerMonitorActive { onPracticeTempo?(bpm) }
            return true
        }
    }

    func resetControlPickup() { controlRouter.resetPickup() }

    public func startControlLearning(_ target: MIDIControlLearnTarget) {
        releaseHeldPads()
        cancelLearning()
        controlLearningTarget = target
        updateSoundRoute()
    }

    public func cancelControlLearning() {
        controlLearningTarget = nil
        pendingControlSignal = nil
        controlLearningNotice = nil
        updateSoundRoute()
    }

    private func learnControl(_ message: MIDIControlMessage) {
        guard let target = controlLearningTarget, pendingControlSignal == nil,
              message.signal.kind == .cc || message.value > 0 else { return }
        if target == .knob && message.signal.kind != .cc { return }
        guard !settings.midiControls.conflicts(message.signal, excluding: target) else {
            controlLearningNotice = "This signal is already assigned. Clear its other mapping first."
            return
        }
        if message.signal.kind == .note, activeProfile.target(forMidiNote: message.signal.number) != nil {
            pendingControlSignal = message.signal
            return
        }
        assignControl(message.signal, to: target)
    }

    public func confirmControlMapping() {
        guard let signal = pendingControlSignal, let target = controlLearningTarget else { return }
        guard !settings.midiControls.conflicts(signal, excluding: target) else {
            pendingControlSignal = nil
            controlLearningNotice = "This signal is already assigned. Clear its other mapping first."
            return
        }
        assignControl(signal, to: target)
    }

    private func assignControl(_ signal: MIDIControlSignal, to target: MIDIControlLearnTarget) {
        var configuration = settings.midiControls
        switch target {
        case .action(let action):
            let behavior = configuration.buttons[action.rawValue]?.behavior ?? .rising64
            configuration.buttons[action.rawValue] = MIDIButtonMapping(signal: signal, behavior: behavior)
        case .knob: configuration.knob.signal = signal
        }
        settings.midiControls = configuration
        controlRouter = MIDIControlRouter()
        cancelControlLearning()
    }

    public func clearControlMapping(_ target: MIDIControlLearnTarget) {
        cancelControlLearning()
        var configuration = settings.midiControls
        switch target {
        case .action(let action): configuration.buttons.removeValue(forKey: action.rawValue)
        case .knob: configuration.knob.signal = nil
        }
        settings.midiControls = configuration
    }

    public func touch(padIndex: Int, isPressed: Bool) {
        guard !isLearning, !isLearningControl, padIndices?.contains(padIndex) == true else { return }
        let key = "touch/\(padIndex)"
        if isPressed { heldPads[key] = padIndex }
        else if heldPads.removeValue(forKey: key) == nil { return }
        emit(PadInputEvent(padIndex: padIndex, velocity: isPressed ? 100 : 0,
                           isNoteOn: isPressed, timestamp: mach_absolute_time(), deviceID: "touch"))
    }

    public func keyboard(padIndex: Int, isPressed: Bool, timestamp: UInt64 = mach_absolute_time()) {
        let key = "keyboard/\(padIndex)"
        if isPressed {
            guard !isLearning, !isLearningControl,
                  settings.playPadsWithKeyboard,
                  activeProfile.isSixteenPad,
                  (lesson != nil || isCalibratingKeyboard),
                  padIndices?.contains(padIndex) == true else { return }
            guard heldPads[key] == nil else { return }
            heldPads[key] = padIndex
        } else {
            guard heldPads.removeValue(forKey: key) != nil else { return }
        }
        emit(PadInputEvent(padIndex: padIndex, velocity: isPressed ? 100 : 0,
                           isNoteOn: isPressed, timestamp: timestamp, deviceID: "keyboard"))
    }

    private func startKeyboard() {
        updateKeyboardConnection()
        if keyboardConnectObserver == nil {
            keyboardConnectObserver = NotificationCenter.default.addObserver(
                forName: .GCKeyboardDidConnect, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.updateKeyboardConnection() }
            }
        }
        if keyboardDisconnectObserver == nil {
            keyboardDisconnectObserver = NotificationCenter.default.addObserver(
                forName: .GCKeyboardDidDisconnect, object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.updateKeyboardConnection() }
            }
        }
    }

    private func stopKeyboard() {
        if let observer = keyboardConnectObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardConnectObserver = nil
        }
        if let observer = keyboardDisconnectObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardDisconnectObserver = nil
        }
        if let keyboard = GCKeyboard.coalesced {
            keyboard.keyboardInput?.keyChangedHandler = nil
        }
        releaseKeyboardPads()
        isKeyboardConnected = false
    }

    private func updateKeyboardConnection() {
        let connected = GCKeyboard.coalesced != nil
        isKeyboardConnected = connected
        guard let keyboard = GCKeyboard.coalesced, let input = keyboard.keyboardInput else {
            releaseKeyboardPads()
            return
        }
        input.keyChangedHandler = { [weak self] keyboardInput, key, keyCode, pressed in
            let timestamp = mach_absolute_time()
            guard !KeyboardPadMapping.isModifier(keyCode: keyCode) else { return }
            if pressed {
                let modifierHeld = keyboardInput.button(forKeyCode: .leftGUI)?.isPressed == true ||
                                   keyboardInput.button(forKeyCode: .rightGUI)?.isPressed == true ||
                                   keyboardInput.button(forKeyCode: .leftControl)?.isPressed == true ||
                                   keyboardInput.button(forKeyCode: .rightControl)?.isPressed == true ||
                                   keyboardInput.button(forKeyCode: .leftAlt)?.isPressed == true ||
                                   keyboardInput.button(forKeyCode: .rightAlt)?.isPressed == true
                guard !modifierHeld else { return }
            }
            guard let padIndex = KeyboardPadMapping.padIndex(for: keyCode) else { return }
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.keyboard(padIndex: padIndex, isPressed: pressed, timestamp: timestamp)
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.keyboard(padIndex: padIndex, isPressed: pressed, timestamp: timestamp)
                }
            }
        }
    }

    private func releaseKeyboardPads() {
        let timestamp = mach_absolute_time()
        let keyboardKeys = heldPads.keys.filter { $0.hasPrefix("keyboard/") }
        for key in keyboardKeys {
            if let padIndex = heldPads.removeValue(forKey: key) {
                emit(PadInputEvent(padIndex: padIndex, velocity: 0, isNoteOn: false,
                                   timestamp: timestamp, deviceID: "keyboard"))
            }
        }
    }

    private func emit(_ event: PadInputEvent) {
        if event.isNoteOn, onNoteEvent == nil, event.deviceID == "touch" || event.deviceID == "keyboard" {
            soundEngine?.play(padIndex: event.padIndex, velocity: event.velocity)
        }
        pressedPadIndices = Set(heldPads.values)
        if event.isNoteOn { pressedPadVelocities[event.padIndex] = event.velocity }
        else if !pressedPadIndices.contains(event.padIndex) { pressedPadVelocities.removeValue(forKey: event.padIndex) }
        lastPad = event
        onPadEvent?(event)
    }

    private func releaseHeldPads() {
        controlRouter = MIDIControlRouter()
        pressedControlVelocities = [:]
        let timestamp = mach_absolute_time()
        let pending = heldPads
        heldPads.removeAll()
        for (key, padIndex) in pending {
            let deviceID = key.components(separatedBy: "/").first ?? "touch"
            emit(PadInputEvent(padIndex: padIndex, velocity: 0, isNoteOn: false,
                               timestamp: timestamp, deviceID: deviceID))
        }
    }

    public func startLearning(padCount: Int, grid: PhysicalPadGrid? = nil) {
        let arrangement = grid ?? .defaultArrangement(padCount: padCount)
        guard PhysicalPadGrid.arrangements(padCount: padCount).contains(arrangement) else { return }
        releaseHeldPads()
        cancelLearning()
        learningPadCount = padCount
        learningGrid = arrangement
    }

    public func cancelLearning() {
        cancelControlLearning()
        learningPadCount = nil
        learningGrid = nil
        learnedNotes = []
        learningDeviceID = nil
        learningChannel = nil
        learningNotice = nil
    }

    private func learn(_ event: MIDINoteEvent) {
        guard let count = learningPadCount, learnedNotes.count < count else { return }
        if let learningDeviceID,
           learningDeviceID != event.deviceID || learningChannel != event.channel { return }
        guard !learnedNotes.contains(event.note) else {
            learningNotice = "duplicateNote"
            return
        }
        learningDeviceID = event.deviceID
        learningChannel = event.channel
        learnedNotes.append(event.note)
        learningNotice = nil
    }

    public func saveLearnedProfile(name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let count = learningPadCount, let grid = learningGrid, learnedNotes.count == count,
              !trimmed.isEmpty, settings.profile(named: trimmed) == nil else { return false }
        let map = Dictionary(uniqueKeysWithValues: learnedNotes.enumerated().map {
            ($0.element, PhysicalPadGrid.target(forSlot: $0.offset, padCount: count))
        })
        settings.saveProfile(ControllerProfile(profileName: trimmed, noteMap: map, padCount: count,
                                               rows: grid.rows, columns: grid.columns))
        settings.activeProfileName = trimmed
        cancelLearning()
        return true
    }
}
