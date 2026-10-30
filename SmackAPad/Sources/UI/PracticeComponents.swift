import SwiftUI

/// Hand colours never change with the page appearance.
struct PatternBlock: View {
    let abbreviation: String
    let hand: String
    var outlined = false

    var body: some View {
        Text(abbreviation)
            .font(Theme.display(Theme.Size.body))
            .foregroundStyle(hand == "R" ? Theme.black : Theme.white)
            .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
            .background(hand == "R" ? Theme.white : Theme.black,
                        in: RoundedRectangle(cornerRadius: Theme.Size.blockRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Size.blockRadius)
                    .stroke(hand == "R" ? Theme.black : Theme.white,
                            lineWidth: outlined ? Theme.Size.border : 0)
                    .padding(-Theme.Space.tight)
            }
    }
}

/// Presentation vocabulary only. Thresholds belong to the separate bar-summary ticket.
enum BarVerdict: String {
    case clean, ahead, behind, uneven

    func label(czech: Bool) -> String {
        switch self {
        case .clean: return czech ? "čistý" : "clean"
        case .ahead: return czech ? "předbíháš" : "ahead"
        case .behind: return czech ? "zaostáváš" : "behind"
        case .uneven: return czech ? "nestejnoměrné" : "uneven"
        }
    }
}

struct BarHeader: View {
    let bar: Int
    let verdict: BarVerdict?
    let czech: Bool

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            Text("\(czech ? "TAKT" : "BAR") \(bar + 1)").font(Theme.display(Theme.Size.body))
            if let verdict { Text(verdict.label(czech: czech)).font(Theme.text()) }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.black)
        .accessibilityElement(children: .combine)
    }
}

struct InstrumentButtonStyle: ButtonStyle {
    var filled = false
    var selected = false
    var main = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.display(main ? Theme.Size.emphasis : Theme.Size.body))
            .foregroundStyle(filled || selected ? Theme.background : Theme.ink)
            .padding(.horizontal, Theme.Space.regular)
            .frame(minHeight: main ? Theme.Size.control : Theme.Size.touch)
            .background(filled || selected ? Theme.ink : Theme.background)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.Size.border))
            .opacity(configuration.isPressed ? 0.65 : 1)
            .contentShape(Rectangle())
    }
}

struct TransportControls: View {
    let running: Bool
    let enabled: Bool
    let start: () -> Void
    let stop: () -> Void
    let restart: () -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: Theme.Space.small) {
                if running {
                    Button(action: stop) {
                        HStack { Rectangle().frame(width: 16, height: 16); Text("STOP") }
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(InstrumentButtonStyle(filled: true, main: true))
                    .frame(width: (geometry.size.width - Theme.Space.small) * 0.6)
                    Button(action: restart) {
                        HStack(spacing: Theme.Space.small) {
                            PracticeGlyph(kind: .restart).frame(width: 20, height: 20)
                            Text("RESTART").font(Theme.display(Theme.Size.body))
                        }.frame(maxWidth: .infinity)
                    }
                    .buttonStyle(InstrumentButtonStyle(main: true))
                } else {
                    Button(action: start) { Text("START").frame(maxWidth: .infinity) }
                        .buttonStyle(InstrumentButtonStyle(filled: true, main: true))
                        .disabled(!enabled)
                        .opacity(enabled ? 1 : 0.5)
                }
            }
        }
        .frame(width: Theme.Size.transportWidth, height: Theme.Size.control)
    }
}

struct RunSummary: Identifiable {
    let id = UUID()
    let score: Double
    let bpm: Int
    let passes: Int
    let passed: Bool
    let mastery: Bool
    let memory: Bool
}

struct SummaryStrip: View {
    let summary: RunSummary
    let czech: Bool
    let detail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            HStack(spacing: Theme.Space.regular) {
                Text("\(Int((summary.score * 100).rounded())) %").font(Theme.display(Theme.Size.emphasis))
                HStack(spacing: Theme.Space.small) {
                    star(summary.passed, czech ? "Splněno" : "Passed")
                    star(summary.mastery, czech ? "Cílové tempo" : "Goal tempo")
                    star(summary.memory, czech ? "Z paměti" : "From memory")
                }
                Button(czech ? "Detail" : "Details", action: detail)
                    .font(Theme.text())
                    .frame(minHeight: Theme.Size.touch)
            }
            Text(czech ? "Poslední dokončený průchod" : "Last completed pass")
                .font(Theme.text(Theme.Size.small)).foregroundStyle(Theme.secondary)
        }
    }

    private func star(_ earned: Bool, _ label: String) -> some View {
        StarShape()
            .fill(earned ? Theme.ink : Theme.background)
            .overlay(StarShape().stroke(Theme.ink, lineWidth: Theme.Size.border))
            .frame(width: 23, height: 23)
            .accessibilityLabel(label)
            .accessibilityValue(earned ? (czech ? "získáno" : "earned") : (czech ? "nezískáno" : "not earned"))
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            for point in 0..<10 {
                let angle = Double(point) * .pi / 5 - .pi / 2
                let radius = min(rect.width, rect.height) * (point.isMultiple(of: 2) ? 0.48 : 0.22)
                let position = CGPoint(x: rect.midX + cos(angle) * radius, y: rect.midY + sin(angle) * radius)
                if point == 0 { path.move(to: position) } else { path.addLine(to: position) }
            }
            path.closeSubpath()
        }
    }
}

/// A small, deliberately drawn icon set instead of default system symbols.
struct PracticeGlyph: View {
    enum Kind { case back, grid, scrolling, eye, legend, tools, restart }
    let kind: Kind

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 24
            context.scaleBy(x: scale, y: scale)
            var path = Path()
            switch kind {
            case .back:
                path.move(to: CGPoint(x: 15, y: 4)); path.addLines([CGPoint(x: 7, y: 12), CGPoint(x: 15, y: 20)])
            case .grid:
                for x in [3, 14] { for y in [3, 14] { path.addRect(CGRect(x: x, y: y, width: 7, height: 7)) } }
            case .scrolling:
                for y in [6, 12, 18] {
                    path.move(to: CGPoint(x: 3, y: y)); path.addLine(to: CGPoint(x: 19, y: y))
                }
                path.move(to: CGPoint(x: 16, y: 3)); path.addLines([CGPoint(x: 21, y: 6), CGPoint(x: 16, y: 9)])
            case .eye:
                path.move(to: CGPoint(x: 2, y: 12))
                path.addQuadCurve(to: CGPoint(x: 22, y: 12), control: CGPoint(x: 12, y: -2))
                path.addQuadCurve(to: CGPoint(x: 2, y: 12), control: CGPoint(x: 12, y: 26))
                path.addEllipse(in: CGRect(x: 9, y: 9, width: 6, height: 6))
            case .legend:
                path.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
                context.draw(Text("?").font(Theme.canvasDisplay(16)).foregroundColor(Theme.ink), at: CGPoint(x: 12, y: 12))
            case .tools:
                for x in [4, 12, 20] {
                    context.fill(Path(ellipseIn: CGRect(x: CGFloat(x) - 1.5, y: 10.5, width: 3, height: 3)), with: .foreground)
                }
            case .restart:
                path.addArc(center: CGPoint(x: 12, y: 12), radius: 8, startAngle: .degrees(220), endAngle: .degrees(500), clockwise: false)
                path.move(to: CGPoint(x: 3, y: 3)); path.addLines([CGPoint(x: 3, y: 10), CGPoint(x: 10, y: 10)])
            }
            context.stroke(path, with: .foreground, style: StrokeStyle(lineWidth: 2, lineCap: .square, lineJoin: .miter))
        }
        .accessibilityHidden(true)
    }
}

struct PadVoice {
    static let abbreviations = ["TH", "TL", "CR", "RD", "SH", "WD", "CB", "OH", "HH", "CP", "RM", "HH", "KD", "SN", "SN", "KD"]
    static let names = ["High tom", "Low tom", "Crash", "Ride", "Shaker", "Wood", "Cowbell", "Open hi-hat", "Hi-hat", "Clap", "Rim", "Hi-hat", "Kick", "Snare", "Snare", "Kick"]
    static let rowOrder = [8, 11, 7, 2, 3, 4, 5, 6, 9, 10, 13, 14, 0, 1, 12, 15]
    static func abbreviation(_ pad: Int) -> String { abbreviations.indices.contains(pad) ? abbreviations[pad] : "?" }
    static func name(_ pad: Int) -> String { names.indices.contains(pad) ? names[pad] : "Pad \(pad + 1)" }
}

/// A small layout diagram, not a second performance surface. Full-size touch
/// pads remain available in the MIDI tools.
struct PadLayoutGrid: View {
    let pads: [Int]
    let used: Set<Int>

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.tight), count: 4), spacing: Theme.Space.tight) {
            ForEach(Array(pads.enumerated()), id: \.offset) { _, pad in
                Text(PadVoice.abbreviation(pad))
                    .font(Theme.text(Theme.Size.dense))
                    .frame(maxWidth: .infinity, minHeight: 24)
                    .foregroundStyle(used.contains(pad) ? Theme.ink : Theme.secondary)
                    .background(Theme.surface)
                    .overlay(Rectangle().stroke(Theme.ink, lineWidth: used.contains(pad) ? Theme.Size.border : 0))
                    .accessibilityLabel("\(PadVoice.name(pad)), pad \(pad + 1)")
            }
        }
        .frame(width: 176)
    }
}
