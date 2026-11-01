import SwiftUI

/// A strike's fractional position belongs to the pass in which it was played.
struct PlayedHit {
    let padIndex: Int
    let step: Double
    let pass: Int
    let mark: HitMark?

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
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let lesson: Lesson
    let hits: [LessonHit]
    let position: Double
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
            if scrolling {
                ScrollingPattern(lesson: lesson, hits: hits, rows: rows, position: position,
                                 running: running, hidden: hidden, verdicts: verdicts,
                                 feedback: feedback,
                                 playedHits: visiblePlayedHits(steps: 0..<(lesson.bars * 16)),
                                 scoring: scoring, missGraceSteps: missGraceSteps)
            } else {
                let count = min(visibleBars, min(lesson.bars, 4))
                let currentBar = min(lesson.bars - 1, max(0, Int(position) / 16))
                let first = (currentBar / max(1, count)) * max(1, count)
                let bars = Array(first..<min(first + count, lesson.bars))
                let columns = count > 2 ? 2 : 1
                let rowCount = Int(ceil(Double(bars.count) / Double(columns)))
                let gap = Theme.Space.regular
                let height = max(1, (geometry.size.height - CGFloat(rowCount - 1) * gap) / CGFloat(max(1, rowCount)))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: columns), spacing: gap) {
                    ForEach(bars, id: \.self) { bar in
                        PatternBar(bar: bar, hits: hits.filter { $0.step / 16 == bar }, rows: rows,
                                   position: position - Double(bar * 16), active: running && bar == currentBar,
                                   hidden: hidden, verdict: verdicts[bar],
                                   feedback: feedback,
                                   playedHits: visiblePlayedHits(steps: (bar * 16)..<((bar + 1) * 16)),
                                   scoring: scoring, missGraceSteps: missGraceSteps)
                            .frame(height: height)
                    }
                }
            }
        }
        .opacity(countdown == nil ? 1 : 0.22)
        .padding(Theme.Space.page)
        .overlay {
            if let countdown {
                GeometryReader { box in
                    Text("\(countdown)")
                        .font(Theme.canvasDisplay(min(box.size.height * 0.62, 240)))
                        .foregroundStyle(Theme.black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .allowsHitTesting(false)
            }
        }
        .background(Theme.orange)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Rhythm pattern"))
        .accessibilityValue(countdown.map { String($0) } ?? (hidden ? settings.localized("From memory, notes hidden") :
            settings.localized("%lld bars, %@", lesson.bars, rows.map { PadVoice.name($0, settings: settings) }.joined(separator: ", "))))
    }
}

private struct PatternBar: View {
    @Environment(SettingsManager.self) private var settings
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

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            Rectangle().fill(active ? Theme.black : Theme.orange).frame(width: Theme.Size.bracket)
            VStack(alignment: .leading, spacing: Theme.Space.small) {
                BarHeader(bar: bar, verdict: verdict)
                Canvas { context, size in
                    let cellWidth = size.width / 16
                    let countHeight: CGFloat = 32
                    let rowHeight = max(1, (size.height - countHeight) / CGFloat(max(1, rows.count)))
                    let dense = cellWidth < 36 || rowHeight < 36
                    for step in 0..<16 {
                        let beat = step.isMultiple(of: 4)
                        guard beat || !dense else { continue }
                        let label = beat ? String(step / 4 + 1) : ["", "e", "&", "a"][step % 4]
                        context.draw(Text(label).font(beat ? Theme.canvasDisplay(Theme.Size.emphasis) : Theme.canvasText(Theme.Size.body)).foregroundColor(Theme.black),
                                     at: CGPoint(x: (CGFloat(step) + 0.5) * cellWidth, y: countHeight / 2))
                    }
                    for (row, pad) in rows.enumerated() {
                        let y = countHeight + (CGFloat(row) + 0.5) * rowHeight
                        var line = Path()
                        line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(line, with: .color(Theme.black), lineWidth: 1)
                        if !hidden {
                            for hit in hits where hit.padIndex == pad {
                                let step = hit.step % 16
                                let rect = CGRect(x: (CGFloat(step) + 0.08) * cellWidth,
                                                  y: y - min(rowHeight - 4, 44) / 2,
                                                  width: cellWidth * 0.84, height: max(8, min(rowHeight - 4, 44)))
                                let tail = feedback.position < Double(hit.step)
                                    ? feedback.strength(offset: -1, step: Double(hit.step)) : 0
                                let mark = hitMark(hit, judgments: feedback.judgments[feedback.pass + (tail > 0 ? -1 : 0)] ?? [:],
                                                   scoring: scoring,
                                                   elapsedSteps: tail > 0 ? Double(feedback.totalSteps) : position - Double(step),
                                                   grace: missGraceSteps)
                                drawHit(hit, in: rect, active: active && Int(position) == step, mark: mark,
                                        strength: tail > 0 ? tail : 1,
                                        fontSize: dense ? Theme.Size.dense : Theme.Size.body, context: &context)
                            }
                        } else {
                            var playedContext = context
                            let behindMarker = min(size.width, max(0, (CGFloat(position) + 0.5) * cellWidth))
                            playedContext.clip(to: Path(CGRect(x: 0, y: 0, width: behindMarker, height: size.height)))
                            for hit in playedHits where hit.padIndex == pad {
                                let step = hit.step - Double(bar * 16)
                                let rect = CGRect(x: (CGFloat(step) + 0.08) * cellWidth,
                                                  y: y - min(rowHeight - 4, 44) / 2,
                                                  width: cellWidth * 0.84, height: max(8, min(rowHeight - 4, 44)))
                                var hitContext = hit.pass == feedback.pass ? playedContext : context
                                if hit.pass != feedback.pass { hitContext.opacity = feedback.strength(offset: -1, step: hit.step) }
                                drawPlayedHit(hit, hand: hits.first(where: { $0.padIndex == pad })?.hand ?? "L",
                                              in: rect, fontSize: dense ? Theme.Size.dense : Theme.Size.body,
                                              context: &hitContext)
                            }
                        }
                    }
                    if active {
                        drawMarker(x: (CGFloat(position) + 0.5) * cellWidth, top: countHeight,
                                   bottom: size.height, context: &context)
                    }
                }
            }
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
    let feedback: PatternFeedback
    let playedHits: [PlayedHit]
    let scoring: Bool
    let missGraceSteps: Double

    var body: some View {
        Canvas { context, size in
            let total = max(16, lesson.bars * 16)
            let cellWidth = max(38, size.width / 24)
            let markerX = size.width / 3
            let countY = size.height * 0.24
            let rowTop = countY + 36
            let rowBottom = size.height - 64
            let rowHeight = max(1, (rowBottom - rowTop) / CGFloat(max(1, rows.count)))
            let firstStep = Int(floor(position - Double(markerX / cellWidth))) - 1
            let lastStep = Int(ceil(position + Double((size.width - markerX) / cellWidth))) + 1
            for (row, _) in rows.enumerated() {
                let y = rowTop + (CGFloat(row) + 0.5) * rowHeight
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Theme.black), lineWidth: 1)
            }
            for globalStep in firstStep...lastStep {
                let step = (globalStep % total + total) % total
                let bar = step / 16
                let x = markerX + CGFloat(Double(globalStep) - position) * cellWidth
                let beat = step.isMultiple(of: 4)
                let label = beat ? String(step % 16 / 4 + 1) : ["", "e", "&", "a"][step % 4]
                context.draw(Text(label).font(beat ? Theme.canvasDisplay(Theme.Size.beat) : Theme.canvasText(Theme.Size.body)).foregroundColor(Theme.black),
                             at: CGPoint(x: x, y: countY))
                if step.isMultiple(of: 16) {
                    let next = globalStep >= total
                    let word = next ? settings.localized("next pass") : verdicts[bar]?.label(settings: settings)
                    let header = "\(settings.localized("BAR %lld", bar + 1))\(word.map { "  \($0)" } ?? "")"
                    context.draw(Text(header).font(Theme.canvasText(Theme.Size.body)).foregroundColor(Theme.black),
                                 at: CGPoint(x: max(0, x), y: 16), anchor: .topLeading)
                    if bar == Int(position) / 16 && globalStep >= 0 && globalStep < total {
                        context.fill(Path(CGRect(x: x - Theme.Size.bracket / 2, y: rowTop, width: Theme.Size.bracket,
                                                 height: max(1, rowBottom - rowTop))), with: .color(Theme.black))
                    }
                }
                if beat {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: countY + 22))
                    path.addLine(to: CGPoint(x: x, y: rowBottom))
                    context.stroke(path, with: .color(Theme.black), lineWidth: step.isMultiple(of: 16) ? 3 : 1)
                }
                if !hidden {
                    for hit in hits where hit.step == step {
                        guard let row = rows.firstIndex(of: hit.padIndex) else { continue }
                        let y = rowTop + (CGFloat(row) + 0.5) * rowHeight
                        let rect = CGRect(x: x - cellWidth * 0.42, y: y - min(rowHeight - 6, 64) / 2,
                                          width: cellWidth * 0.84, height: max(8, min(rowHeight - 6, 64)))
                        let offset = Int(floor(Double(globalStep) / Double(total)))
                        let strength = feedback.strength(offset: offset, step: Double(step))
                        let mark = strength > 0
                            ? hitMark(hit, judgments: feedback.judgments[feedback.pass + offset] ?? [:], scoring: scoring,
                                      elapsedSteps: position - Double(globalStep), grace: missGraceSteps)
                            : nil
                        drawHit(hit, in: rect, active: running && globalStep == Int(position), mark: mark,
                                strength: strength, fontSize: Theme.Size.body, context: &context)
                    }
                }
            }
            if hidden {
                var playedContext = context
                playedContext.clip(to: Path(CGRect(x: 0, y: rowTop, width: markerX, height: max(1, rowBottom - rowTop))))
                for hit in playedHits {
                    guard let row = rows.firstIndex(of: hit.padIndex) else { continue }
                    let step = hit.step + Double((hit.pass - feedback.pass) * total)
                    let x = markerX + CGFloat(step - position) * cellWidth
                    guard x + cellWidth * 0.42 >= 0 else { continue }
                    let y = rowTop + (CGFloat(row) + 0.5) * rowHeight
                    let rect = CGRect(x: x - cellWidth * 0.42, y: y - min(rowHeight - 6, 64) / 2,
                                      width: cellWidth * 0.84, height: max(8, min(rowHeight - 6, 64)))
                    var hitContext = playedContext
                    hitContext.opacity = feedback.strength(offset: hit.pass - feedback.pass, step: hit.step)
                    drawPlayedHit(hit, hand: hits.first(where: { $0.padIndex == hit.padIndex })?.hand ?? "L",
                                  in: rect, fontSize: Theme.Size.body, context: &hitContext)
                }
            }
            drawMarker(x: markerX, top: countY - 20, bottom: rowBottom, context: &context)
            let overview = CGRect(x: 0, y: size.height - 22, width: size.width, height: 16)
            context.stroke(Path(overview), with: .color(Theme.black), lineWidth: Theme.Size.border)
            for bar in 1..<max(1, lesson.bars) {
                let x = size.width * CGFloat(bar) / CGFloat(lesson.bars)
                context.fill(Path(CGRect(x: x, y: overview.minY, width: 2, height: overview.height)), with: .color(Theme.black))
            }
            drawMarker(x: size.width * CGFloat(position / Double(total)), top: overview.minY - 3,
                       bottom: overview.maxY + 3, context: &context)
        }
    }
}

private func drawPlayedHit(_ hit: PlayedHit, hand: String, in rect: CGRect, fontSize: CGFloat,
                           context: inout GraphicsContext) {
    let note = LessonHit(step: Int(hit.step), padIndex: hit.padIndex, hand: hand, velocity: 0)
    drawHit(note, in: rect, active: false, mark: hit.mark, fontSize: fontSize, context: &context)
}

private func hitMark(_ hit: LessonHit, judgments: [LessonHit: HitJudgment], scoring: Bool,
                     elapsedSteps: Double, grace: Double) -> HitMark? {
    guard scoring else { return nil }
    if let judgment = judgments[hit] { return judgment == .off ? .off : .correct }
    return elapsedSteps > grace ? .wrong : nil
}

private func drawHit(_ hit: LessonHit, in rect: CGRect, active: Bool, mark: HitMark?, strength: Double = 1,
                     fontSize: CGFloat, context: inout GraphicsContext) {
    if mark != nil, strength < 1 {
        drawHit(hit, in: rect, active: active, mark: nil, fontSize: fontSize, context: &context)
        if strength > 0 {
            var coloured = context
            coloured.opacity *= strength
            drawHit(hit, in: rect, active: active, mark: mark, fontSize: fontSize, context: &coloured)
        }
        return
    }
    let right = hit.hand == "R"
    let block = Path(roundedRect: rect, cornerRadius: Theme.Size.blockRadius)
    // A scored note keeps its hand as the frame colour while the fill shows the result.
    context.fill(block, with: .color(mark?.color ?? (right ? Theme.white : Theme.black)))
    if mark != nil {
        context.stroke(Path(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: Theme.Size.blockRadius),
                       with: .color(right ? Theme.white : Theme.black), lineWidth: 3)
    }
    if active {
        context.stroke(Path(roundedRect: rect.insetBy(dx: -3, dy: -3), cornerRadius: Theme.Size.blockRadius + 2),
                       with: .color(right ? Theme.black : Theme.white), lineWidth: Theme.Size.border)
    }
    context.draw(Text(PadVoice.abbreviation(hit.padIndex)).font(Theme.canvasDisplay(fontSize))
        .foregroundColor(mark != nil ? Theme.white : (right ? Theme.black : Theme.white)), at: CGPoint(x: rect.midX, y: rect.midY))
}

private func drawMarker(x: CGFloat, top: CGFloat, bottom: CGFloat, context: inout GraphicsContext) {
    var path = Path()
    path.move(to: CGPoint(x: x, y: top)); path.addLine(to: CGPoint(x: x, y: bottom))
    context.stroke(path, with: .color(Theme.white), lineWidth: 6)
    context.stroke(path, with: .color(Theme.black), lineWidth: 3)
}
