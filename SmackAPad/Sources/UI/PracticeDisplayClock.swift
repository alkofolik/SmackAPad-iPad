import AVFoundation
import Observation
import SwiftUI

/// The display owns drawing time; the audio scheduler remains independent.
@MainActor
@Observable
final class PracticeDisplayClock {
    struct Sample {
        let hostSeconds: Double
        let date: Date
    }

    private(set) var sample: Sample?
    #if DEBUG
    private(set) var refreshRate = 0
    private(set) var lateFrameCount = 0
    #endif
    @ObservationIgnored private var running = false
    @ObservationIgnored private var screen: UIScreen?
    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var previousTarget: CFTimeInterval?
    @ObservationIgnored private var previousInterval: CFTimeInterval?

    // CADisplayLink retains its target. A weak relay lets the clock be released.
    @MainActor
    private final class Target: NSObject {
        weak var clock: PracticeDisplayClock?

        init(clock: PracticeDisplayClock) { self.clock = clock }

        @objc func tick(_ link: CADisplayLink) { clock?.tick(link) }
    }

    deinit { link?.invalidate() }

    func setRunning(_ running: Bool) {
        guard self.running != running else { return }
        self.running = running
        if running {
            sample = nil
            #if DEBUG
            lateFrameCount = 0
            #endif
            startLink()
        } else {
            stopLink()
        }
    }

    func attach(to screen: UIScreen?) {
        guard self.screen !== screen else { return }
        stopLink()
        self.screen = screen
        if running { startLink() }
    }

    private func startLink() {
        guard link == nil, let screen else { return }
        guard let link = screen.displayLink(withTarget: Target(clock: self),
                                           selector: #selector(Target.tick(_:))) else { return }
        let maximum = Float(screen.maximumFramesPerSecond)
        link.preferredFrameRateRange = CAFrameRateRange(minimum: min(30, maximum),
                                                       maximum: maximum, preferred: maximum)
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    private func stopLink() {
        link?.invalidate()
        link = nil
        previousTarget = nil
        previousInterval = nil
    }

    private func tick(_ link: CADisplayLink) {
        let mediaNow = CACurrentMediaTime()
        let hostNow = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let untilPresentation = link.targetTimestamp - mediaNow
        // Convert the display's monotonic timestamp to the host-second domain
        // used by PracticeSession, retaining the target even for a late callback.
        sample = Sample(hostSeconds: hostNow + untilPresentation,
                        date: Date().addingTimeInterval(untilPresentation))
        #if DEBUG
        let interval = link.targetTimestamp - link.timestamp
        if interval > 0 {
            let rate = Int((1 / interval).rounded())
            if refreshRate != rate { refreshRate = rate }
        }
        let missedRefresh: Bool
        if let previousTarget, let previousInterval {
            missedRefresh = link.timestamp - previousTarget > previousInterval * 0.5
        } else {
            missedRefresh = false
        }
        if untilPresentation <= 0 || missedRefresh { lateFrameCount += 1 }
        previousTarget = link.targetTimestamp
        previousInterval = interval
        #endif
    }
}

/// Only these small leaf views observe the per-frame sample.
@MainActor
struct PracticeDisplayFrame<Content: View>: View {
    let clock: PracticeDisplayClock
    let session: PracticeSession
    @ViewBuilder let content: (PatternFrame, Date) -> Content

    var body: some View {
        if session.running, let sample = clock.sample {
            content(session.patternFrame(atHostSeconds: sample.hostSeconds), sample.date)
        } else {
            content(PatternFrame(tapePosition: 0, totalSteps: session.practiceLesson.bars * 16,
                                 bpm: session.bpm, countdown: session.countdown), .now)
        }
    }
}

/// Attach to the actual window's screen, including an external display.
struct PracticeDisplayLinkHost: UIViewRepresentable {
    let clock: PracticeDisplayClock

    final class HostView: UIView {
        var clock: PracticeDisplayClock?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            clock?.attach(to: window?.windowScene?.screen)
        }
    }

    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.isUserInteractionEnabled = false
        view.clock = clock
        return view
    }

    func updateUIView(_ view: HostView, context: Context) { }
}

#if DEBUG
@MainActor
struct PracticeTimingReadout: View {
    @AppStorage("smackapad.debug.timingReadout") private var enabled = false
    let clock: PracticeDisplayClock

    var body: some View {
        if enabled {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                let audio = AudioEngine.practice.timingReadout
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "Output: \(audio.route)")
                    Text(verbatim: milliseconds("outputPresentationLatency", audio.presentationLatency))
                    Text(verbatim: milliseconds("session.outputLatency", audio.sessionOutputLatency))
                    Text(verbatim: milliseconds("ioBufferDuration", audio.ioBufferDuration))
                    Text(verbatim: "Display: \(clock.refreshRate) Hz · Late frames: \(clock.lateFrameCount)")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white)
                .padding(8)
                .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                .allowsHitTesting(false)
            }
        }
    }

    private func milliseconds(_ label: String, _ seconds: Double) -> String {
        String(format: "%@: %.2f ms", label, seconds * 1_000)
    }
}
#endif
