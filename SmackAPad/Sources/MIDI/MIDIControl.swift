import Foundation

public enum MIDIControlKind: String, Codable, Sendable { case note, cc }

public struct MIDIControlSignal: Codable, Hashable, Sendable {
    public var kind: MIDIControlKind
    public var channel: Int
    public var number: Int

    var isValid: Bool { (1...16).contains(channel) && (0...127).contains(number) }
    var label: String { "\(kind == .cc ? "CC" : "Note") \(number) · ch \(channel)" }
}

public struct MIDIControlMessage: Sendable {
    public let signal: MIDIControlSignal
    public let value: Int
    public let deviceID: String
    public let timestamp: UInt64

    public init(signal: MIDIControlSignal, value: Int, deviceID: String, timestamp: UInt64 = 0) {
        self.signal = signal
        self.value = value
        self.deviceID = deviceID
        self.timestamp = timestamp
    }
}

public enum MIDIPracticeAction: String, CaseIterable, Codable, Sendable {
    case startStop, restart, listen, tempoDown, tempoUp

    static let tempoButtonStep = 5
    var title: String {
        switch self {
        case .startStop: return "Start / stop"
        case .restart: return "Restart"
        case .listen: return "Listen"
        case .tempoDown: return "Tempo −"
        case .tempoUp: return "Tempo +"
        }
    }
}

public enum MIDICCButtonBehavior: String, CaseIterable, Codable, Sendable {
    case rising64, nonzero, everyChange
    var title: String {
        switch self {
        case .rising64: return "Press ≥ 64 (rising edge)"
        case .nonzero: return "Press > 0, release = 0"
        case .everyChange: return "Every value change"
        }
    }

    func triggers(previous: Int, value: Int) -> Bool {
        switch self {
        case .rising64: return previous < 64 && value >= 64
        case .nonzero: return previous == 0 && value > 0
        case .everyChange: return previous != value
        }
    }
}

public struct MIDIButtonMapping: Codable, Equatable, Sendable {
    public var signal: MIDIControlSignal
    public var behavior: MIDICCButtonBehavior = .rising64
}

public enum MIDIKnobMode: String, CaseIterable, Codable, Sendable {
    case absolute, twosComplement, binaryOffset, signedBit
    var title: String {
        switch self {
        case .absolute: return "Absolute 0–127"
        case .twosComplement: return "Relative · 1 / 127"
        case .binaryOffset: return "Relative · 65 / 63"
        case .signedBit: return "Relative · 1 / 65"
        }
    }

    /// Each decoded encoder step changes the tempo by one BPM, including accelerated turns.
    func relativeSteps(_ value: Int) -> Int {
        switch self {
        case .absolute: return 0
        case .twosComplement: return value < 64 ? value : value - 128
        case .binaryOffset: return value - 64
        case .signedBit: return value < 64 ? value : -(value & 63)
        }
    }
}

public struct MIDITempoKnob: Codable, Equatable, Sendable {
    public var signal: MIDIControlSignal?
    public var mode: MIDIKnobMode = .absolute
    public var minimumBpm = PracticeTempo.minimumBpm
    public var maximumBpm = PracticeTempo.maximumBpm
    public var pickup = true
    public var reversed = false

    public init() {}

    public init(
        signal: MIDIControlSignal? = nil,
        mode: MIDIKnobMode = .absolute,
        minimumBpm: Int = 30,
        maximumBpm: Int = 400,
        pickup: Bool = true,
        reversed: Bool = false
    ) {
        self.signal = signal
        self.mode = mode
        self.minimumBpm = minimumBpm
        self.maximumBpm = maximumBpm
        self.pickup = pickup
        self.reversed = reversed
    }

    var range: ClosedRange<Int> {
        let low = PracticeTempo.clamp(minimumBpm)
        return low...max(low, PracticeTempo.clamp(maximumBpm))
    }
}

public struct MIDIControlConfiguration: Codable, Equatable, Sendable {
    // Raw action keys keep the UserDefaults JSON readable and extensible.
    public var buttons: [String: MIDIButtonMapping] = [:]
    public var knob = MIDITempoKnob()

    public init() {}

    public init(buttons: [String: MIDIButtonMapping], knob: MIDITempoKnob = MIDITempoKnob()) {
        self.buttons = buttons
        self.knob = knob
    }

    func conflicts(_ signal: MIDIControlSignal, excluding target: MIDIControlLearnTarget) -> Bool {
        buttons.contains { key, mapping in
            mapping.signal == signal && target != .action(MIDIPracticeAction(rawValue: key) ?? .startStop)
        } || (target != .knob && knob.signal == signal)
    }

    /// Invalid or duplicate assignments are discarded on load rather than stealing pad input.
    func validated() -> Self {
        var clean = Self()
        var used: Set<MIDIControlSignal> = []
        for action in MIDIPracticeAction.allCases {
            if let mapping = buttons[action.rawValue], mapping.signal.isValid,
               used.insert(mapping.signal).inserted {
                clean.buttons[action.rawValue] = mapping
            }
        }
        clean.knob = knob
        clean.knob.minimumBpm = knob.range.lowerBound
        clean.knob.maximumBpm = knob.range.upperBound
        if let signal = knob.signal,
           !signal.isValid || signal.kind != .cc || used.contains(signal) { clean.knob.signal = nil }
        return clean
    }
}

public enum MIDIControlLearnTarget: Equatable, Sendable {
    case action(MIDIPracticeAction), knob
}

/// Routing happens before pad mapping. Even releases and ignored controls are consumed.
enum MIDIControlRoute: Equatable {
    case pad, consumed, action(MIDIPracticeAction), tempo(Int)
}

struct MIDIControlRouter {
    private struct InputKey: Hashable {
        let deviceID: String
        let signal: MIDIControlSignal
    }
    private var previousValues: [InputKey: Int] = [:]
    private var configuration: MIDIControlConfiguration?
    private var pickupDevice: String?
    private var lastAbsoluteBpm: Double?
    private var expectedTempo: Int?
    private var pickedUp = false

    mutating func resetPickup() {
        pickupDevice = nil
        lastAbsoluteBpm = nil
        expectedTempo = nil
        pickedUp = false
    }

    mutating func route(_ message: MIDIControlMessage, configuration config: MIDIControlConfiguration,
                        stoppedTempo: Int?) -> MIDIControlRoute {
        if configuration != config {
            previousValues = [:]
            resetPickup()
            configuration = config
        }
        let signal = message.signal
        let value = message.value
        let key = InputKey(deviceID: message.deviceID, signal: signal)
        if let action = MIDIPracticeAction.allCases.first(where: { config.buttons[$0.rawValue]?.signal == signal }),
           let mapping = config.buttons[action.rawValue] {
            let previous = previousValues[key] ?? 0
            previousValues[key] = value
            let fires = signal.kind == .note
                ? previous == 0 && value > 0
                : mapping.behavior.triggers(previous: previous, value: value)
            return fires ? .action(action) : .consumed
        }
        guard config.knob.signal == signal else { return .pad }
        guard let current = stoppedTempo else { resetPickup(); return .consumed }
        let knob = config.knob
        if knob.mode != .absolute {
            let steps = knob.mode.relativeSteps(value) * (knob.reversed ? -1 : 1)
            return steps == 0 ? .consumed : .tempo(PracticeTempo.clamp(current + steps))
        }
        if expectedTempo != current || pickupDevice != message.deviceID {
            resetPickup()
            expectedTempo = current
            pickupDevice = message.deviceID
        }
        let range = knob.range
        let normalized = knob.reversed ? 127 - value : value
        let mapped = Double(range.lowerBound) + Double(normalized) / 127 * Double(range.upperBound - range.lowerBound)
        // Outside a narrowed knob range, reaching the nearest end permits takeover.
        let target = Double(min(range.upperBound, max(range.lowerBound, current)))
        let crossed = lastAbsoluteBpm.map { min($0, mapped) <= target && max($0, mapped) >= target } ?? false
        if !knob.pickup || Int(mapped.rounded()) == Int(target) || crossed { pickedUp = true }
        lastAbsoluteBpm = mapped
        guard pickedUp else { return .consumed }
        let tempo = Int(mapped.rounded())
        expectedTempo = tempo
        return .tempo(tempo)
    }
}
