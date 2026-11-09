import AVFoundation

public enum AudioOutputRoute: String, CaseIterable, Sendable {
    case speaker, wired, bluetooth, other

    static var current: Self {
        Self(port: AVAudioSession.sharedInstance().currentRoute.outputs.first?.portType)
    }

    init(port: AVAudioSession.Port?) {
        switch port {
        case .builtInSpeaker: self = .speaker
        case .headphones, .lineOut, .usbAudio: self = .wired
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE: self = .bluetooth
        default: self = .other
        }
    }
}
