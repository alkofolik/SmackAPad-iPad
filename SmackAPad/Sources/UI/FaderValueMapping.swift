//
//  FaderValueMapping.swift
//  SmackAPad
//

import CoreGraphics
import Foundation

/// Pure mapping between fader cap position and volume percent.
public enum FaderValueMapping {
    /// Maps a normalized position along the fader travel (0.0 = bottom / silence, 1.0 = top / 0 dB)
    /// to volume percent (0...100 in steps of 5%, clamped).
    public static func volumePercent(fromNormalizedPosition position: CGFloat) -> Int {
        let clamped = min(max(position, 0.0), 1.0)
        let rawPercent = Int((clamped * 100.0).rounded())
        return SettingsManager.clampVolume(rawPercent)
    }

    /// Maps a volume percent (0...100) to normalized position along the fader travel (0.0 = bottom, 1.0 = top).
    public static func normalizedPosition(fromVolumePercent percent: Int) -> CGFloat {
        let clamped = SettingsManager.clampVolume(percent)
        return CGFloat(clamped) / 100.0
    }

    /// Maps a touch Y coordinate within [minY, maxY] to volume percent.
    /// In screen coordinates, minY is the top (100% / 0 dB) and maxY is the bottom (0% / −∞ dB).
    public static func volumePercent(fromY y: CGFloat, minY: CGFloat, maxY: CGFloat) -> Int {
        guard maxY > minY else { return 0 }
        let normalized = (maxY - y) / (maxY - minY)
        return volumePercent(fromNormalizedPosition: normalized)
    }

    /// Maps a volume percent to a Y coordinate within [minY, maxY].
    /// In screen coordinates, minY is the top (100% / 0 dB) and maxY is the bottom (0% / −∞ dB).
    public static func yPosition(fromVolumePercent percent: Int, minY: CGFloat, maxY: CGFloat) -> CGFloat {
        let normalized = normalizedPosition(fromVolumePercent: percent)
        return maxY - normalized * (maxY - minY)
    }
}
