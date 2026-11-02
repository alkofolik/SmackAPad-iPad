import SwiftUI

/// How one pad strike or expected note turned out. Shown as colour only.
enum HitMark {
    case correct, off, wrong

    var color: Color {
        switch self {
        case .correct: return Theme.markCorrect
        case .off: return Theme.markOff
        case .wrong: return Theme.markWrong
        }
    }
}

/// A short colour flash on the pad layout; `mark` is nil when nothing is scored.
struct PadFlash: Equatable {
    let mark: HitMark?
    let date: Date

    var color: Color { mark?.color ?? Theme.orange }
    func strength(at now: Date) -> Double { max(0, 1 - now.timeIntervalSince(date) / 0.4) }
}

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

    func label(settings: SettingsManager? = nil) -> String {
        let mgr = settings ?? SettingsManager.shared
        return mgr.localized(rawValue)
    }

    func label(language: AppLanguage) -> String {
        language.localized(rawValue)
    }
}

struct BarHeader: View {
    @Environment(SettingsManager.self) private var settings
    let bar: Int
    let verdict: BarVerdict?

    var body: some View {
        HStack(spacing: Theme.Space.regular) {
            Text(settings.localized("BAR %lld", bar + 1)).font(Theme.display(Theme.Size.body))
            if let verdict { Text(verdict.label(settings: settings)).font(Theme.text()) }
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
            .font(main ? Theme.display(Theme.Size.emphasis) : Theme.control)
            .foregroundStyle(filled || selected ? Theme.background : Theme.ink)
            .padding(.horizontal, Theme.Space.regular)
            .frame(minHeight: main ? Theme.Size.control : Theme.Size.touch)
            .background(filled || selected ? Theme.ink : Theme.background)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.Size.border))
            .opacity(configuration.isPressed ? 0.65 : 1)
            .contentShape(Rectangle())
            .motion(value: selected)
            .motion(value: configuration.isPressed)
    }
}

/// A tap performs the action; holding the icon reveals its localized name.
struct PracticeIconButton: View {
    let symbol: String
    let title: String
    var selected = false
    let action: () -> Void
    @State private var showingHint = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 21, weight: .medium))
                .frame(width: Theme.Size.touch, height: Theme.Size.touch)
                .foregroundStyle(selected ? Theme.background : Theme.ink)
                .background(selected ? Theme.ink : Theme.background)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .help(title)
        .highPriorityGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in showingHint = true })
        .popover(isPresented: $showingHint, arrowEdge: .top) {
            Text(title)
                .font(Theme.control)
                .padding(Theme.Space.regular)
                .foregroundStyle(Theme.ink)
                .background(Theme.background)
                .presentationCompactAdaptation(.popover)
        }
    }
}

struct TransportControls: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduced
    let running: Bool
    let enabled: Bool
    let start: () -> Void
    let stop: () -> Void
    let restart: () -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: Theme.Space.small) {
                Button(action: running ? stop : start) {
                    HStack {
                        if running { Rectangle().frame(width: 16, height: 16).transition(.opacity) }
                        Text(settings.localized(running ? "Stop" : "Start"))
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .id(running).transition(.opacity)
                    }.frame(maxWidth: .infinity)
                }
                .buttonStyle(InstrumentButtonStyle(filled: true, main: true))
                .frame(width: running ? (geometry.size.width - Theme.Space.small) * 0.6 : geometry.size.width)
                .disabled(!running && !enabled)
                .opacity(running || enabled ? 1 : 0.5)
                if running {
                    Button(action: restart) {
                        HStack(spacing: Theme.Space.small) {
                            PracticeGlyph(kind: .restart).frame(width: 20, height: 20)
                            Text(settings.localized("Restart"))
                                .font(Theme.display(18))
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }.frame(maxWidth: .infinity)
                    }
                    .buttonStyle(InstrumentButtonStyle(main: true))
                    .transition(.opacity)
                }
            }
        }
        .frame(width: Theme.Size.transportWidth, height: Theme.Size.control)
        .motion(Theme.Motion.standard, value: running)
        .transaction { if Theme.Motion.Policy(reduced: reduced).opacityOnly { $0.animation = nil } }
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
    var finishedByStar: Int? = nil
}

struct SummaryStrip: View {
    @State private var revealed: Set<Int> = []
    @Environment(SettingsManager.self) private var settings
    let summary: RunSummary
    var nextStarText: String? = nil
    var dismiss: (() -> Void)? = nil
    let detail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            if let star = summary.finishedByStar {
                HStack(spacing: Theme.Space.small) {
                    Text(settings.localized(star == 3
                        ? "Run finished: star 3 earned, from memory"
                        : "Run finished: star 2 earned, goal tempo"))
                        .font(Theme.meta)
                        .fixedSize(horizontal: false, vertical: true)
                    if let dismiss {
                        Button(settings.localized("Close"), action: dismiss)
                            .font(Theme.meta)
                            .frame(minWidth: Theme.Size.touch, minHeight: Theme.Size.touch)
                    }
                }
            }
            HStack(spacing: Theme.Space.regular) {
                Text("\(Int((summary.score * 100).rounded())) %").font(Theme.control)
                HStack(spacing: Theme.Space.small) {
                    star(summary.passed && revealed.contains(0), settings.localized("Passed"))
                    star(summary.mastery && revealed.contains(1), settings.localized("Goal tempo"))
                    star(summary.memory && revealed.contains(2), settings.localized("From memory"))
                }
                Button(settings.localized("Details"), action: detail)
                    .font(Theme.control)
                    .frame(minHeight: Theme.Size.touch)
            }
            if let nextStarText {
                Text(nextStarText)
                    .font(Theme.meta)
                    .foregroundStyle(Theme.ink)
            }
            Text(settings.localized("Last completed pass"))
                .font(Theme.meta).foregroundStyle(Theme.secondary)
        }
        .task(id: summary.id) {
            revealed = []
            for index in 0..<3 {
                do { try await Task.sleep(for: Theme.Motion.starStagger) } catch { return }
                revealed.insert(index)
            }
        }
    }

    private func star(_ earned: Bool, _ label: String) -> some View {
        StarShape()
            .fill(earned ? Theme.ink : Theme.background)
            .overlay(StarShape().stroke(Theme.ink, lineWidth: Theme.Size.border))
            .frame(width: 23, height: 23)
            .accessibilityLabel(label)
            .accessibilityValue(settings.localized(earned ? "earned" : "not earned"))
            .motion(value: earned)
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
    enum Kind { case back, grid, scrolling, eye, legend, tools, restart, lock, info }
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
            case .info:
                path.addEllipse(in: CGRect(x: 3, y: 3, width: 18, height: 18))
                context.draw(Text("i").font(Theme.canvasDisplay(16)).foregroundColor(Theme.ink), at: CGPoint(x: 12, y: 12))
            case .tools:
                for x in [4, 12, 20] {
                    context.fill(Path(ellipseIn: CGRect(x: CGFloat(x) - 1.5, y: 10.5, width: 3, height: 3)), with: .foreground)
                }
            case .restart:
                path.addArc(center: CGPoint(x: 12, y: 12), radius: 8, startAngle: .degrees(220), endAngle: .degrees(500), clockwise: false)
                path.move(to: CGPoint(x: 3, y: 3)); path.addLines([CGPoint(x: 3, y: 10), CGPoint(x: 10, y: 10)])
            case .lock:
                path.addRect(CGRect(x: 5, y: 10, width: 14, height: 11))
                path.move(to: CGPoint(x: 8, y: 10))
                path.addLine(to: CGPoint(x: 8, y: 6))
                path.addArc(center: CGPoint(x: 12, y: 6), radius: 4, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                path.addLine(to: CGPoint(x: 16, y: 10))
                path.move(to: CGPoint(x: 12, y: 13))
                path.addLine(to: CGPoint(x: 12, y: 17))
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
    static func name(_ pad: Int, settings: SettingsManager? = nil) -> String {
        guard names.indices.contains(pad) else { return "Pad \(pad + 1)" }
        let raw = names[pad]
        return settings?.localized(raw) ?? raw
    }
}

/// A small layout diagram, not a second performance surface. Full-size touch
/// pads remain available in the MIDI tools.
struct PadLayoutGrid: View {
    let pads: [Int]
    let used: Set<Int>
    var flashes: [Int: PadFlash] = [:]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: flashes.isEmpty)) { timeline in
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.tight), count: 4), spacing: Theme.Space.tight) {
                ForEach(Array(pads.enumerated()), id: \.offset) { _, pad in
                    cell(pad, now: timeline.date)
                }
            }
        }
        .frame(width: 176)
    }

    private func cell(_ pad: Int, now: Date) -> some View {
        let flash = flashes[pad]
        let strength = flash?.strength(at: now) ?? 0
        let isUsed = used.contains(pad)
        let tint = (flash?.color ?? Theme.orange).opacity(strength)
        return Text(PadVoice.abbreviation(pad))
            .font(Theme.text(Theme.Size.dense))
            .frame(maxWidth: .infinity, minHeight: 24)
            .foregroundStyle(strength > 0.35 ? Theme.white : (isUsed ? Theme.ink : Theme.secondary))
            .background {
                ZStack {
                    Theme.surface
                    tint
                }
            }
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: isUsed ? Theme.Size.border : 0))
            .accessibilityLabel("\(PadVoice.name(pad)), pad \(pad + 1)")
    }
}

/// A volume slider row (0–100% in steps of 5) following the app's three-colour theme.
struct VolumeSliderRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.tight) {
            HStack {
                Text(title)
                    .font(Theme.control)
                Spacer()
                Text("\(value) %")
                    .font(Theme.text(Theme.Size.dense))
                    .foregroundStyle(Theme.secondary)
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = SettingsManager.clampVolume(Int($0.rounded())) }
                ),
                in: 0...100,
                step: 5
            )
            .tint(Theme.orange)
        }
        .padding(.vertical, Theme.Space.tight)
    }
}
