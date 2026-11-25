//
//  SettingsManager+Calibration.swift
//  SmackAPad
//

import Foundation

// MARK: - Calibration Offset Management

extension SettingsManager {
    /// Reads a route-specific offset, falling back to calibration saved before routes were tracked.
    public func calibrationOffset(for deviceId: String, outputRoute: AudioOutputRoute) -> Double {
        withLock {
            calibrationOffsets[calibrationKey(for: deviceId, outputRoute: outputRoute)]
                ?? calibrationOffsets[deviceId]
                ?? 0
        }
    }

    /// Stores a signed offset for this input and output, capped at ±200 ms (SPEC §3.5).
    public func setCalibrationOffset(_ offsetMs: Double, for deviceId: String, outputRoute: AudioOutputRoute) {
        withLock {
            let capped = min(max(offsetMs, -200.0), 200.0)
            var updated = calibrationOffsets
            updated[calibrationKey(for: deviceId, outputRoute: outputRoute)] = capped
            self.calibrationOffsets = updated
        }
    }

    /// Removes all calibration offsets for an input, including its legacy fallback.
    public func removeCalibrationOffset(for deviceId: String) {
        withLock {
            var updated = calibrationOffsets
            updated.removeValue(forKey: deviceId)
            for route in AudioOutputRoute.allCases {
                updated.removeValue(forKey: calibrationKey(for: deviceId, outputRoute: route))
            }
            self.calibrationOffsets = updated
        }
    }

    private func calibrationKey(for deviceId: String, outputRoute: AudioOutputRoute) -> String {
        "\(deviceId)|\(outputRoute.rawValue)"
    }

    func persistCalibrationOffsets() {
        withLock {
            userDefaults.set(calibrationOffsets, forKey: SettingsKey.calibrationOffsets.rawValue)
        }
    }
}
