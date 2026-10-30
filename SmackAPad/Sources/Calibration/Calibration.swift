import Foundation

public struct CalibrationResult: Equatable, Sendable {
    public let offsetMilliseconds: Double
    public let spreadMilliseconds: Double
    public let usableTaps: Int
    public let discardedTaps: Int
}

public enum CalibrationFailure: Error, Equatable, Sendable {
    case tooFewTaps
    case unevenTaps
    case audioClockChanged
}

/// Pure analysis of tap-minus-output-time differences. Output latency never enters this API.
public enum CalibrationAnalysis {
    public static func evaluate(deltasMilliseconds deltas: [Double]) -> Result<CalibrationResult, CalibrationFailure> {
        let deltas = deltas.filter(\.isFinite)
        guard deltas.count >= 6 else { return .failure(.tooFewTaps) }
        let center = median(deltas)
        let spread = 1.4826 * median(deltas.map { abs($0 - center) })
        let cut = max(60, 3 * spread)
        let kept = deltas.filter { abs($0 - center) <= cut }
        guard kept.count >= 6 else { return .failure(.tooFewTaps) }
        guard spread <= 80 else { return .failure(.unevenTaps) }
        return .success(CalibrationResult(
            offsetMilliseconds: min(200, max(-200, median(kept).rounded())),
            spreadMilliseconds: spread, usableTaps: kept.count, discardedTaps: deltas.count - kept.count
        ))
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}

/// Host-clock seconds from CoreMIDI and the audio output record share one timeline.
/// Keep early taps until all output timestamps are available, including the final late window.
public struct CalibrationMeasurement: Sendable {
    private var taps: [Double] = []

    public init() {}

    public mutating func recordTap(at time: Double) {
        if time.isFinite { taps.append(time) }
    }

    public func matchedClickIndices(outputTimes: [Double]) -> Set<Int> {
        Set(matches(outputTimes: outputTimes).keys)
    }

    public func finish(outputTimes: [Double], clockChanged: Bool) -> Result<CalibrationResult, CalibrationFailure> {
        guard !clockChanged, outputTimes.count == 10,
              outputTimes.allSatisfy(\.isFinite),
              zip(outputTimes, outputTimes.dropFirst()).allSatisfy({ $0 < $1 }) else {
            return .failure(.audioClockChanged)
        }
        return CalibrationAnalysis.evaluate(deltasMilliseconds: Array(matches(outputTimes: outputTimes).values))
    }

    private func matches(outputTimes: [Double]) -> [Int: Double] {
        var deltas: [Int: Double] = [:]
        for tap in taps.sorted() {
            // Choose among ALL clicks first, then reject a duplicate of that click.
            // Never search only the unclaimed clicks: that would move a duplicate forward.
            guard let nearest = outputTimes.indices.min(by: {
                abs(tap - outputTimes[$0]) < abs(tap - outputTimes[$1])
            }), abs(tap - outputTimes[nearest]) <= 0.350, deltas[nearest] == nil else { continue }
            deltas[nearest] = (tap - outputTimes[nearest]) * 1_000
        }
        return deltas
    }
}
