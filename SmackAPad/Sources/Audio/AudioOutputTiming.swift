import Foundation

/// The audio adapter's single render-to-presentation model, shared by both flows.
/// No MIDI offset or scoring-window adjustment belongs here.
public struct AudioOutputTiming: Sendable {
    public let presentationLatency: TimeInterval

    public init?(presentationLatency: TimeInterval) {
        guard presentationLatency.isFinite, presentationLatency > 0 else { return nil }
        self.presentationLatency = presentationLatency
    }

    public func renderTime(forAudibleTime time: TimeInterval) -> TimeInterval {
        time - presentationLatency
    }

    public func audibleTime(forRenderTime time: TimeInterval) -> TimeInterval {
        time + presentationLatency
    }
}
