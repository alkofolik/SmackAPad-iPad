#if DEBUG
import Foundation

/// Read-only output values for camera-based display/click measurements.
struct AudioTimingReadout {
    let route: String
    let presentationLatency: TimeInterval
    let sessionOutputLatency: TimeInterval
    let ioBufferDuration: TimeInterval
}
#endif
