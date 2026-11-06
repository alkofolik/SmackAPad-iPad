import SwiftUI

/// Three-state visibility for pattern notes:
/// - shown: notes fully visible
/// - faded: notes drawn at low contrast (outline only, no pad label)
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
        pass: Int,
        fadeNotes: Bool
    ) -> NoteVisibility {
        guard fromMemory, running, !listen else {
            return .shown
        }
        guard !isSectionLoop, fadeNotes else {
            return .hidden
        }
        switch pass {
        case 1:
            return .shown
        case 2:
            return .faded
        default:
            return .hidden
        }
    }
}

/// A strike's fractional position belongs to the pass in which it was played.
struct PlayedHit {
    let padIndex: Int
    let step: Double
    let pass: Int
    let mark: HitMark?

    func tapeStep(totalSteps: Int) -> Double { Double((pass - 1) * totalSteps) + step }

    func isVisible(in currentPass: Int, before position: Double, steps: Range<Int>,
                   totalSteps: Int? = nil, bpm: Int = 60, reduceMotion: Bool = false) -> Bool {
        guard step >= Double(steps.lowerBound), step < Double(steps.upperBound) else { return false }
        if pass == currentPass { return step < position }
        guard let totalSteps else { return false }
        return FeedbackWindow.strength(recordedPass: pass, step: step, pass: currentPass,
            position: position, totalSteps: totalSteps, bpm: bpm, reduceMotion: reduceMotion) > 0
    }
}

private struct PatternFeedback {
    let judgments: [Int: [LessonHit: HitJudgment]]
    let pass: Int
    let position: Double
    let totalSteps: Int
    let bpm: Int
    let reduceMotion: Bool

    func strength(offset: Int, step: Double) -> Double {
        FeedbackWindow.strength(recordedPass: pass + offset, step: step, pass: pass,
                                position: position, totalSteps: totalSteps, bpm: bpm,
                                reduceMotion: reduceMotion)
    }
}

struct PatternField: View {
    @ScaledMetric(relativeTo: .headline) private var notationScale: CGFloat = 1
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let lesson: Lesson
    let hits: [LessonHit]
    let position: Double
    let tapePosition: Double
    let running: Bool
    let visibility: NoteVisibility
    var fromMemory: Bool = false
    var afterMe: Bool = false
    var hidden: Bool { visibility == .hidden }
    let scrolling: Bool
    let visibleBars: Int
    let verdicts: [Int: BarVerdict]
    let judgments: [Int: [LessonHit: HitJudgment]]
    let bpm: Int
    let playedHits: [PlayedHit]
    let pass: Int
    let scoring: Bool
    let missGraceSteps: Double
    let countdown: Int?
    var band: Color = PracticeBandStyle.orange
    var edgeTendency: Double = 0
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
        PatternFeedback(judgments: FeedbackWindow.visibleJudgments(judgments, pass: pass,
            position: position, totalSteps: lesson.bars * 16, bpm: bpm, reduceMotion: reduceMotion),
            pass: pass, position: position, totalSteps: lesson.bars * 16, bpm: bpm, reduceMotion: reduceMotion)
    }

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let count = min(visibleBars, min(lesson.bars, 4))
            let unscaledHeight = PracticeBandStyle.unscaledHeight(rows: rows.count)
            let bandScale = max(PracticeBandStyle.minRowHeight / PracticeBandStyle.baseRowHeight,
                                availableHeight / unscaledHeight)

            let contentHeight = max(availableHeight, unscaledHeight * bandScale)
            let gutter: CGFloat = scrolling ? 0 : (PracticeBandStyle.showPadLabels ? 96 * bandScale : 0)

            ZStack {
                ScrollView(.vertical) {
                    Group {
                        if scrolling {
                            ScrollingPattern(lesson: lesson, hits: hits, rows: rows, position: tapePosition,
                                             running: running, visibility: visibility, fromMemory: fromMemory, afterMe: afterMe,
                                             verdicts: verdicts, judgments: judgments, pass: pass,
                                             playedHits: playedHits, scoring: scoring,
                                             missGraceSteps: missGraceSteps, band: band, scale: bandScale)
                        } else {
                            let currentBar = min(lesson.bars - 1, max(0, Int(position) / 16))
                            let first = (currentBar / max(1, count)) * max(1, count)
                            let bars = Array(first..<min(first + count, lesson.bars))
                            let startStep = first * 16
                            let endStep = min(first + count, lesson.bars) * 16
                            let staticPlayed = visiblePlayedHits(steps: startStep..<endStep)
                            StaticPattern(lesson: lesson, hits: hits, rows: rows, bars: bars, firstBar: first,
                                          position: position, running: running, visibility: visibility,
                                          verdicts: verdicts, feedback: feedback,
                                          playedHits: staticPlayed,
                                          scoring: scoring, missGraceSteps: missGraceSteps,
                                          band: band, scale: bandScale, bpm: bpm, reduceMotion: reduceMotion,
                                          afterMe: afterMe)
                                .frame(height: contentHeight)
                        }
                    }
                    .frame(height: contentHeight)
                }
                .scrollBounceBehavior(.basedOnSize)

                if lesson.bars > 1 {
                    PatternPassProgress(position: position, bars: lesson.bars, gutter: gutter)
                        .padding(.bottom, Theme.Space.small)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }

                if scoring && countdown == nil {
                    BandTopSpineRuler(
                        bars: runBars,
                        tapePosition: tapePosition,
                        starMomentBeamActive: starMomentBeamActive
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .opacity(countdown == nil ? 1 : 0.22)
        .padding(.horizontal, Theme.Space.page)
        .overlay {
            if let countdown {
                GeometryReader { geometry in
                    CountInNumeral(number: countdown, size: min(geometry.size.height * 0.65, geometry.size.width * 0.7))
                        .id(countdown)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .allowsHitTesting(false)
            }
        }
        .overlay { BandEdgeGlow(tendency: edgeTendency) }
        .background {
            ZStack(alignment: .top) {
                band
                Theme.black.opacity(0.10).frame(height: 76)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.2), value: band)
        }
        .clipShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Rhythm pattern"))
        .accessibilityValue(
            countdown.map { String($0) } ?? {
                if afterMe {
                    return settings.localized(running ? (pass.isMultiple(of: 2) ? "Your turn" : "Listen…") : "After me")
                }
                if fromMemory && scoring {
                    switch visibility {
                    case .shown:
                        return settings.localized("Pass 1 · notes shown")
                    case .faded:
                        return settings.localized("Pass 2 · notes fading")
                    case .hidden:
                        return settings.localized("From memory, notes hidden")
                    }
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
    var top: CGFloat { 56 * scale }
    var bottom: CGFloat { size.height - 24 * scale }
    var height: CGFloat {
        max(1, (bottom - top - PracticeBandStyle.rowGap * scale * CGFloat(max(0, rows.count - 1))) / CGFloat(max(1, rows.count)))
    }
    var countY: CGFloat { 26 * scale }
    func y(_ row: Int) -> CGFloat { top + CGFloat(row) * (height + PracticeBandStyle.rowGap * scale) + height / 2 }
    func tile(x: CGFloat, width: CGFloat, row: Int) -> CGRect {
        let h = min(height - 4 * scale, 64 * scale)
        return CGRect(x: x - width * 0.42, y: y(row) - h / 2, width: width * 0.84, height: h)
    }
    var fontSize: CGFloat { 32 * scale }

    func drawRows(context: inout GraphicsContext) {
        for row in rows.indices {
            let rect = CGRect(x: -10, y: y(row) - height / 2, width: size.width + 20, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: 12), with: .color(Theme.white.opacity(0.16)))
        }
    }

    /// Drawn after every moving note, so old notes deliberately slide underneath.
    func drawLabels(band: Color, context: inout GraphicsContext) {
        guard PracticeBandStyle.showPadLabels else { return }
        for (row, pad) in rows.enumerated() {
            let labelHeight = min(height, 44 * scale)
            let rect = CGRect(x: -12, y: y(row) - labelHeight / 2, width: 100 * scale, height: labelHeight)
            context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(band))
            let duplicate = rows.filter { PadVoice.abbreviation($0) == PadVoice.abbreviation(pad) }.count > 1
            context.draw(Text(PadVoice.abbreviation(pad)).font(Theme.canvasDisplay(fontSize)).foregroundColor(Theme.black),
                         at: CGPoint(x: 0, y: y(row)), anchor: .leading)
            if duplicate {
                context.draw(Text(String(pad + 1)).font(Theme.canvasText(20 * scale)).monospacedDigit().foregroundColor(Theme.black),
                             at: CGPoint(x: 56 * scale, y: y(row)), anchor: .leading)
            }
        }
    }
}

private func drawBeat(step: Int, x: CGFloat, lanes: PatternLanes, context: inout GraphicsContext) {
    if step.isMultiple(of: 4) {
        context.draw(Text(String(step % 16 / 4 + 1)).font(Theme.canvasDisplay(28 * lanes.scale)).monospacedDigit().foregroundColor(Theme.black),
                     at: CGPoint(x: x, y: lanes.countY))
        let bar = step.isMultiple(of: 16)
        let lineTop = lanes.countY + 14 * lanes.scale
        var path = Path()
        path.move(to: CGPoint(x: x, y: lineTop))
        path.addLine(to: CGPoint(x: x, y: lanes.bottom))
        context.stroke(path, with: .color(Theme.black.opacity(bar ? 0.38 : 0.18)), lineWidth: bar ? 1.2 : 0.65)
        if bar {
            let tickWidth = max(4, 6 * lanes.scale)
            let tickHeight = max(2.5, 4 * lanes.scale)
            let tickY = lanes.countY + 12 * lanes.scale
            context.fill(Path(roundedRect: CGRect(x: x - tickWidth / 2, y: tickY, width: tickWidth, height: tickHeight), cornerRadius: 1),
                         with: .color(Theme.black.opacity(0.7)))
        }
    } else {
        context.fill(Path(ellipseIn: CGRect(x: x - 2.1, y: lanes.countY - 2.1, width: 4.2, height: 4.2)),
                     with: .color(Theme.black.opacity(0.5)))
    }
}

private struct StaticPattern: View {
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
    let scale: CGFloat
    var bpm: Int = 60
    var reduceMotion: Bool = false
    var afterMe: Bool = false

    var body: some View {
        let gutter: CGFloat = PracticeBandStyle.showPadLabels ? 96 * scale : 0
        let barCount = max(1, bars.count)
        let totalSteps = barCount * 16
        let startStep = firstBar * 16
        let endStep = (firstBar + barCount) * 16

        ZStack {
            Canvas { context, size in
                let cellWidth = max(1, (size.width - gutter) / CGFloat(totalSteps))
                let lanes = PatternLanes(size: size, rows: rows, scale: scale)
                lanes.drawRows(context: &context)

                // Beat division marks and numbers for each bar
                for (barIndex, _) in bars.enumerated() {
                    let barOffsetSteps = barIndex * 16
                    for step in 0..<16 {
                        let visibleStep = barOffsetSteps + step
                        let x = gutter + (CGFloat(visibleStep) + 0.5) * cellWidth
                        drawBeat(step: step, x: x, lanes: lanes, context: &context)
                    }
                }
            }

            Canvas { context, size in
                let cellWidth = max(1, (size.width - gutter) / CGFloat(totalSteps))
                let lanes = PatternLanes(size: size, rows: rows, scale: scale)
                let elapsedSeconds = position * 15.0 / Double(max(1, bpm))
                let fadeProgress = reduceMotion ? 1.0 : min(1.0, max(0.0, elapsedSeconds / 0.25))

                for (row, pad) in rows.enumerated() {
                    if visibility != .hidden || afterMe {
                        for hit in hits where hit.padIndex == pad && hit.step >= startStep && hit.step < endStep {
                            let visibleStep = hit.step - startStep
                            let x = gutter + (CGFloat(visibleStep) + 0.5) * cellWidth
                            let rect = lanes.tile(x: x, width: cellWidth, row: row)
                            let tail = feedback.position < Double(hit.step) ? feedback.strength(offset: -1, step: Double(hit.step)) : 0
                            let mark = hitMark(hit, judgments: feedback.judgments[feedback.pass + (tail > 0 ? -1 : 0)] ?? [:],
                                               scoring: scoring, elapsedSteps: tail > 0 ? Double(feedback.totalSteps) : position - Double(hit.step),
                                               grace: missGraceSteps)
                            drawHit(hit, in: rect, mark: mark, strength: tail > 0 ? tail : 1,
                                    visibility: afterMe ? .shown : visibility, fadeProgress: fadeProgress,
                                    fontSize: lanes.fontSize, context: &context)
                        }
                    } else if fadeProgress < 1 {
                        for hit in hits where hit.padIndex == pad && hit.step >= startStep && hit.step < endStep {
                            let visibleStep = hit.step - startStep
                            let x = gutter + (CGFloat(visibleStep) + 0.5) * cellWidth
                            let rect = lanes.tile(x: x, width: cellWidth, row: row)
                            drawHit(hit, in: rect, mark: nil, strength: 1,
                                    visibility: .hidden, fadeProgress: fadeProgress,
                                    fontSize: lanes.fontSize, context: &context)
                        }
                    }
                }
            }
            .opacity(afterMe ? 0 : 1)
            .animation(reduceMotion ? nil : Theme.Motion.fast, value: afterMe)

            Canvas { context, size in
                let cellWidth = max(1, (size.width - gutter) / CGFloat(totalSteps))
                let lanes = PatternLanes(size: size, rows: rows, scale: scale)

                if visibility == .hidden && running {
                    for (row, pad) in rows.enumerated() {
                        var playedContext = context
                        let visiblePosition = position - Double(startStep)
                        let markerX = gutter + CGFloat(visiblePosition) * cellWidth
                        let behindMarker = min(size.width, max(0, markerX))
                        playedContext.clip(to: Path(CGRect(x: 0, y: 0, width: behindMarker, height: size.height)))

                        let barPlayedHits = playedHits.filter {
                            $0.padIndex == pad && $0.step >= Double(startStep) && $0.step < Double(endStep)
                        }
                        for hit in barPlayedHits {
                            let visibleStep = hit.step - Double(startStep)
                            let x = gutter + (CGFloat(visibleStep) + 0.5) * cellWidth
                            let rect = lanes.tile(x: x, width: cellWidth, row: row)
                            var hitContext = hit.pass == feedback.pass ? playedContext : context
                            if hit.pass != feedback.pass {
                                hitContext.opacity = feedback.strength(offset: -1, step: hit.step)
                            }
                            drawPlayedHit(hit, in: rect, fontSize: lanes.fontSize, context: &hitContext)
                        }
                    }
                }

                // Smooth playhead moving across bar boundaries at constant speed
                let visiblePosition = position - Double(startStep)
                if running && visiblePosition >= 0 && visiblePosition <= Double(totalSteps) {
                    let markerX = gutter + CGFloat(visiblePosition) * cellWidth
                    drawMarker(x: markerX, top: lanes.top - 4 * scale, bottom: lanes.bottom + 4, context: &context)
                }

                // Pad labels appear once, on the left of the whole row of bars
                lanes.drawLabels(band: band, context: &context)
            }
        }
    }
}

private struct ScrollingPattern: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let lesson: Lesson
    let hits: [LessonHit]
    let rows: [Int]
    let position: Double
    let running: Bool
    let visibility: NoteVisibility
    var fromMemory: Bool = false
    var afterMe: Bool = false
    let verdicts: [Int: BarVerdict]
    let judgments: [Int: [LessonHit: HitJudgment]]
    let pass: Int
    let playedHits: [PlayedHit]
    let scoring: Bool
    let missGraceSteps: Double
    let band: Color
    let scale: CGFloat

    var body: some View {
        let total = max(16, lesson.bars * 16)

        ZStack {
            Canvas { context, size in
                let cellWidth = max(PracticeBandStyle.cellWidth(rows: rows, scale: scale), size.width / 24)
                let markerX = size.width / 3
                let lanes = PatternLanes(size: size, rows: rows, scale: scale)
                let firstStep = Int(floor(position - Double(markerX / cellWidth))) - 1
                let lastStep = Int(ceil(position + Double((size.width - markerX) / cellWidth))) + 1
                lanes.drawRows(context: &context)
                for globalStep in firstStep...lastStep {
                    guard globalStep >= 0 else { continue }
                    let step = (globalStep % total + total) % total
                    let x = markerX + CGFloat(Double(globalStep) - position) * cellWidth
                    drawBeat(step: step, x: x, lanes: lanes, context: &context)
                }
            }

            Canvas { context, size in
                let cellWidth = max(PracticeBandStyle.cellWidth(rows: rows, scale: scale), size.width / 24)
                let markerX = size.width / 3
                let lanes = PatternLanes(size: size, rows: rows, scale: scale)
                let firstStep = Int(floor(position - Double(markerX / cellWidth))) - 1
                let lastStep = Int(ceil(position + Double((size.width - markerX) / cellWidth))) + 1

                for globalStep in firstStep...lastStep {
                    guard globalStep >= 0 else { continue }
                    let step = (globalStep % total + total) % total
                    let recordedPass = globalStep / total + 1
                    let stepVisibility: NoteVisibility = afterMe ? .shown : NoteVisibility.derive(
                        fromMemory: fromMemory,
                        running: running,
                        listen: false,
                        isSectionLoop: false,
                        pass: recordedPass,
                        fadeNotes: settings.fadeMemoryNotes
                    )
                    let x = markerX + CGFloat(Double(globalStep) - position) * cellWidth
                    if stepVisibility != .hidden || afterMe {
                        for hit in hits where hit.step == step {
                            guard let row = rows.firstIndex(of: hit.padIndex) else { continue }
                            let rect = lanes.tile(x: x, width: cellWidth, row: row)
                            let strength = min(1, max(0, rect.maxX / rect.width))
                            let mark = hitMark(hit, judgments: judgments[recordedPass] ?? [:], scoring: scoring,
                                               elapsedSteps: position - Double(globalStep), grace: missGraceSteps)
                            drawHit(hit, in: rect, mark: mark, strength: strength, visibility: afterMe ? .shown : stepVisibility,
                                    fontSize: lanes.fontSize, context: &context)
                        }
                    }
                }
            }
            .opacity(afterMe ? 0 : 1)
            .animation(reduceMotion ? nil : Theme.Motion.fast, value: afterMe)

            Canvas { context, size in
                let cellWidth = max(PracticeBandStyle.cellWidth(rows: rows, scale: scale), size.width / 24)
                let markerX = size.width / 3
                let lanes = PatternLanes(size: size, rows: rows, scale: scale)
                let rowTop = lanes.top
                let rowBottom = lanes.bottom

                if visibility == .hidden && running {
                    var playedContext = context
                    playedContext.clip(to: Path(CGRect(x: 0, y: rowTop, width: markerX, height: max(1, rowBottom - rowTop))))
                    for hit in playedHits {
                        guard let row = rows.firstIndex(of: hit.padIndex) else { continue }
                        let step = hit.tapeStep(totalSteps: total)
                        guard step >= 0, step < position else { continue }
                        let x = markerX + CGFloat(step - position) * cellWidth
                        guard x + cellWidth * 0.42 >= 0 else { continue }
                        let rect = lanes.tile(x: x, width: cellWidth, row: row)
                        var hitContext = playedContext
                        hitContext.opacity = min(1, max(0, rect.maxX / rect.width))
                        drawPlayedHit(hit, in: rect, fontSize: lanes.fontSize, context: &hitContext)
                    }
                }
                drawMarker(x: markerX, top: lanes.top - 4 * scale, bottom: rowBottom + 4, context: &context)
                lanes.drawLabels(band: band, context: &context)
            }
        }
    }
}

private func drawPlayedHit(_ hit: PlayedHit, in rect: CGRect, fontSize: CGFloat,
                           context: inout GraphicsContext) {
    let note = LessonHit(step: Int(hit.step), padIndex: hit.padIndex, hand: "L", velocity: 0)
    drawHit(note, in: rect, mark: hit.mark, strength: 1, visibility: .shown, fontSize: fontSize, context: &context)
}

private func hitMark(_ hit: LessonHit, judgments: [LessonHit: HitJudgment], scoring: Bool,
                     elapsedSteps: Double, grace: Double) -> HitMark? {
    guard scoring else { return nil }
    if let judgment = judgments[hit] { return judgment == .off ? .off : .correct }
    return elapsedSteps > grace ? .wrong : nil
}

private func drawHit(_ hit: LessonHit, in rect: CGRect, mark: HitMark?, strength: Double = 1,
                     visibility: NoteVisibility = .shown, fadeProgress: Double = 1,
                     fontSize: CGFloat, context: inout GraphicsContext) {
    if mark != nil, strength < 1 {
        drawHit(hit, in: rect, mark: nil, strength: 1, visibility: visibility, fadeProgress: fadeProgress, fontSize: fontSize, context: &context)
        if strength > 0 {
            var coloured = context
            coloured.opacity *= strength
            drawHit(hit, in: rect, mark: mark, strength: 1, visibility: visibility, fadeProgress: fadeProgress, fontSize: fontSize, context: &coloured)
        }
        return
    }
    let cornerRadius = min(7, rect.width * 0.25)
    let innerRadius = max(1, cornerRadius - 1)

    switch visibility {
    case .shown:
        var fillContext = context
        fillContext.opacity *= strength
        fillContext.fill(Path(roundedRect: rect, cornerRadius: cornerRadius), with: .color(Theme.white))
        if let mark {
            fillContext.fill(Path(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: innerRadius),
                             with: .color(PracticeBandStyle.hitColor(mark)))
            var accent = Path()
            let padInset = min(4, rect.width * 0.25)
            let vPad = min(5, rect.height * 0.2)
            if mark == .wrong {
                accent.move(to: CGPoint(x: rect.minX + padInset, y: rect.minY + vPad))
                accent.addLine(to: CGPoint(x: rect.minX + padInset, y: rect.maxY - vPad))
            } else if mark == .off {
                accent.move(to: CGPoint(x: rect.minX + padInset, y: rect.maxY - vPad))
                accent.addLine(to: CGPoint(x: rect.maxX - padInset, y: rect.maxY - vPad))
            }
            fillContext.stroke(accent, with: .color(Theme.black), lineWidth: 1.4)
        }
        let hitFontSize = min(fontSize, max(7, rect.width * 0.65))
        fillContext.draw(Text(PadVoice.abbreviation(hit.padIndex)).font(Theme.canvasDisplay(hitFontSize))
            .foregroundColor(Theme.black), at: CGPoint(x: rect.midX, y: rect.midY))

    case .faded:
        var fadedContext = context
        fadedContext.opacity *= strength
        // Low contrast outline: outline only, no pad label
        fadedContext.stroke(Path(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75), cornerRadius: cornerRadius),
                            with: .color(Theme.ink.opacity(0.35)), lineWidth: 1.5)
        if let mark {
            fadedContext.fill(Path(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: innerRadius),
                             with: .color(PracticeBandStyle.hitColor(mark)))
            var accent = Path()
            let padInset = min(4, rect.width * 0.25)
            let vPad = min(5, rect.height * 0.2)
            if mark == .wrong {
                accent.move(to: CGPoint(x: rect.minX + padInset, y: rect.minY + vPad))
                accent.addLine(to: CGPoint(x: rect.minX + padInset, y: rect.maxY - vPad))
            } else if mark == .off {
                accent.move(to: CGPoint(x: rect.minX + padInset, y: rect.maxY - vPad))
                accent.addLine(to: CGPoint(x: rect.maxX - padInset, y: rect.maxY - vPad))
            }
            fadedContext.stroke(accent, with: .color(Theme.black), lineWidth: 1.4)
        }
        if fadeProgress < 1 {
            var crossContext = context
            crossContext.opacity *= strength * (1.0 - fadeProgress)
            crossContext.fill(Path(roundedRect: rect, cornerRadius: cornerRadius), with: .color(Theme.white))
            let hitFontSize = min(fontSize, max(7, rect.width * 0.65))
            crossContext.draw(Text(PadVoice.abbreviation(hit.padIndex)).font(Theme.canvasDisplay(hitFontSize))
                .foregroundColor(Theme.black), at: CGPoint(x: rect.midX, y: rect.midY))
        }

    case .hidden:
        if fadeProgress < 1 {
            var crossContext = context
            crossContext.opacity *= strength * (1.0 - fadeProgress)
            crossContext.stroke(Path(roundedRect: rect.insetBy(dx: 0.75, dy: 0.75), cornerRadius: cornerRadius),
                                with: .color(Theme.ink.opacity(0.35)), lineWidth: 1.5)
        }
    }
}

private func drawMarker(x: CGFloat, top: CGFloat, bottom: CGFloat, context: inout GraphicsContext) {
    var path = Path()
    path.move(to: CGPoint(x: x, y: top)); path.addLine(to: CGPoint(x: x, y: bottom))
    context.stroke(path, with: .color(Theme.white), lineWidth: 5)
    context.stroke(path, with: .color(Theme.black), lineWidth: 1.7)
    var cap = Path()
    cap.move(to: CGPoint(x: x - 5, y: top - 3))
    cap.addLines([CGPoint(x: x + 5, y: top - 3), CGPoint(x: x, y: top + 3)])
    cap.closeSubpath()
    context.fill(cap, with: .color(Theme.black))
}

/// A single thin line at the bottom edge of the pattern band with bar notches.
private struct PatternPassProgress: View {
    @Environment(SettingsManager.self) private var settings
    let position: Double
    let bars: Int
    var gutter: CGFloat = 0

    var body: some View {
        let count = max(1, bars)
        let totalSteps = Double(count * 16)
        let localPosition = position.truncatingRemainder(dividingBy: totalSteps)
        let fraction = totalSteps > 0 ? min(1, max(0, localPosition / totalSteps)) : 0
        Canvas { context, size in
            let y = size.height - 2
            let trackWidth = max(1, size.width - gutter)
            context.fill(Path(CGRect(x: gutter, y: y - 1, width: trackWidth, height: 1.5)),
                         with: .color(Theme.black.opacity(0.25)))
            if fraction > 0 {
                context.fill(Path(CGRect(x: gutter, y: y - 1, width: trackWidth * fraction, height: 2)),
                             with: .color(Theme.black))
            }
            for bar in 1..<count {
                let x = min(size.width - 1, max(gutter + 1, gutter + trackWidth * Double(bar) / Double(count)))
                context.fill(Path(CGRect(x: x - 0.5, y: y - 4, width: 1, height: 6)),
                             with: .color(Theme.black))
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Position in the current pass"))
        .accessibilityValue(settings.localized("Bar %lld / %lld, %lld percent",
            min(count, Int(position) / 16 + 1), count, Int(fraction * 100)))
    }
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
