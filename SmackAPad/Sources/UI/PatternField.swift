import SwiftUI

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
    let hidden: Bool
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
            let contentHeight = max(geometry.size.height,
                PracticeBandStyle.minimumHeight(rows: rows.count, scale: notationScale))
            ScrollView(.vertical) {
                Group {
                    if scrolling {
                        ScrollingPattern(lesson: lesson, hits: hits, rows: rows, position: tapePosition,
                                         running: running, hidden: hidden, verdicts: verdicts,
                                         judgments: judgments, pass: pass,
                                         playedHits: playedHits,
                                         scoring: scoring, missGraceSteps: missGraceSteps, band: band, scale: notationScale)
                    } else {
                        let minimumWidth = PracticeBandStyle.barWidth(rows: rows, scale: notationScale)
                        let columns = geometry.size.width >= minimumWidth * 2 + Theme.Space.regular ? 2 : 1
                        let minimumHeight = PracticeBandStyle.minimumHeight(rows: rows.count, scale: notationScale)
                        let verticalSlots = max(1, Int((contentHeight + Theme.Space.regular) / (minimumHeight + Theme.Space.regular)))
                        // Preserve full-size notation; page through fewer bars when more cannot fit.
                        let count = min(visibleBars, min(lesson.bars, min(4, columns * verticalSlots)))
                        let currentBar = min(lesson.bars - 1, max(0, Int(position) / 16))
                        let first = (currentBar / max(1, count)) * max(1, count)
                        let bars = Array(first..<min(first + count, lesson.bars))
                        let rowCount = Int(ceil(Double(bars.count) / Double(columns)))
                        let gap = Theme.Space.regular
                        let height = max(1, (contentHeight - CGFloat(rowCount - 1) * gap) / CGFloat(max(1, rowCount)))
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: columns), spacing: gap) {
                            ForEach(bars, id: \.self) { bar in
                                PatternBar(bar: bar, hits: hits.filter { $0.step / 16 == bar }, rows: rows,
                                           position: position - Double(bar * 16), active: running && bar == currentBar,
                                           hidden: hidden, verdict: verdicts[bar],
                                           feedback: feedback,
                                           playedHits: visiblePlayedHits(steps: (bar * 16)..<((bar + 1) * 16)),
                                           scoring: scoring, missGraceSteps: missGraceSteps, band: band, scale: notationScale)
                                    .frame(height: height)
                            }
                        }
                    }
                }
                .frame(height: contentHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
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
        .overlay(alignment: .bottom) {
            if lesson.bars > 1 {
                PatternPassProgress(position: position, bars: lesson.bars)
                    .padding(.horizontal, Theme.Space.page).padding(.bottom, Theme.Space.small)
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
        .clipShape(RoundedRectangle(cornerRadius: PracticeBandStyle.radius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Rhythm pattern"))
        .accessibilityValue(countdown.map { String($0) } ?? (hidden ? settings.localized("From memory, notes hidden") :
            settings.localized("%lld bars, %@", lesson.bars, rows.map { PadVoice.name($0, settings: settings) }.joined(separator: ", "))))
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
        var path = Path()
        path.move(to: CGPoint(x: x, y: lanes.top - 20))
        path.addLine(to: CGPoint(x: x, y: lanes.bottom))
        let bar = step.isMultiple(of: 16)
        context.stroke(path, with: .color(Theme.black.opacity(bar ? 0.38 : 0.18)), lineWidth: bar ? 1.2 : 0.65)
        if bar {
            context.fill(Path(roundedRect: CGRect(x: x - 3, y: 12, width: 6, height: 8), cornerRadius: 2),
                         with: .color(Theme.black.opacity(0.7)))
        }
    } else {
        context.fill(Path(ellipseIn: CGRect(x: x - 2.1, y: lanes.countY - 2.1, width: 4.2, height: 4.2)),
                     with: .color(Theme.black.opacity(0.5)))
    }
}

private struct PatternBar: View {
    let bar: Int
    let hits: [LessonHit]
    let rows: [Int]
    let position: Double
    let active: Bool
    let hidden: Bool
    let verdict: BarVerdict?
    let feedback: PatternFeedback
    let playedHits: [PlayedHit]
    let scoring: Bool
    let missGraceSteps: Double
    let band: Color
    let scale: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    canvas
                        .frame(width: max(geometry.size.width, PracticeBandStyle.barWidth(rows: rows, scale: scale)),
                               height: geometry.size.height)
                        .overlay(alignment: .topLeading) {
                            // Beat anchors keep the active part visible in narrow windows.
                            HStack(spacing: 0) {
                                Color.clear.frame(width: 96 * scale, height: 1)
                                ForEach(0..<4, id: \.self) { beat in
                                    Color.clear.frame(width: PracticeBandStyle.cellWidth(rows: rows, scale: scale) * 4,
                                                      height: 1).id(beat)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                }
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: Int(position) / 4) { _, beat in
                    if active { proxy.scrollTo(beat, anchor: .center) }
                }
                .onChange(of: active) { _, active in
                    if active { proxy.scrollTo(max(0, Int(position) / 4), anchor: .center) }
                }
            }
        }
    }

    private var canvas: some View {
        Canvas { context, size in
            // Leave a fixed label gutter even when the first static note is at step zero.
            let gutter: CGFloat = PracticeBandStyle.showPadLabels ? 96 * scale : 0
            let cellWidth = max(1, (size.width - gutter) / 16)
            let lanes = PatternLanes(size: size, rows: rows, scale: scale)
            lanes.drawRows(context: &context)
            for step in 0..<16 {
                drawBeat(step: step, x: gutter + (CGFloat(step) + 0.5) * cellWidth, lanes: lanes, context: &context)
            }
            for (row, pad) in rows.enumerated() {
                if !hidden {
                    for hit in hits where hit.padIndex == pad {
                        let step = hit.step % 16
                        let rect = lanes.tile(x: gutter + (CGFloat(step) + 0.5) * cellWidth, width: cellWidth, row: row)
                        let tail = feedback.position < Double(hit.step) ? feedback.strength(offset: -1, step: Double(hit.step)) : 0
                        let mark = hitMark(hit, judgments: feedback.judgments[feedback.pass + (tail > 0 ? -1 : 0)] ?? [:],
                                           scoring: scoring, elapsedSteps: tail > 0 ? Double(feedback.totalSteps) : position - Double(step),
                                           grace: missGraceSteps)
                        drawHit(hit, in: rect, mark: mark, strength: tail > 0 ? tail : 1,
                                fontSize: lanes.fontSize, context: &context)
                    }
                } else {
                    var playedContext = context
                    let behindMarker = min(size.width, max(0, gutter + (CGFloat(position) + 0.5) * cellWidth))
                    playedContext.clip(to: Path(CGRect(x: 0, y: 0, width: behindMarker, height: size.height)))
                    for hit in playedHits where hit.padIndex == pad {
                        let step = hit.step - Double(bar * 16)
                        let rect = lanes.tile(x: gutter + (CGFloat(step) + 0.5) * cellWidth, width: cellWidth, row: row)
                        var hitContext = hit.pass == feedback.pass ? playedContext : context
                        if hit.pass != feedback.pass { hitContext.opacity = feedback.strength(offset: -1, step: hit.step) }
                        drawPlayedHit(hit, in: rect, fontSize: lanes.fontSize, context: &hitContext)
                    }
                }
            }
            if active {
                drawMarker(x: gutter + (CGFloat(position) + 0.5) * cellWidth, top: lanes.top - 4 * scale,
                           bottom: lanes.bottom + 4, context: &context)
            }
            lanes.drawLabels(band: band, context: &context)
        }
    }
}

private struct ScrollingPattern: View {
    @Environment(SettingsManager.self) private var settings
    let lesson: Lesson
    let hits: [LessonHit]
    let rows: [Int]
    let position: Double
    let running: Bool
    let hidden: Bool
    let verdicts: [Int: BarVerdict]
    let judgments: [Int: [LessonHit: HitJudgment]]
    let pass: Int
    let playedHits: [PlayedHit]
    let scoring: Bool
    let missGraceSteps: Double
    let band: Color
    let scale: CGFloat

    var body: some View {
        Canvas { context, size in
            let total = max(16, lesson.bars * 16)
            let cellWidth = max(PracticeBandStyle.cellWidth(rows: rows, scale: scale), size.width / 24)
            let markerX = size.width / 3
            let lanes = PatternLanes(size: size, rows: rows, scale: scale)
            let rowTop = lanes.top
            let rowBottom = lanes.bottom
            let firstStep = Int(floor(position - Double(markerX / cellWidth))) - 1
            let lastStep = Int(ceil(position + Double((size.width - markerX) / cellWidth))) + 1
            lanes.drawRows(context: &context)
            for globalStep in firstStep...lastStep {
                guard globalStep >= 0 else { continue }
                let step = (globalStep % total + total) % total
                let recordedPass = globalStep / total + 1
                let x = markerX + CGFloat(Double(globalStep) - position) * cellWidth
                drawBeat(step: step, x: x, lanes: lanes, context: &context)
                if !hidden {
                    for hit in hits where hit.step == step {
                        guard let row = rows.firstIndex(of: hit.padIndex) else { continue }
                        let rect = lanes.tile(x: x, width: cellWidth, row: row)
                        // A note keeps the judgment of its own tape repeat. Fade only
                        // as its block leaves the viewport, independent of pass changes.
                        let strength = min(1, max(0, rect.maxX / rect.width))
                        let mark = hitMark(hit, judgments: judgments[recordedPass] ?? [:], scoring: scoring,
                                           elapsedSteps: position - Double(globalStep), grace: missGraceSteps)
                        drawHit(hit, in: rect, mark: mark, strength: strength,
                                fontSize: lanes.fontSize, context: &context)
                    }
                }
            }
            if hidden && running {
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

private func drawPlayedHit(_ hit: PlayedHit, in rect: CGRect, fontSize: CGFloat,
                           context: inout GraphicsContext) {
    let note = LessonHit(step: Int(hit.step), padIndex: hit.padIndex, hand: "L", velocity: 0)
    drawHit(note, in: rect, mark: hit.mark, fontSize: fontSize, context: &context)
}

private func hitMark(_ hit: LessonHit, judgments: [LessonHit: HitJudgment], scoring: Bool,
                     elapsedSteps: Double, grace: Double) -> HitMark? {
    guard scoring else { return nil }
    if let judgment = judgments[hit] { return judgment == .off ? .off : .correct }
    return elapsedSteps > grace ? .wrong : nil
}

private func drawHit(_ hit: LessonHit, in rect: CGRect, mark: HitMark?, strength: Double = 1,
                     fontSize: CGFloat, context: inout GraphicsContext) {
    if mark != nil, strength < 1 {
        drawHit(hit, in: rect, mark: nil, fontSize: fontSize, context: &context)
        if strength > 0 {
            var coloured = context
            coloured.opacity *= strength
            drawHit(hit, in: rect, mark: mark, fontSize: fontSize, context: &coloured)
        }
        return
    }
    context.fill(Path(roundedRect: rect, cornerRadius: 7), with: .color(Theme.white))
    if let mark {
        context.fill(Path(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 6),
                     with: .color(PracticeBandStyle.hitColor(mark)))
        var accent = Path()
        if mark == .wrong {
            accent.move(to: CGPoint(x: rect.minX + 4, y: rect.minY + 5))
            accent.addLine(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 5))
        } else if mark == .off {
            accent.move(to: CGPoint(x: rect.minX + 4, y: rect.maxY - 5))
            accent.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.maxY - 5))
        }
        context.stroke(accent, with: .color(Theme.black), lineWidth: 1.4)
    }
    context.draw(Text(PadVoice.abbreviation(hit.padIndex)).font(Theme.canvasDisplay(fontSize))
        .foregroundColor(Theme.black), at: CGPoint(x: rect.midX, y: rect.midY))
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

    var body: some View {
        let count = max(1, bars)
        let totalSteps = Double(count * 16)
        let localPosition = position.truncatingRemainder(dividingBy: totalSteps)
        let fraction = totalSteps > 0 ? min(1, max(0, localPosition / totalSteps)) : 0
        Canvas { context, size in
            let y = size.height - 2
            context.fill(Path(CGRect(x: 0, y: y - 1, width: size.width, height: 1.5)),
                         with: .color(Theme.black.opacity(0.25)))
            if fraction > 0 {
                context.fill(Path(CGRect(x: 0, y: y - 1, width: size.width * fraction, height: 2)),
                             with: .color(Theme.black))
            }
            for bar in 1..<count {
                let x = min(size.width - 1, max(1, size.width * Double(bar) / Double(count)))
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
