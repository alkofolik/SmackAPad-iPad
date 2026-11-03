import Darwin
import Foundation

/// Resolves unreliable MIDI timestamps without leaving the native mach clock domain.
public enum MIDITimestamp {
    private static let timebaseRatio: (numer: UInt64, denom: UInt64) = {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        return (UInt64(timebase.numer), UInt64(timebase.denom))
    }()

    public static func nanosecondsToTicks(_ ns: UInt64) -> UInt64 {
        ns * timebaseRatio.denom / timebaseRatio.numer
    }

    public static func ticksToNanoseconds(_ ticks: UInt64) -> UInt64 {
        ticks * timebaseRatio.numer / timebaseRatio.denom
    }

    private static let limits: (stale: UInt64, future: UInt64) = {
        (nanosecondsToTicks(250_000_000), nanosecondsToTicks(50_000_000))
    }()

    /// Resolves unreliable MIDI timestamps without leaving the native mach clock domain.
    /// Preserved for backwards compatibility with untracked calls.
    public static func resolve(_ timestamp: UInt64, receivedAt receipt: UInt64) -> UInt64 {
        guard timestamp != 0 else { return receipt }
        // Subtract in timestamp order so zero and UInt64.max cannot underflow or overflow.
        if timestamp <= receipt {
            return receipt - timestamp > limits.stale ? receipt : timestamp
        }
        return timestamp - receipt > limits.future ? receipt : timestamp
    }

    /// Tracks and estimates per-device clock offsets for Bluetooth MIDI controllers.
    public final class DeviceTracker: @unchecked Sendable {
        private struct DeviceState {
            var estimatedOffset: Int64?
            var lastReceipt: UInt64 = 0
        }

        private let lock = NSLock()
        private var devices: [String: DeviceState] = [:]
        private let maxLagTicks: UInt64 = nanosecondsToTicks(500_000_000)
        private let stepResetTicks: Int64 = Int64(nanosecondsToTicks(1_000_000_000))

        public init() {}

        public func reset(deviceID: String? = nil) {
            lock.lock()
            defer { lock.unlock() }
            if let deviceID {
                devices.removeValue(forKey: deviceID)
            } else {
                devices.removeAll()
            }
        }

        public func resolve(
            _ timestamp: UInt64,
            receivedAt receipt: UInt64,
            deviceID: String
        ) -> (timestamp: UInt64, usedReceiptTime: Bool) {
            guard timestamp != 0 else {
                return (receipt, true)
            }

            lock.lock()
            defer { lock.unlock() }

            var state = devices[deviceID] ?? DeviceState()
            let sampleOffset = Int64(receipt) - Int64(timestamp)

            if let currentOffset = state.estimatedOffset {
                let diff = sampleOffset - currentOffset
                if abs(diff) > stepResetTicks {
                    // Clock step change (e.g. device reconnect or clock reset)
                    state.estimatedOffset = sampleOffset
                } else if sampleOffset < currentOffset {
                    // Lower latency observed: fast converge to true lower bound
                    state.estimatedOffset = sampleOffset
                } else {
                    // Track slow clock drift without chasing BLE transmission jitter
                    let slew = Int64(Double(sampleOffset - currentOffset) * 0.05)
                    state.estimatedOffset = currentOffset + max(1, slew)
                }
            } else {
                state.estimatedOffset = sampleOffset
            }

            state.lastReceipt = receipt
            devices[deviceID] = state

            let offset = state.estimatedOffset ?? sampleOffset
            let mapped = Int64(timestamp) + offset
            var resolved = mapped > 0 ? UInt64(mapped) : receipt

            // A note cannot occur after its receipt time
            if resolved > receipt {
                resolved = receipt
            }
            if receipt >= resolved && receipt - resolved > maxLagTicks {
                resolved = receipt - maxLagTicks
            }

            return (resolved, false)
        }
    }

    public static let sharedTracker = DeviceTracker()

    public static func resolve(
        _ timestamp: UInt64,
        receivedAt receipt: UInt64,
        deviceID: String
    ) -> (timestamp: UInt64, usedReceiptTime: Bool) {
        sharedTracker.resolve(timestamp, receivedAt: receipt, deviceID: deviceID)
    }
}
