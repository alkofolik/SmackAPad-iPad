import Foundation

/// TEMPORARY ticket 09 diagnostics. Disable all output here; remove after iPad validation.
enum AudioTimingDiagnostics {
    static let enabled = true

    static func record(_ event: String, sessionOutputLatency: Double,
                       ioBufferDuration: Double, presentationLatency: Double) {
        #if DEBUG
        guard enabled else { return }
        let sessionAndBuffer = sessionOutputLatency + ioBufferDuration
        print(String(format:
            "[TEMP ticket09 timing] %@ | session+buffer=%.3f ms | mixerPresentation=%.3f ms | presentation-minus-session=%.3f ms",
            event, sessionAndBuffer * 1_000, presentationLatency * 1_000,
            (presentationLatency - sessionAndBuffer) * 1_000))
        #endif
    }
}
