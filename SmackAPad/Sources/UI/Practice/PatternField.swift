import SwiftUI

/// Three-state visibility for pattern notes:
/// - shown: notes fully visible
/// - faded: outlined notes with a light fill and no pad label
/// - hidden: notes hidden, only struck hits drawn behind playhead
public enum NoteVisibility: String, Sendable, Equatable {
    case shown
    case faded
    case hidden

    public static func derive(
        fromMemory: Bool,
        running: Bool,
        listen: Bool,
        isSectionLoop: Bool,
        warmUp: LearningRules.MemoryWarmUp,
        fadeNotes: Bool,
        peeking: Bool = false
    ) -> NoteVisibility {
        guard fromMemory, running, !listen else {
            return .shown
        }
        if peeking && !isSectionLoop { return .shown }
        guard !isSectionLoop, fadeNotes else {
            return .hidden
        }
        if warmUp.notesHidden {
            return .hidden
        }
        return warmUp.consecutivePasses == 0 ? .shown : .faded
    }
}

/// A strike's fractional position belongs to the pass in which it was played.
struct PlayedHit {
    let padIndex: Int
    let step: Double
    let pass: Int
    let mark: HitMark?
    var hidden: Bool = true
    var struckAt: Double? = nil

    func tapeStep(totalSteps: Int) -> Double { Double((pass - 1) * totalSteps) + step }

    func isVisible(in currentPass: Int, before position: Double, steps: Range<Int>,
                   totalSteps: Int? = nil, bpm: Int = 60, reduceMotion: Bool = false) -> Bool {
        guard step >= Double(steps.lowerBound), step < Double(steps.upperBound) else { return false }
        if pass == currentPass { return step < position }
        guard hidden, let totalSteps else { return false }
        return FeedbackWindow.strength(recordedPass: pass, step: step, pass: currentPass,
            position: position, totalSteps: totalSteps, bpm: bpm, reduceMotion: reduceMotion) > 0
    }
}

struct PatternHitFeedback {
    let mark: HitMark
    let struckAt: Double
}

private struct PatternFeedback {
    let hitsByPass: [Int: [LessonHit: PatternHitFeedback]]
    let pass: Int
    let position: Double
    let totalSteps: Int
    let bpm: Int
    let reduceMotion: Bool
    let hostSeconds: Double?

    func strength(offset: Int, step: Double) -> Double {
        FeedbackWindow.strength(recordedPass: pass + offset, step: step, pass: pass,
                                position: position, totalSteps: totalSteps, bpm: bpm,
                                reduceMotion: reduceMotion)
    }

    static func correctPopScale(struckAt: Double?, hostSeconds: Double?, reduceMotion: Bool) -> CGFloat {
        guard !reduceMotion, let struckAt, let hostSeconds else { return 1 }
        let age = hostSeconds - struckAt
        guard age >= 0, age < 0.12 else { return 1 }
        let phase = age / 0.12
        let envelope = phase < 0.28 ? (phase / 0.28) : ((1 - phase) / 0.72)
        return 1 + 0.08 * CGFloat(max(0, min(1, envelope)))
    }

    static func correctPulseProgress(struckAt: Double?, hostSeconds: Double?, reduceMotion: Bool) -> Double? {
        guard !reduceMotion, let struckAt, let hostSeconds else { return nil }
        let age = hostSeconds - struckAt
        let duration = 0.18
        guard age >= 0, age < duration else { return nil }
        return age / duration
    }
}

struct PatternField: View {
    static let ghostOutline = Theme.black

    @ScaledMetric(relativeTo: .headline) private var notationScale: CGFloat = 1
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var session: PracticeSession? = nil
    let lesson: Lesson
    let hits: [LessonHit]
    let position: Double
    let tapePosition: Double
    let running: Bool
    let visibility: NoteVisibility
    var fromMemory: Bool = false
    var afterMe: Bool = false
    var peekNotesOpacity: Double? = nil
    var peekCycles: Range<Int>? = nil
    var hidden: Bool { visibility == .hidden }
    let scrolling: Bool
    let visibleBars: Int
    let verdicts: [Int: BarVerdict]
    let hitsByPass: [Int: [LessonHit: PatternHitFeedback]]
    var hostSeconds: Double? = nil
    var displayDate: Date = .now
    let bpm: Int
    let playedHits: [PlayedHit]
    let pass: Int
    let scoring: Bool
    let missGraceSteps: Double
    let countdown: Int?
    var band: Color = PracticeBandStyle.orange
    var runBars: Int = 4
    var starMomentBeamActive: Bool = false

    private var rows: [Int] {
        let used = Set(hits.map(\.padIndex))
        return PadVoice.rowOrder.filter { used.contains($0) }
    }

    private func visiblePlayedHits(steps: Range<Int>) -> [PlayedHit] {
        guard hidden, running else { return [] }
        return playedHits.filter {
            $0.isVisible(in: pass, before: position, steps: steps, totalSteps: lesson.bars * 16,
                         bpm: bpm, reduceMotion: reduceMotion)
        }
    }

    private var feedback: PatternFeedback {
        PatternFeedback(
            hitsByPass: FeedbackWindow.visibleJudgments(hitsByPass, pass: pass,
                position: position, totalSteps: lesson.bars * 16, bpm: bpm, reduceMotion: reduceMotion),
            pass: pass, position: position, totalSteps: lesson.bars * 16, bpm: bpm,
            reduceMotion: reduceMotion, hostSeconds: hostSeconds
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let count = min(visibleBars, min(lesson.bars, 4))
            let layout = BandGeometry(size: geometry.size, rows: rows.count)
            let labelLayout = PracticeBandStyle.bandLabelLayout(
                rows: rows,
                availableWidth: geometry.size.width,
                rowHeight: layout.rowHeight,
                barCount: scrolling ? 1 : count
            )
            let gutter = labelLayout.gutter
            let orangeFieldWidth = max(1, geometry.size.width - gutter)

            HStack(spacing: 0) {
                if gutter > 0 {
                    BandMarginView(
                        rows: rows,
                        layout: layout,
                        labelLayout: labelLayout,
                        session: session
                    )
                    .frame(width: gutter, height: geometry.size.height)
                    .background {
                        LinearGradient(
                            colors: [
                                Color(red: 0.09, green: 0.085, blue: 0.075),
                                Color(red: 0.06, green: 0.055, blue: 0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Theme.black.opacity(0.85))
                            .frame(width: 2)
                    }
                }

                ZStack(alignment: .topLeading) {
                    Group {
                        if scrolling {
                            ScrollingPattern(session: session, lesson: lesson, hits: hits, rows: rows, position: tapePosition,
                                             running: running, visibility: visibility, fromMemory: fromMemory, afterMe: afterMe,
                                             verdicts: verdicts, hitsByPass: hitsByPass,
                                             hostSeconds: hostSeconds, displayDate: displayDate, pass: pass,
                                             playedHits: playedHits, scoring: scoring,
                                             missGraceSteps: missGraceSteps, band: band, layout: layout,
                                             labelLayout: labelLayout, bpm: bpm,
                                             peekNotesOpacity: peekNotesOpacity, peekCycles: peekCycles)
                        } else {
                            let currentBar = min(lesson.bars - 1, max(0, Int(position) / 16))
                            let first = (currentBar / max(1, count)) * max(1, count)
                            let bars = Array(first..<min(first + count, lesson.bars))
                            let startStep = first * 16
                            let endStep = min(first + count, lesson.bars) * 16
                            let staticPlayed = visiblePlayedHits(steps: startStep..<endStep)
                            StaticPattern(session: session, lesson: lesson, hits: hits, rows: rows, bars: bars, firstBar: first,
                                          position: position, running: running, visibility: visibility,
                                          verdicts: verdicts, feedback: feedback,
                                          playedHits: staticPlayed,
                                          scoring: scoring, missGraceSteps: missGraceSteps,
                                          band: band, layout: layout, labelLayout: labelLayout,
                                          bpm: bpm, reduceMotion: reduceMotion,
                                          displayDate: displayDate,
                                          afterMe: afterMe,
                                          fromMemory: fromMemory, peekNotesOpacity: peekNotesOpacity)
                        }
                    }
                    .frame(width: orangeFieldWidth, height: geometry.size.height)

                    if scoring && countdown == nil {
                        BandTopSpineRuler(
                            bars: runBars,
                            tapePosition: tapePosition,
                            starMomentBeamActive: starMomentBeamActive
                        )
                        .frame(width: orangeFieldWidth, height: 8)
                    }
                }
                .frame(width: orangeFieldWidth, height: geometry.size.height)
                .background {
                    ZStack(alignment: .top) {
                        band
                        LinearGradient(
                            colors: [
                                Theme.white.opacity(0.12),
                                .clear,
                                Theme.black.opacity(0.16)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        Theme.black.opacity(0.18).frame(height: layout.headerTintHeight)
                    }
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: band)
                }
                .overlay {
                    ZStack {
                        VStack(spacing: 0) {
                            LinearGradient(
                                colors: [Theme.black.opacity(0.42), Theme.black.opacity(0.14), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 18)
                            Spacer(minLength: 0)
                            LinearGradient(
                                colors: [.clear, Theme.black.opacity(0.10), Theme.black.opacity(0.32)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 14)
                        }
                        HStack(spacing: 0) {
                            LinearGradient(
                                colors: [Theme.black.opacity(0.30), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 12)
                            Spacer(minLength: 0)
                            LinearGradient(
                                colors: [.clear, Theme.black.opacity(0.24)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 10)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(Rectangle())
            }
            .opacity(countdown == nil ? 1 : 0.22)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay {
                if let countdown {
                    CountInNumeral(number: countdown, size: min(geometry.size.height * 0.65, geometry.size.width * 0.7))
                        .id(countdown)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Theme.black.opacity(0.65), lineWidth: 1)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.11, green: 0.10, blue: 0.09),
                            Color(red: 0.06, green: 0.055, blue: 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .shadow(.inner(color: Theme.black.opacity(0.9), radius: 6, y: 3))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Theme.white.opacity(0.12), Theme.black.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                }
        }
        .shadow(color: Theme.black.opacity(0.32), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Rhythm pattern"))
        .accessibilityValue(
            countdown.map { String($0) } ?? {
                if afterMe {
                    return settings.localized(running ? (pass.isMultiple(of: 2) ? "Your turn" : "Listen…") : "After me")
                }
                if fromMemory && scoring {
                    return settings.localized(visibility == .hidden ? "From memory, notes hidden" : "From memory")
                }
                if visibility == .hidden {
                    return settings.localized("From memory, notes hidden")
                }
                return settings.localized("%lld bars, %@", lesson.bars, rows.map { PadVoice.name($0, settings: settings) }.joined(separator: ", "))
            }()
        )
    }
}

/// One geometry serves lane fills, tiles and fixed labels, including dense lessons.
private struct PatternLanes {
    let size: CGSize
    let rows: [Int]
    let scale: CGFloat
    let rowScale: CGFloat
    let top: CGFloat
    let bottom: CGFloat
    let height: CGFloat
    let rowGap: CGFloat
    let countY: CGFloat
    let beatFontSize: CGFloat
    let tickY: CGFloat
    let tickWidth: CGFloat
    let tickHeight: CGFloat
    let beatLineTop: CGFloat
    let fontSize: CGFloat

    init(geometry: BandGeometry, rows: [Int]) {
        self.size = geometry.size
        self.rows = rows
        self.scale = geometry.scale
        self.rowScale = geometry.rowScale
        self.top = geometry.top
        self.bottom = geometry.bottom
        self.height = geometry.rowHeight
        self.rowGap = geometry.rowGap
        self.countY = geometry.countY
        self.beatFontSize = geometry.beatFontSize
        self.tickY = geometry.tickY
        self.tickWidth = geometry.tickWidth
        self.tickHeight = geometry.tickHeight
        self.beatLineTop = geometry.beatLineTop
        self.fontSize = geometry.noteFontSize
    }

    init(size: CGSize, rows: [Int], scale: CGFloat) {
        self.size = size
        self.rows = rows
        self.scale = scale
        self.rowScale = scale
        self.top = 56 * scale
        self.bottom = size.height - 24 * scale
        self.rowGap = PracticeBandStyle.rowGap * scale
        self.height = max(1, (self.bottom - self.top - self.rowGap * CGFloat(max(0, rows.count - 1))) / CGFloat(max(1, rows.count)))
        self.countY = 26 * scale
        self.beatFontSize = 28 * scale
        self.tickY = self.countY + 12 * scale
        self.tickWidth = max(4, 6 * scale)
        self.tickHeight = max(2.5, 4 * scale)
        self.beatLineTop = self.countY + 14 * scale
        self.fontSize = 32 * scale
    }

    func y(_ row: Int) -> CGFloat { top + CGFloat(row) * (height + rowGap) + height / 2 }
    func tile(x: CGFloat, width: CGFloat, row: Int) -> CGRect {
        let h = min(height - 4 * rowScale, 64 * rowScale)
        return CGRect(x: x - width * 0.42, y: y(row) - h / 2, width: width * 0.84, height: max(1, h))
    }

    func drawRows(context: inout GraphicsContext) {
        let radius = min(12, height * 0.4)
        for row in rows.indices {
            let rect = CGRect(x: -10, y: y(row) - height / 2, width: size.width + 20, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(Theme.white.opacity(0.16)))
        }
    }

}

private func drawBeat(
    step: Int,
    x: CGFloat,
    lanes: PatternLanes,
    beatOnePulse: Double = 0,
    reduceMotion: Bool = false,
    context: inout GraphicsContext
) {
    if step.isMultiple(of: 4) {
        let bar = step.isMultiple(of: 16)
        if bar && beatOnePulse > 0 {
            let haloRadius = lanes.beatFontSize * 0.50
            let haloRect = CGRect(
                x: x - haloRadius,
                y: lanes.countY - haloRadius * 0.9,
                width: haloRadius * 2,
                height: haloRadius * 1.8
            )
            context.fill(
                Path(ellipseIn: haloRect),
                with: .color(Theme.white.opacity((reduceMotion ? 0.34 : 0.48) * beatOnePulse))
            )
        }
        let digitSize = (bar && beatOnePulse > 0 && !reduceMotion)
            ? lanes.beatFontSize * (1 + 0.08 * beatOnePulse)
            : lanes.beatFontSize
        context.draw(Text(String(step % 16 / 4 + 1)).font(Theme.canvasDisplay(digitSize)).monospacedDigit().foregroundColor(Theme.black),
                     at: CGPoint(x: x, y: lanes.countY))
        var path = Path()
        path.move(to: CGPoint(x: x, y: lanes.beatLineTop))
        path.addLine(to: CGPoint(x: x, y: lanes.bottom))
        context.stroke(path, with: .color(Theme.black.opacity(bar ? 0.68 : 0.38)), lineWidth: bar ? 2.0 : 1.25)
        if bar {
            var highlight = Path()
            highlight.move(to: CGPoint(x: x + 1.25, y: lanes.beatLineTop))
            highlight.addLine(to: CGPoint(x: x + 1.25, y: lanes.bottom))
            context.stroke(highlight, with: .color(Theme.white.opacity(0.12)), lineWidth: 0.75)

            let tickRect = CGRect(x: x - lanes.tickWidth / 2, y: lanes.tickY, width: lanes.tickWidth, height: lanes.tickHeight)
            context.fill(Path(roundedRect: tickRect, cornerRadius: 1),
                         with: .color(Theme.black.opacity(0.85)))
            if beatOnePulse > 0 {
                context.fill(Path(roundedRect: tickRect, cornerRadius: 1),
                             with: .color(Theme.white.opacity((reduceMotion ? 0.70 : 0.95) * beatOnePulse)))
            }
        }
    } else {
        let isEighth = step.isMultiple(of: 2)
        var subPath = Path()
        subPath.move(to: CGPoint(x: x, y: lanes.top))
        subPath.addLine(to: CGPoint(x: x, y: lanes.bottom))
        context.stroke(subPath, with: .color(Theme.black.opacity(isEighth ? 0.16 : 0.07)), lineWidth: isEighth ? 0.85 : 0.55)
        let dotRadius: CGFloat = isEighth ? 2.2 : 1.7
        context.fill(Path(ellipseIn: CGRect(x: x - dotRadius, y: lanes.countY - dotRadius, width: dotRadius * 2, height: dotRadius * 2)),
                     with: .color(Theme.black.opacity(isEighth ? 0.58 : 0.36)))
    }
}

private struct StaticPattern: View {
    var session: PracticeSession? = nil
    let lesson: Lesson
    let hits: [LessonHit]
    let rows: [Int]
    let bars: [Int]
    let firstBar: Int
    let position: Double
    let running: Bool
    let visibility: NoteVisibility
    let verdicts: [Int: BarVerdict]
    let feedback: PatternFeedback
    let playedHits: [PlayedHit]
    let scoring: Bool
    let missGraceSteps: Double
    let band: Color
    let layout: BandGeometry
    let labelLayout: BandLabelLayout
    var bpm: Int = 60
    var reduceMotion: Bool = false
    var displayDate: Date = .now
    var afterMe: Bool = false
    var fromMemory: Bool = false
    var peekNotesOpacity: Double? = nil

    var body: some View {
        let barCount = max(1, bars.count)
        let totalSteps = barCount * 16
        let startStep = firstBar * 16
        let endStep = (firstBar + barCount) * 16

        ZStack {
            Canvas { context, size in
                let cellWidth = max(1, (size.width - 24) / CGFloat(totalSteps))
                let lanes = PatternLanes(geometry: layout, rows: rows)
                lanes.drawRows(context: &context)

                // Beat division marks and numbers for each bar
                let pulseSteps = max(0.75, 0.18 * Double(max(1, bpm)) / 15.0)
                for (barIndex, _) in bars.enumerated() {
                    let barOffsetSteps = barIndex * 16
                    let barGlobalStep = (firstBar + barIndex) * 16
                    let delta = position - Double(barGlobalStep)
                    let beatOnePulse = (running && delta >= 0 && delta < pulseSteps)
                        ? pow(1.0 - delta / pulseSteps, 1.5)
                        : 0
                    for step in 0..<16 {
                        let visibleStep = barOffsetSteps + step
                        let x = (CGFloat(visibleStep) + 0.5) * cellWidth
                        drawBeat(
                            step: step,
                            x: x,
                            lanes: lanes,
                            beatOnePulse: step == 0 ? beatOnePulse : 0,
                            reduceMotion: reduceMotion,
                            context: &context
                        )
                    }
                }
            }

            Canvas { context, size in
                let cellWidth = max(1, (size.width - 24) / CGFloat(totalSteps))
                let lanes = PatternLanes(geometry: layout, rows: rows)

                if visibility != .hidden || afterMe || peekNotesOpacity != nil {
                    context.opacity = peekNotesOpacity ?? 1
                    for (row, pad) in rows.enumerated() {
                        for hit in hits where hit.padIndex == pad && hit.step >= startStep && hit.step < endStep {
                            let visibleStep = hit.step - startStep
                            let x = (CGFloat(visibleStep) + 0.5) * cellWidth
                            let rect = lanes.tile(x: x, width: cellWidth, row: row)
                            let currentHit = feedback.hitsByPass[feedback.pass]?[hit]
                            let tail = currentHit == nil && !fromMemory && feedback.position < Double(hit.step)
                                ? feedback.strength(offset: -1, step: Double(hit.step)) : 0
                            let result = tail > 0 ? feedback.hitsByPass[feedback.pass - 1]?[hit] : currentHit
                            let mark = hitMark(result, scoring: scoring,
                                               elapsedSteps: tail > 0 ? Double(feedback.totalSteps) : position - Double(hit.step),
                                               grace: missGraceSteps)
                            let popScale = mark == .correct
                                ? PatternFeedback.correctPopScale(struckAt: result?.struckAt, hostSeconds: feedback.hostSeconds, reduceMotion: reduceMotion)
                                : 1
                            let pulse = mark == .correct
                                ? PatternFeedback.correctPulseProgress(struckAt: result?.struckAt, hostSeconds: feedback.hostSeconds, reduceMotion: reduceMotion)
                                : nil
                            drawHit(hit, in: rect, mark: mark, strength: tail > 0 ? tail : 1,
                                    popScale: popScale,
                                    correctPulse: pulse,
                                    visibility: afterMe || peekNotesOpacity != nil ? .shown : visibility,
                                    fontSize: lanes.fontSize, context: &context)
                        }
                    }
                }
            }
            .opacity(afterMe ? 0 : 1)
            .animation(reduceMotion ? nil : Theme.Motion.fast, value: afterMe)

            Canvas { context, size in
                let cellWidth = max(1, (size.width - 24) / CGFloat(totalSteps))
                let lanes = PatternLanes(geometry: layout, rows: rows)

                if visibility == .hidden && running {
                    for (row, pad) in rows.enumerated() {
                        var playedContext = context
                        let visiblePosition = position - Double(startStep)
                        let markerX = CGFloat(visiblePosition) * cellWidth
                        let behindMarker = min(size.width, max(0, markerX))
                        playedContext.clip(to: Path(CGRect(x: 0, y: 0, width: behindMarker, height: size.height)))

                        let barPlayedHits = playedHits.filter {
                            $0.padIndex == pad && $0.step >= Double(startStep) && $0.step < Double(endStep)
                        }
                        for hit in barPlayedHits {
                            let visibleStep = hit.step - Double(startStep)
                            let x = (CGFloat(visibleStep) + 0.5) * cellWidth
                            let rect = lanes.tile(x: x, width: cellWidth, row: row)
                            var hitContext = hit.pass == feedback.pass ? playedContext : context
                            if hit.pass != feedback.pass {
                                hitContext.opacity = feedback.strength(offset: hit.pass - feedback.pass, step: hit.step)
                            }
                            let popScale = hit.mark == .correct
                                ? PatternFeedback.correctPopScale(struckAt: hit.struckAt, hostSeconds: feedback.hostSeconds, reduceMotion: reduceMotion)
                                : 1
                            let pulse = hit.mark == .correct
                                ? PatternFeedback.correctPulseProgress(struckAt: hit.struckAt, hostSeconds: feedback.hostSeconds, reduceMotion: reduceMotion)
                                : nil
                            drawPlayedHit(hit, in: rect, popScale: popScale, correctPulse: pulse, fontSize: lanes.fontSize, context: &hitContext, hits: hits)
                        }
                    }
                }

                // Smooth playhead moving across bar boundaries at constant speed
                let visiblePosition = position - Double(startStep)
                if running && visiblePosition >= 0 && visiblePosition <= Double(totalSteps) {
                    let markerX = CGFloat(visiblePosition) * cellWidth
                    drawPlayheadRowFlashes(session: session, rows: rows, lanes: lanes, markerX: markerX,
                                           cellWidth: cellWidth, now: displayDate, canvasWidth: size.width, context: &context)
                    drawMarker(x: markerX, top: lanes.top - 4 * lanes.scale, bottom: lanes.bottom + 4, context: &context)
                }
            }
        }
    }
}

private struct ScrollingPattern: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var session: PracticeSession? = nil
    let lesson: Lesson
    let hits: [LessonHit]
    let rows: [Int]
    let position: Double
    let running: Bool
    let visibility: NoteVisibility
    var fromMemory: Bool = false
    var afterMe: Bool = false
    let verdicts: [Int: BarVerdict]
    let hitsByPass: [Int: [LessonHit: PatternHitFeedback]]
    var hostSeconds: Double? = nil
    var displayDate: Date = .now
    let pass: Int
    let playedHits: [PlayedHit]
    let scoring: Bool
    let missGraceSteps: Double
    let band: Color
    let layout: BandGeometry
    let labelLayout: BandLabelLayout
    var bpm: Int = 60
    var peekNotesOpacity: Double? = nil
    var peekCycles: Range<Int>? = nil

    var body: some View {
        let total = max(16, lesson.bars * 16)

        ZStack {
            Canvas { context, size in
                let cellWidth = max(PracticeBandStyle.cellWidth(rows: rows, scale: layout.rowScale), size.width / 24)
                let markerX = size.width / 3
                let lanes = PatternLanes(geometry: layout, rows: rows)
                let firstStep = Int(floor(position - Double(markerX / cellWidth))) - 1
                let lastStep = Int(ceil(position + Double((size.width - markerX) / cellWidth))) + 1
                let pulseSteps = max(0.75, 0.18 * Double(max(1, bpm)) / 15.0)
                lanes.drawRows(context: &context)
                for globalStep in firstStep...lastStep {
                    guard globalStep >= 0 else { continue }
                    let step = (globalStep % total + total) % total
                    let x = markerX + CGFloat(Double(globalStep) - position) * cellWidth
                    let delta = position - Double(globalStep)
                    let beatOnePulse = (running && step.isMultiple(of: 16) && delta >= 0 && delta < pulseSteps)
                        ? pow(1.0 - delta / pulseSteps, 1.5)
                        : 0
                    drawBeat(
                        step: step,
                        x: x,
                        lanes: lanes,
                        beatOnePulse: beatOnePulse,
                        reduceMotion: reduceMotion,
                        context: &context
                    )
                }
            }

            Canvas { context, size in
                let cellWidth = max(PracticeBandStyle.cellWidth(rows: rows, scale: layout.rowScale), size.width / 24)
                let markerX = size.width / 3
                let lanes = PatternLanes(geometry: layout, rows: rows)
                let firstStep = Int(floor(position - Double(markerX / cellWidth))) - 1
                let lastStep = Int(ceil(position + Double((size.width - markerX) / cellWidth))) + 1

                context.opacity = peekNotesOpacity ?? 1
                for globalStep in firstStep...lastStep {
                    guard globalStep >= 0 else { continue }
                    let step = (globalStep % total + total) % total
                    let recordedPass = globalStep / total + 1
                    if let peekCycles, !peekCycles.contains(recordedPass) { continue }
                    let stepVisibility: NoteVisibility = afterMe || peekNotesOpacity != nil ? .shown : visibility
                    let x = markerX + CGFloat(Double(globalStep) - position) * cellWidth
                    if stepVisibility != .hidden || afterMe {
                        for hit in hits where hit.step == step {
                            guard let row = rows.firstIndex(of: hit.padIndex) else { continue }
                            let rect = lanes.tile(x: x, width: cellWidth, row: row)
                            let edgeOpacity = min(1, max(0, rect.maxX / rect.width))
                            guard edgeOpacity > 0 else { continue }
                            let result = hitsByPass[recordedPass]?[hit]
                            let mark = hitMark(result, scoring: scoring,
                                               elapsedSteps: position - Double(globalStep), grace: missGraceSteps)
                            let popScale = mark == .correct
                                ? PatternFeedback.correctPopScale(struckAt: result?.struckAt, hostSeconds: hostSeconds, reduceMotion: reduceMotion)
                                : 1
                            let pulse = mark == .correct
                                ? PatternFeedback.correctPulseProgress(struckAt: result?.struckAt, hostSeconds: hostSeconds, reduceMotion: reduceMotion)
                                : nil
                            var noteContext = context
                            noteContext.opacity *= edgeOpacity
                            drawHit(hit, in: rect, mark: mark, strength: 1, popScale: popScale,
                                    correctPulse: pulse,
                                    visibility: afterMe ? .shown : stepVisibility,
                                    fontSize: lanes.fontSize, context: &noteContext)
                        }
                    }
                }
            }
            .opacity(afterMe ? 0 : 1)
            .animation(reduceMotion ? nil : Theme.Motion.fast, value: afterMe)

            Canvas { context, size in
                let cellWidth = max(PracticeBandStyle.cellWidth(rows: rows, scale: layout.rowScale), size.width / 24)
                let markerX = size.width / 3
                let lanes = PatternLanes(geometry: layout, rows: rows)
                let rowTop = lanes.top
                let rowBottom = lanes.bottom

                if visibility == .hidden && running {
                    var playedContext = context
                    playedContext.clip(to: Path(CGRect(x: 0, y: rowTop, width: markerX, height: max(1, rowBottom - rowTop))))
                    for hit in playedHits {
                        guard hit.pass == pass || hit.hidden else { continue }
                        guard let row = rows.firstIndex(of: hit.padIndex) else { continue }
                        let step = hit.tapeStep(totalSteps: total)
                        guard step >= 0, step < position else { continue }
                        let x = markerX + CGFloat(step - position) * cellWidth
                        guard x + cellWidth * 0.42 >= 0 else { continue }
                        let rect = lanes.tile(x: x, width: cellWidth, row: row)
                        var hitContext = playedContext
                        hitContext.opacity = min(1, max(0, rect.maxX / rect.width))
                        let popScale = hit.mark == .correct
                            ? PatternFeedback.correctPopScale(struckAt: hit.struckAt, hostSeconds: hostSeconds, reduceMotion: reduceMotion)
                            : 1
                        let pulse = hit.mark == .correct
                            ? PatternFeedback.correctPulseProgress(struckAt: hit.struckAt, hostSeconds: hostSeconds, reduceMotion: reduceMotion)
                            : nil
                        drawPlayedHit(hit, in: rect, popScale: popScale, correctPulse: pulse, fontSize: lanes.fontSize, context: &hitContext, hits: hits)
                    }
                }
                if running {
                    drawPlayheadRowFlashes(session: session, rows: rows, lanes: lanes, markerX: markerX,
                                           cellWidth: cellWidth, now: displayDate, canvasWidth: size.width, context: &context)
                }
                drawMarker(x: markerX, top: lanes.top - 4 * lanes.scale, bottom: rowBottom + 4, context: &context)
            }
        }
    }
}

@MainActor
private func drawPlayheadRowFlashes(
    session: PracticeSession?,
    rows: [Int],
    lanes: PatternLanes,
    markerX: CGFloat,
    cellWidth: CGFloat,
    now: Date,
    canvasWidth: CGFloat,
    context: inout GraphicsContext
) {
    guard let flashes = session?.padFlashes, !flashes.isEmpty else { return }
    let flashWidth = max(cellWidth * 1.6, 72 * lanes.scale)
    let radius = min(12, lanes.height * 0.4)
    for (row, pad) in rows.enumerated() {
        guard let flash = flashes[pad] else { continue }
        let age = max(0, now.timeIntervalSince(flash.date))
        let strike = 1 - age / BandRowDotSchedule.fadeDuration
        guard strike > 0 else { continue }
        let minX = max(0, markerX - flashWidth / 2)
        let maxX = min(canvasWidth, markerX + flashWidth / 2)
        guard maxX > minX else { continue }
        let rect = CGRect(x: minX, y: lanes.y(row) - lanes.height / 2, width: maxX - minX, height: lanes.height)
        context.fill(Path(roundedRect: rect, cornerRadius: radius),
                     with: .color(Theme.white.opacity(0.24 * strike)))
    }
}

private func drawPlayedHit(_ hit: PlayedHit, in rect: CGRect, popScale: CGFloat = 1,
                           correctPulse: Double? = nil, fontSize: CGFloat,
                           context: inout GraphicsContext, hits: [LessonHit]? = nil) {
    let hand = hits?.first(where: { $0.padIndex == hit.padIndex && abs(Double($0.step) - hit.step) < 0.75 })?.hand ?? "R"
    let note = LessonHit(step: Int(hit.step), padIndex: hit.padIndex, hand: hand, velocity: 0)
    drawHit(note, in: rect, mark: hit.mark, strength: 1, popScale: popScale, correctPulse: correctPulse, visibility: .shown, fontSize: fontSize, context: &context)
}

private func hitMark(_ feedback: PatternHitFeedback?, scoring: Bool,
                     elapsedSteps: Double, grace: Double) -> HitMark? {
    guard scoring else { return nil }
    return feedback?.mark ?? (elapsedSteps > grace ? .wrong : nil)
}

func drawHit(_ hit: LessonHit, in rect: CGRect, mark: HitMark?, strength: Double = 1,
             popScale: CGFloat = 1,
             correctPulse: Double? = nil,
             visibility: NoteVisibility = .shown,
             fontSize: CGFloat, context: inout GraphicsContext) {
    guard visibility != .hidden else { return }
    if mark != nil, strength < 1 {
        var base = context
        base.opacity *= 1 - strength
        drawHit(hit, in: rect, mark: nil, visibility: visibility, fontSize: fontSize, context: &base)
        if strength > 0 {
            var marked = context
            marked.opacity *= strength
            drawHit(hit, in: rect, mark: mark, popScale: popScale, correctPulse: correctPulse, visibility: visibility,
                    fontSize: fontSize, context: &marked)
        }
        return
    }

    let drawRect = rect.insetBy(dx: rect.width * (1 - popScale) / 2,
                               dy: rect.height * (1 - popScale) / 2)
    let cornerRadius = min(7, min(drawRect.width, drawRect.height) * 0.25)
    let tilePath = Path(roundedRect: drawRect, cornerRadius: cornerRadius)
    if mark == .wrong {
        context.fill(tilePath, with: .color(Theme.black.opacity(0.14)))
        context.stroke(Path(roundedRect: drawRect.insetBy(dx: 0.75, dy: 0.75),
                            cornerRadius: max(0, cornerRadius - 0.75)),
                       with: .color(Theme.black.opacity(0.55)), lineWidth: 1.5)
        let slashInset = min(4, min(drawRect.width, drawRect.height) * 0.2)
        var slash = Path()
        slash.move(to: CGPoint(x: drawRect.minX + slashInset, y: drawRect.maxY - slashInset))
        slash.addLine(to: CGPoint(x: drawRect.maxX - slashInset, y: drawRect.minY + slashInset))
        context.stroke(slash, with: .color(Theme.black), style: StrokeStyle(lineWidth: 1.75, lineCap: .round))
        return
    }

    let isLeft = hit.hand.uppercased() == "L"
    let baseColor = isLeft ? Theme.black : Theme.white
    if visibility == .faded && mark == nil {
        let innerRadius = max(1, cornerRadius - 1)
        let interior = Path(roundedRect: drawRect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: innerRadius)
        context.fill(interior, with: .color(baseColor.opacity(isLeft ? 0.35 : 0.20)))
        if isLeft {
            context.stroke(interior, with: .color(Theme.white.opacity(0.35)), lineWidth: 1)
        }
        context.stroke(Path(roundedRect: drawRect.insetBy(dx: 1, dy: 1), cornerRadius: innerRadius),
                       with: .color(PatternField.ghostOutline.opacity(0.4)), lineWidth: 1.5)
        return
    }

    let shadowPath = tilePath.offsetBy(dx: 0, dy: 1.5)
    context.fill(shadowPath, with: .color(Theme.black.opacity(0.28)))

    context.fill(tilePath, with: .color(baseColor))

    var bevelContext = context
    bevelContext.clip(to: tilePath)
    var topEdge = Path()
    topEdge.move(to: CGPoint(x: drawRect.minX + 1.5, y: drawRect.minY + 0.75))
    topEdge.addLine(to: CGPoint(x: drawRect.maxX - 1.5, y: drawRect.minY + 0.75))
    bevelContext.stroke(
        topEdge,
        with: .color(Theme.white.opacity(isLeft ? 0.28 : 0.95)),
        style: StrokeStyle(lineWidth: 1.25, lineCap: .round)
    )
    if !isLeft {
        var bottomEdge = Path()
        bottomEdge.move(to: CGPoint(x: drawRect.minX + 1.5, y: drawRect.maxY - 0.75))
        bottomEdge.addLine(to: CGPoint(x: drawRect.maxX - 1.5, y: drawRect.maxY - 0.75))
        bevelContext.stroke(
            bottomEdge,
            with: .color(Theme.black.opacity(0.14)),
            style: StrokeStyle(lineWidth: 1, lineCap: .round)
        )
        context.stroke(tilePath, with: .color(Theme.black.opacity(0.16)), lineWidth: 0.75)
    } else {
        context.stroke(tilePath, with: .color(Theme.white.opacity(0.85)), lineWidth: 1)
    }

    var labelRect = drawRect
    switch mark {
    case .correct:
        if let pulse = correctPulse {
            let eased = 1 - pow(1 - pulse, 2)
            let alpha = (1 - pulse) * (1 - 0.2 * pulse)
            let expand = 1.5 + 9.0 * eased
            let pulseRect = drawRect.insetBy(dx: -expand, dy: -expand)
            let pulsePath = Path(roundedRect: pulseRect, cornerRadius: cornerRadius + expand * 0.45)
            context.stroke(
                pulsePath,
                with: .color(Theme.white.opacity(0.92 * alpha)),
                lineWidth: max(1.0, 2.2 - 0.8 * pulse)
            )
        }
        let inset = min(2.5, min(drawRect.width, drawRect.height) * 0.22)
        context.stroke(Path(roundedRect: drawRect.insetBy(dx: inset, dy: inset),
                            cornerRadius: max(0, cornerRadius - inset)),
                       with: .color(Theme.orange), lineWidth: 2)
    case .early, .late:
        let direction: CGFloat = mark == .early ? 1 : -1
        let edge = mark == .early ? drawRect.minX : drawRect.maxX
        let ink = isLeft ? Theme.orange : Theme.black
        var clipped = context
        clipped.clip(to: tilePath)

        let reservedWidth: CGFloat
        if drawRect.width >= 24 {
            let tip = edge + direction * 3
            let outer = tip + direction * 5
            let halfHeight = min(7, drawRect.height * 0.23)
            var chevron = Path()
            chevron.move(to: CGPoint(x: outer, y: drawRect.midY - halfHeight))
            chevron.addLine(to: CGPoint(x: tip, y: drawRect.midY))
            chevron.addLine(to: CGPoint(x: outer, y: drawRect.midY + halfHeight))
            clipped.stroke(chevron, with: .color(ink),
                           style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
            reservedWidth = 10
        } else {
            let barWidth = min(2.5, drawRect.width / 3)
            let barX = mark == .early ? drawRect.minX : drawRect.maxX - barWidth
            clipped.fill(Path(CGRect(x: barX, y: drawRect.minY, width: barWidth, height: drawRect.height)),
                         with: .color(ink))
            reservedWidth = barWidth
        }
        labelRect.size.width -= reservedWidth
        if mark == .early { labelRect.origin.x += reservedWidth }
    default:
        break
    }

    if visibility == .shown && PracticeBandStyle.showPadLabels {
        let hitFontSize = min(fontSize, max(7, min(labelRect.width * 0.65, drawRect.height * 0.68)))
        var labelContext = context
        if mark == .early || mark == .late { labelContext.clip(to: Path(labelRect)) }
        labelContext.draw(Text(PadVoice.abbreviation(hit.padIndex)).font(Theme.canvasDisplay(hitFontSize))
            .foregroundColor(isLeft ? Theme.white : Theme.black),
            at: CGPoint(x: labelRect.midX, y: labelRect.midY))
    }
}

private func drawMarker(x: CGFloat, top: CGFloat, bottom: CGFloat, context: inout GraphicsContext) {
    var path = Path()
    path.move(to: CGPoint(x: x, y: top))
    path.addLine(to: CGPoint(x: x, y: bottom))
    context.stroke(path, with: .color(Theme.orange.opacity(0.42)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
    context.stroke(path, with: .color(Color(red: 1, green: 0.82, blue: 0.55).opacity(0.72)), style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
    context.stroke(path, with: .color(Theme.black.opacity(0.35)), style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
    context.stroke(path, with: .color(Theme.white), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    var cap = Path()
    cap.move(to: CGPoint(x: x - 6.0, y: top - 4.0))
    cap.addLines([CGPoint(x: x + 6.0, y: top - 4.0), CGPoint(x: x, y: top + 4.0)])
    cap.closeSubpath()
    context.stroke(cap, with: .color(Theme.orange.opacity(0.55)), style: StrokeStyle(lineWidth: 4.0, lineJoin: .round))
    context.fill(cap, with: .color(Theme.white))
    context.stroke(cap, with: .color(Theme.black.opacity(0.7)), style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
}

/// A thin ruler (8 pt high) along the top edge of the orange band, spanning the band width.
/// Divided into one sector per bar of the current run, filling along with the playhead.
struct BandTopSpineRuler: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let bars: Int
    let tapePosition: Double
    let starMomentBeamActive: Bool

    @State private var beamOffset: CGFloat = -0.25

    private var totalRunSteps: Double {
        Double(max(1, bars) * 16)
    }

    private var runStep: Double {
        totalRunSteps > 0 ? tapePosition.truncatingRemainder(dividingBy: totalRunSteps) : 0
    }

    private var currentBarIndex: Int {
        min(max(0, bars - 1), Int(runStep / 16))
    }

    private var barStep: Double {
        runStep - Double(currentBarIndex * 16)
    }

    private var barFraction: Double {
        min(1, max(0, barStep / 16))
    }

    private var isWarningLit: Bool {
        bars >= 2 && currentBarIndex == bars - 2 && barFraction >= 0.75
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let sectorCount = max(1, bars)
            let gap: CGFloat = 2
            let totalGaps = CGFloat(sectorCount - 1) * gap
            let sectorWidth = max(1, (width - totalGaps) / CGFloat(sectorCount))

            ZStack(alignment: .topLeading) {
                // Background track & dividers
                HStack(spacing: gap) {
                    ForEach(0..<sectorCount, id: \.self) { index in
                        ZStack(alignment: .leading) {
                            if index == sectorCount - 1 {
                                // Last sector distinct background
                                LastSectorTrackBackground()
                            } else {
                                Theme.white.opacity(0.18)
                            }

                            // Progress fill for this sector
                            let fillFraction: CGFloat = {
                                if index < currentBarIndex { return 1.0 }
                                if index == currentBarIndex { return CGFloat(barFraction) }
                                return 0.0
                            }()
                            if fillFraction > 0 {
                                Theme.white.opacity(0.95)
                                    .frame(width: sectorWidth * fillFraction)
                            }
                        }
                        .frame(width: sectorWidth, height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5))
                    }
                }

                // Warning tooth on leading edge of the last sector
                if sectorCount >= 2 {
                    let toothX = CGFloat(sectorCount - 1) * (sectorWidth + gap)
                    WarningToothShape()
                        .fill(isWarningLit ? Theme.white : Theme.black.opacity(0.5))
                        .overlay {
                            if !isWarningLit {
                                WarningToothShape()
                                    .stroke(Theme.white.opacity(0.7), lineWidth: 0.75)
                            }
                        }
                        .frame(width: 8, height: 8)
                        .offset(x: toothX)
                }

                // Star moment laser beam sweep (0.45 s)
                if starMomentBeamActive && !reduceMotion {
                    LinearGradient(
                        colors: [.clear, Theme.white, Theme.white, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 0.20, height: 8)
                    .offset(x: width * beamOffset)
                }
            }
            .frame(width: width, height: 8)
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Run progress"))
        .accessibilityValue(settings.localized("bar %lld of %lld", min(bars, currentBarIndex + 1), bars))
        .task(id: starMomentBeamActive) {
            guard starMomentBeamActive, !reduceMotion else {
                beamOffset = -0.25
                return
            }
            beamOffset = -0.25
            withAnimation(.easeOut(duration: 0.45)) {
                beamOffset = 1.05
            }
        }
    }
}

/// Subtle hatched pattern for the final bar's ruler sector.
private struct LastSectorTrackBackground: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.white.opacity(0.12)))
            var path = Path()
            let step: CGFloat = 6
            for x in stride(from: -size.height, to: size.width + size.height, by: step) {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
            }
            context.stroke(path, with: .color(Theme.black.opacity(0.20)), lineWidth: 1.5)
        }
    }
}

/// A notched/bevelled tooth pointing into the final bar.
struct WarningToothShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A single, read-only demo measure using the same lanes and note marks as practice.
struct HelpPatternBand: View {
    static let hiHat = 11
    static let snare = 13
    static let kick = 12
    private static let rows = [hiHat, snare, kick]
    private static let hits = [
        LessonHit(step: 0, padIndex: hiHat, hand: "R", velocity: 100),
        LessonHit(step: 4, padIndex: hiHat, hand: "R", velocity: 100),
        LessonHit(step: 8, padIndex: hiHat, hand: "R", velocity: 100),
        LessonHit(step: 12, padIndex: hiHat, hand: "R", velocity: 100),
        LessonHit(step: 4, padIndex: snare, hand: "L", velocity: 100),
        LessonHit(step: 12, padIndex: snare, hand: "L", velocity: 100),
        LessonHit(step: 0, padIndex: kick, hand: "R", velocity: 100),
        LessonHit(step: 10, padIndex: kick, hand: "L", velocity: 100)
    ]

    var visibility: NoteVisibility = .shown
    var position: Double? = nil
    var band = PracticeBandStyle.orange
    var matchedHit = false
    var passed = false
    var height: CGFloat = 80
    var bars = 1
    var showHitMarks = false

    var body: some View {
        Canvas { context, size in
            let scale = min(size.height / 228, size.width / 400)
            let lanes = PatternLanes(size: size, rows: Self.rows, scale: scale)
            let labelLayout = PracticeBandStyle.bandLabelLayout(
                rows: Self.rows,
                availableWidth: size.width,
                rowHeight: lanes.height,
                barCount: bars,
                maxFontSize: 22 * scale,
                minFontSize: 11 * scale,
                trailingPadding: 8 * scale
            )
            let gutter = labelLayout.gutter
            let stepCount = 16 * bars
            let stepWidth = (size.width - gutter) / CGFloat(stepCount)
            let x: (Double) -> CGFloat = { gutter + ($0 + 0.5) * stepWidth }
            lanes.drawRows(context: &context)
            for step in 0..<stepCount {
                drawBeat(step: step, x: x(Double(step)), lanes: lanes, context: &context)
            }
            if let position {
                drawMarker(x: x(position), top: lanes.top - 4 * scale, bottom: lanes.bottom, context: &context)
            }
            if visibility != .hidden {
                for bar in 0..<bars {
                    for hit in Self.hits {
                        guard let row = Self.rows.firstIndex(of: hit.padIndex) else { continue }
                        let step = hit.step + bar * 16
                        let width = min(stepWidth * 1.5, 64 * scale)
                        let rect = lanes.tile(x: x(Double(step)), width: width, row: row)
                        let matchesPlayhead = position.map { (0..<3).contains($0 - Double(step)) } ?? false
                        let mark: HitMark?
                        if showHitMarks && hit.padIndex == Self.hiHat {
                            mark = switch hit.step {
                            case 0: .correct
                            case 4: .early
                            case 8: .late
                            case 12: .wrong
                            default: nil
                            }
                        } else {
                            mark = matchedHit && matchesPlayhead && hit.padIndex == Self.snare ? .correct : nil
                        }
                        drawHit(hit, in: rect, mark: mark, visibility: visibility, fontSize: lanes.fontSize, context: &context)
                    }
                }
            }
            for (row, pad) in Self.rows.enumerated() {
                let iconSize = labelLayout.iconSize
                let iconRect = CGRect(
                    x: (gutter - iconSize) / 2,
                    y: lanes.y(row) - iconSize / 2,
                    width: iconSize,
                    height: iconSize
                )
                DrumGlyph.draw(kind: DrumKind.forPad(pad), in: iconRect, context: &context, color: Theme.ink)
            }
        }
        .padding(.horizontal, Theme.Space.small)
        .frame(height: height)
        .background(band)
        .overlay(alignment: .bottomTrailing) {
            if passed {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Theme.black)
                    .padding(Theme.Space.small)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Margin & Hit Indicator (Ticket 218, 229 & 231)

private struct BandRowDotSchedule: TimelineSchedule {
    let flashDate: Date?
    static let fadeDuration: TimeInterval = 0.20
    private static let frameInterval: TimeInterval = 1.0 / 60.0

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] {
        guard let flashDate else { return [startDate] }
        let finish = flashDate.addingTimeInterval(Self.fadeDuration)
        guard finish > startDate else { return [startDate] }
        var dates: [Date] = []
        var current = startDate
        while current < finish {
            dates.append(current)
            current = current.addingTimeInterval(Self.frameInterval)
        }
        dates.append(finish)
        return dates
    }
}

private struct BandVelocityMeter: View {
    let level: Double
    let height: CGFloat

    private let segmentCount = 4

    var body: some View {
        VStack(spacing: 2) {
            ForEach((0..<segmentCount).reversed(), id: \.self) { index in
                let threshold = Double(index) / Double(segmentCount)
                let fill = max(0, min(1, (level - threshold) * Double(segmentCount)))
                let activeColor = index == segmentCount - 1
                    ? Color(red: 1, green: 0.85, blue: 0.42)
                    : Theme.orange
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.white.opacity(0.14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(activeColor)
                            .opacity(fill)
                            .shadow(color: activeColor.opacity(fill * 0.7), radius: 2.5)
                    }
            }
        }
        .padding(1.5)
        .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 3))
        .frame(width: 11, height: max(18, height))
        .accessibilityHidden(true)
    }
}

/// Observes pad input in the gutter without invalidating the pattern or the practice screen.
private struct BandMarginRowIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let session: PracticeSession?
    let padIndex: Int
    let iconSize: CGFloat
    let rowHeight: CGFloat
    let name: String
    let onTap: () -> Void

    var body: some View {
        let flash = session?.padFlashes[padIndex]
        TimelineView(BandRowDotSchedule(flashDate: flash?.date)) { timeline in
            let age = flash.map { max(0, timeline.date.timeIntervalSince($0.date)) } ?? .infinity
            let phase = age / BandRowDotSchedule.fadeDuration
            let isStriking = phase < 1
            let velocityLevel: Double = {
                guard isStriking, let flash, flash.velocity > 0 else { return 0 }
                let peak = max(0.22, Double(flash.velocity) / 127.0)
                return reduceMotion ? peak : peak * (1 - phase)
            }()
            let press = isStriking ? (phase < 0.22 ? phase / 0.22 : (1 - phase) / 0.78) : 0
            let glyphScale: CGFloat = (!reduceMotion && isStriking) ? (1.0 - 0.12 * CGFloat(press)) : 1.0
            let badgeSize = max(iconSize + 6, min(rowHeight - 6, iconSize + 10))
            let meterHeight = min(rowHeight - 6, max(18, iconSize * 1.15))

            HStack(spacing: 6) {
                Button(action: onTap) {
                    DrumGlyph(kind: DrumKind.forPad(padIndex))
                        .frame(width: iconSize, height: iconSize)
                        .scaleEffect(glyphScale)
                        .foregroundStyle(isStriking ? Theme.white : Theme.white.opacity(0.92))
                        .frame(width: badgeSize, height: badgeSize)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isStriking ? Theme.orange.opacity(0.24) : Theme.white.opacity(0.06))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(isStriking ? Theme.orange.opacity(0.85) : Theme.white.opacity(0.12), lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(name)

                BandVelocityMeter(level: velocityLevel, height: meterHeight)
            }
        }
    }
}

/// Left margin holding drum icons and hit indicator dots right-aligned against the orange field (Ticket 229).
/// Tapping an icon reveals the full drum name in a small bubble for ~2 s.
private struct BandMarginView: View {
    let rows: [Int]
    let layout: BandGeometry
    let labelLayout: BandLabelLayout
    let session: PracticeSession?
    @State private var activeBubblePad: Int? = nil
    @State private var bubbleTask: Task<Void, Never>? = nil

    var body: some View {
        GeometryReader { geometry in
            let lanes = PatternLanes(geometry: layout, rows: rows)
            let iconSize = labelLayout.iconSize

            ZStack(alignment: .topLeading) {
                ForEach(rows.indices, id: \.self) { row in
                    let pad = rows[row]
                    let rowY = lanes.y(row)
                    let name = labelLayout.labels[pad] ?? PadVoice.displayName(pad)

                    HStack(spacing: 0) {
                        Spacer(minLength: 0)

                        BandMarginRowIndicator(
                            session: session,
                            padIndex: pad,
                            iconSize: iconSize,
                            rowHeight: layout.rowHeight,
                            name: name
                        ) {
                            withAnimation(Theme.Motion.fast) {
                                activeBubblePad = pad
                            }
                            bubbleTask?.cancel()
                            bubbleTask = Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                await MainActor.run {
                                    withAnimation(Theme.Motion.fast) {
                                        if activeBubblePad == pad {
                                            activeBubblePad = nil
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.trailing, 8)
                    .padding(.leading, 8)
                    .frame(width: geometry.size.width, height: layout.rowHeight)
                    .position(x: geometry.size.width / 2, y: rowY)
                }

                // Bubble callout for active drum name
                if let activeBubblePad,
                   let activeRowIndex = rows.firstIndex(of: activeBubblePad) {
                    let rowY = lanes.y(activeRowIndex)
                    let name = labelLayout.labels[activeBubblePad] ?? PadVoice.displayName(activeBubblePad)

                    Text(name)
                        .font(Theme.canvasPadTitle(size: 13))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Theme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Theme.ink.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Theme.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                        .position(x: geometry.size.width + 45, y: rowY)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .zIndex(100)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
