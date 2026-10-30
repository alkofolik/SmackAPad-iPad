import CoreMIDI
import Foundation
import Observation

/// A normalized note event. Timestamps stay in the mach_absolute_time clock domain.
public struct MIDINoteEvent: Sendable {
    public let note: Int
    public let velocity: Int
    public let channel: Int
    public let isNoteOn: Bool
    public let timestamp: UInt64
    public let receiptTimestamp: UInt64
    public let usedReceiptTime: Bool
    public let deviceID: String
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
}

@MainActor
@Observable
public final class MIDIInput {
    public private(set) var sources: [MIDISource] = []
    public private(set) var lastNote: MIDINoteEvent?
    public private(set) var lastPad: PadInputEvent?
    public private(set) var pressedPadIndices: Set<Int> = []
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
    public private(set) var learningPadCount: Int?
    public private(set) var learnedNotes: [Int] = []
    public private(set) var learningNotice: String?
    public private(set) var lesson: Lesson?

    /// Called for both presses and releases; no calibration or scoring correction is applied here.
    @ObservationIgnored public var onPadEvent: ((PadInputEvent) -> Void)?
    /// Calibration listens before profile mapping so any controller pad can tap the pulse.
    @ObservationIgnored public var onNoteEvent: ((MIDINoteEvent) -> Void)?
    @ObservationIgnored private let settings: SettingsManager
    @ObservationIgnored private var client: MIDIClientRef = 0
    @ObservationIgnored private var ports: [MIDIEndpointRef: MIDIPortRef] = [:]
    @ObservationIgnored private var learningDeviceID: String?
    @ObservationIgnored private var learningChannel: Int?
    @ObservationIgnored private var heldPads: [String: Int] = [:]
    @ObservationIgnored private var generation = UUID()

    public init(settings: SettingsManager) {
        self.settings = settings
    }

    public var isLearning: Bool { learningPadCount != nil }
    public var learningComplete: Bool { learnedNotes.count == learningPadCount }
    public var activeProfile: ControllerProfile { settings.activeProfile() }
    public var padIndices: [Int]? {
        guard activeProfile.isEightPad else { return Array(0..<16) }
        if let lesson { return EightPadLayout.slots(for: lesson) }
        return EightPadLayout.baseSlots
    }

    public func setLesson(_ lesson: Lesson?) {
        releaseHeldPads()
        self.lesson = lesson
    }

    public func profileDidChange() {
        releaseHeldPads()
        cancelLearning()
    }

    public func start() {
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
        generation = UUID()
        releaseHeldPads()
        cancelLearning()
        for port in ports.values { MIDIPortDispose(port) }
        ports.removeAll()
        if client != 0 { MIDIClientDispose(client) }
        client = 0
        sources = []
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
        for endpoint in endpoints {
            var uniqueID: MIDIUniqueID = 0
            let idStatus = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &uniqueID)
            let deviceID = idStatus == noErr ? "midi:\(uniqueID)" : "endpoint:\(endpoint)"
            var displayName: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &displayName)
            let name = displayName?.takeRetainedValue() as String? ?? deviceID
            if ports[endpoint] == nil {
                var port: MIDIPortRef = 0
                let session = generation
                // CoreMIDI translates MIDI 1.0/2.0 sources into MIDI 1.0 UMP packets.
                let status = MIDIInputPortCreateWithProtocol(
                    client, name as CFString, ._1_0, &port
                ) { [weak self] eventList, _ in
                    let receipt = mach_absolute_time()
                    let events = Self.noteEvents(in: eventList, receipt: receipt, deviceID: deviceID)
                    guard !events.isEmpty else { return }
                    Task { @MainActor [weak self] in
                        guard let self, self.generation == session,
                              self.sources.contains(where: { $0.id == deviceID }) else { return }
                        for event in events { self.receive(event) }
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
        sources = connected
        if let selectedSourceID, !sources.contains(where: { $0.id == selectedSourceID }) {
            self.selectedSourceID = nil
        }
    }

    /// Copies only note messages before leaving CoreMIDI's callback; never keeps packet pointers.
    nonisolated private static func noteEvents(
        in list: UnsafePointer<MIDIEventList>, receipt: UInt64, deviceID: String
    ) -> [MIDINoteEvent] {
        var events: [MIDINoteEvent] = []
        withUnsafePointer(to: list.pointee.packet) { first in
            var packet = first
            for _ in 0..<list.pointee.numPackets {
                let rawTimestamp = packet.pointee.timeStamp
                let timestamp = MIDITimestamp.resolve(rawTimestamp, receivedAt: receipt)
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
                                    events.append(MIDINoteEvent(
                                        note: Int((word >> 8) & 0x7F), velocity: velocity,
                                        channel: Int((word >> 16) & 0xF) + 1,
                                        isNoteOn: status == 0x9 && velocity > 0,
                                        timestamp: timestamp, receiptTimestamp: receipt,
                                        usedReceiptTime: timestamp != rawTimestamp, deviceID: deviceID
                                    ))
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
        onNoteEvent?(event)
        if event.usedReceiptTime { fallbackCount += 1 }
        if event.isNoteOn { noteOnCount += 1 }
        if isLearning {
            if event.isNoteOn { learn(event) }
            return
        }
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
        emit(PadInputEvent(padIndex: padIndex, velocity: event.velocity,
                           isNoteOn: event.isNoteOn, timestamp: event.timestamp, deviceID: event.deviceID))
    }

    public func touch(padIndex: Int, isPressed: Bool) {
        guard !isLearning, padIndices?.contains(padIndex) == true else { return }
        let key = "touch/\(padIndex)"
        if isPressed { heldPads[key] = padIndex }
        else if heldPads.removeValue(forKey: key) == nil { return }
        emit(PadInputEvent(padIndex: padIndex, velocity: isPressed ? 100 : 0,
                           isNoteOn: isPressed, timestamp: mach_absolute_time(), deviceID: "touch"))
    }

    private func emit(_ event: PadInputEvent) {
        pressedPadIndices = Set(heldPads.values)
        lastPad = event
        onPadEvent?(event)
    }

    private func releaseHeldPads() {
        let timestamp = mach_absolute_time()
        let pending = heldPads
        heldPads.removeAll()
        for (key, padIndex) in pending {
            let deviceID = key.components(separatedBy: "/").first ?? "touch"
            emit(PadInputEvent(padIndex: padIndex, velocity: 0, isNoteOn: false,
                               timestamp: timestamp, deviceID: deviceID))
        }
    }

    public func startLearning(padCount: Int) {
        guard padCount == 8 || padCount == 16 else { return }
        releaseHeldPads()
        cancelLearning()
        learningPadCount = padCount
    }

    public func cancelLearning() {
        learningPadCount = nil
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
        guard let count = learningPadCount, learnedNotes.count == count,
              !trimmed.isEmpty, settings.profile(named: trimmed) == nil else { return false }
        // Learn order follows the grid, left-to-right, top row first. Eight-pad values are slots.
        let map = Dictionary(uniqueKeysWithValues: learnedNotes.enumerated().map { ($0.element, $0.offset) })
        settings.saveProfile(ControllerProfile(profileName: trimmed, noteMap: map, padCount: count))
        settings.activeProfileName = trimmed
        cancelLearning()
        return true
    }
}
