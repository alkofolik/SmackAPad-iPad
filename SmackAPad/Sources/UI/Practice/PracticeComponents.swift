import SwiftUI
import UIKit

enum LessonPlaybackMode: String, CaseIterable {
    case listen = "Listen"
    case play = "Play"
    case afterMe = "After me"
}

/// How one pad strike or expected note turned out. Shape-coded on the pattern band.
enum HitMark: Equatable, Sendable {
    case correct, early, late, wrong

    static func from(_ feedback: HitFeedback) -> HitMark? {
        switch feedback.judgment {
        case .perfect, .good:
            return .correct
        case .off:
            if let error = feedback.timingErrorMilliseconds, error < 0 {
                return .early
            }
            return .late
        case .wrongPad:
            return .wrong
        case .ignored:
            return nil
        }
    }
}

/// A short colour flash on the pad layout; `mark` is nil when nothing is scored.
struct PadFlash: Equatable {
    static let fadeDuration: TimeInterval = 0.4

    let mark: HitMark?
    let date: Date

    var color: Color {
        switch mark {
        case .correct: Color(red: 0.04, green: 0.34, blue: 0.15)
        case .early, .late: Color(red: 0.36, green: 0.26, blue: 0)
        case .wrong: Color(red: 0.62, green: 0.06, blue: 0.10)
        case nil: Theme.orange
        }
    }
    func strength(at now: Date) -> Double { max(0, 1 - now.timeIntervalSince(date) / Self.fadeDuration) }
    func isFading(at now: Date = Date()) -> Bool { now.timeIntervalSince(date) < Self.fadeDuration }
}

/// Schedules animation frames only while at least one pad flash is fading.
/// When no flash is fading, updates cease so the 30 Hz timeline pauses.
struct PadFlashSchedule: TimelineSchedule {
    let flashes: [Int: PadFlash]
    private static let frameInterval: TimeInterval = 1.0 / 30.0

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> [Date] {
        guard let latest = flashes.values.map(\.date).max() else {
            return [startDate]
        }
        let finish = latest.addingTimeInterval(PadFlash.fadeDuration)
        guard finish > startDate else {
            return [startDate]
        }
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

/// Hand colours: cream white = right, filled black with 1 pt light outline = left.
struct PatternBlock: View {
    let abbreviation: String
    let hand: String
    var outlined = false
    var size: CGFloat = 44

    var body: some View {
        let isRight = hand.uppercased() == "R"
        Text(abbreviation)
            .font(Theme.canvasDisplay(max(14, size * 0.44)))
            .foregroundStyle(isRight ? Theme.black : Theme.white)
            .frame(width: size, height: size)
            .background(isRight ? Theme.white : Theme.black,
                        in: RoundedRectangle(cornerRadius: 6))
            .overlay {
                if !isRight {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Theme.white, lineWidth: 1)
                } else if outlined {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(Theme.black, lineWidth: 1.5)
                }
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

struct InstrumentButtonStyle: ButtonStyle {
    var filled = false
    var selected = false
    var main = false
    var customHeight: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(main || selected ? Theme.action : Theme.control)
            .foregroundStyle(filled || selected ? Theme.background : Theme.ink)
            .padding(.horizontal, Theme.Space.regular)
            .frame(height: customHeight)
            .frame(minHeight: customHeight == nil ? (main ? Theme.Size.control : Theme.Size.touch) : nil)
            .background(filled || selected ? Theme.ink : Theme.background)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: Theme.Size.border))
            .opacity(configuration.isPressed ? 0.65 : 1)
            .frame(minWidth: Theme.Size.minimumTouch)
            .contentShape(Rectangle())
            .motion(value: selected)
            .motion(value: configuration.isPressed)
    }
}

enum PracticeToolbarButtonAppearance {
    case segmented
    case outline
    case solidDark
}

/// A 24×24 stroke vector icon matching the UI shape from Main.dc.html.
enum PracticeToolbarIcon: Equatable {
    case symbol(String)
    case crossedSticks
    case padLegend
}

private struct PracticeToolbarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let appearance: PracticeToolbarButtonAppearance
    var selected: Bool = false
    var size: CGSize = CGSize(width: 48, height: 48)

    private var cornerRadius: CGFloat {
        appearance == .solidDark ? 14 : 12
    }

    private var backgroundColor: Color {
        switch appearance {
        case .segmented, .outline:
            return selected ? Theme.orange : .clear
        case .solidDark:
            return Theme.black
        }
    }

    private var foregroundColor: Color {
        switch appearance {
        case .segmented, .outline:
            return selected ? Theme.black : Theme.ink
        case .solidDark:
            return Theme.white
        }
    }

    private var borderColor: Color {
        switch appearance {
        case .segmented:
            return .clear
        case .outline:
            return selected ? .clear : Theme.ink.opacity(0.28)
        case .solidDark:
            return Theme.ink.opacity(0.18)
        }
    }

    private var borderWidth: CGFloat {
        switch appearance {
        case .segmented: return 0
        case .outline: return 1.5
        case .solidDark: return 1
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size.width, height: size.height)
            .foregroundStyle(foregroundColor)
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(backgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.4)
    }
}

@Observable
final class PracticeToolbarHintCoordinator {
    static let coordinateSpaceName = "PracticeToolbarHintSpace"

    struct Hint: Equatable {
        let title: String
        let anchor: CGRect
    }

    var currentHint: Hint?
    private var dismissTask: Task<Void, Never>?

    func show(title: String, anchor: CGRect) {
        dismissTask?.cancel()
        currentHint = Hint(title: title, anchor: anchor)
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.currentHint = nil
        }
    }

    func hide(for title: String? = nil) {
        if let title {
            guard currentHint?.title == title else { return }
        }
        dismissTask?.cancel()
        dismissTask = nil
        currentHint = nil
    }
}

private struct PracticeToolbarHintCoordinatorKey: EnvironmentKey {
    static let defaultValue: PracticeToolbarHintCoordinator? = nil
}

extension EnvironmentValues {
    var practiceToolbarHintCoordinator: PracticeToolbarHintCoordinator? {
        get { self[PracticeToolbarHintCoordinatorKey.self] }
        set { self[PracticeToolbarHintCoordinatorKey.self] = newValue }
    }
}

struct PracticeToolbarHintRowLayout: Layout {
    let anchor: CGRect

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let pill = subviews.first else { return }
        let pillSize = pill.sizeThatFits(.unspecified)
        let pillWidth = pillSize.width

        let desiredX = anchor.midX - pillWidth / 2
        let minX = bounds.minX
        let maxX = max(bounds.minX, bounds.maxX - pillWidth)
        let clampedX = min(max(desiredX, minX), maxX)

        let y = bounds.minY + anchor.maxY + 6
        pill.place(at: CGPoint(x: clampedX, y: y), proposal: ProposedViewSize(pillSize))
    }
}

struct PracticeToolbarHintContainerModifier: ViewModifier {
    @State private var coordinator = PracticeToolbarHintCoordinator()
    @Environment(\.accessibilityReduceMotion) private var reduced

    func body(content: Content) -> some View {
        content
            .coordinateSpace(.named(PracticeToolbarHintCoordinator.coordinateSpaceName))
            .environment(\.practiceToolbarHintCoordinator, coordinator)
            .overlay(alignment: .topLeading) {
                if let hint = coordinator.currentHint {
                    PracticeToolbarHintRowLayout(anchor: hint.anchor) {
                        hintPill(for: hint.title)
                    }
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .zIndex(100)
                }
            }
            .animation(reduced ? nil : Theme.Motion.fast, value: coordinator.currentHint)
            .onDisappear { coordinator.hide() }
    }

    private func hintPill(for title: String) -> some View {
        Text(title)
            .font(Theme.strong(15))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Theme.white)
            .padding(.horizontal, Theme.Space.controlGap)
            .padding(.vertical, Theme.Space.small)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(Theme.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.pad)
                            .strokeBorder(Theme.orange, lineWidth: 1.5)
                    )
            )
            .allowsHitTesting(false)
    }
}

private struct PracticeToolbarHintModifier: ViewModifier {
    let title: String
    @Environment(\.practiceToolbarHintCoordinator) private var coordinator
    @State private var buttonFrame: CGRect = .zero
    @State private var showingFallbackHint = false
    @State private var fallbackDismissTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduced

    private var hintGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.45, maximumDistance: 15)
            .onEnded { _ in
                showHint()
            }
    }

    private func showHint() {
        if let coordinator {
            coordinator.show(title: title, anchor: buttonFrame)
        } else {
            showingFallbackHint = true
            fallbackDismissTask?.cancel()
            fallbackDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                showingFallbackHint = false
            }
        }
    }

    private func hideHint() {
        if let coordinator {
            coordinator.hide(for: title)
        } else {
            fallbackDismissTask?.cancel()
            fallbackDismissTask = nil
            showingFallbackHint = false
        }
    }

    private var fallbackHintPill: some View {
        Text(title)
            .font(Theme.strong(15))
            .lineLimit(1)
            .fixedSize()
            .foregroundStyle(Theme.white)
            .padding(.horizontal, Theme.Space.controlGap)
            .padding(.vertical, Theme.Space.small)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(Theme.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.pad)
                            .strokeBorder(Theme.orange, lineWidth: 1.5)
                    )
            )
            .allowsHitTesting(false)
    }

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .help(title)
            .highPriorityGesture(hintGesture)
            .background(
                GeometryReader { geo in
                    let frame = geo.frame(in: .named(PracticeToolbarHintCoordinator.coordinateSpaceName))
                    Color.clear
                        .onChange(of: frame, initial: true) { _, newFrame in
                            buttonFrame = newFrame
                        }
                }
            )
            .overlay(alignment: .bottom) {
                if coordinator == nil && showingFallbackHint {
                    fallbackHintPill
                        .alignmentGuide(.bottom) { d in d[.top] - 6 }
                        .transition(.opacity)
                }
            }
            .zIndex(coordinator == nil && showingFallbackHint ? 100 : 0)
            .animation(reduced ? nil : Theme.Motion.fast, value: showingFallbackHint)
            .onDisappear { hideHint() }
    }
}

extension View {
    func practiceToolbarHint(_ title: String) -> some View {
        modifier(PracticeToolbarHintModifier(title: title))
    }

    func practiceToolbarHintContainer() -> some View {
        modifier(PracticeToolbarHintContainerModifier())
    }
}

struct PracticeToolbarGlyph: View {
    let icon: PracticeToolbarIcon
    var size: CGFloat = 22

    var body: some View {
        switch icon {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .medium))
                .accessibilityHidden(true)
        case .crossedSticks:
            CrossedSticksGlyph()
                .frame(width: size, height: size)
        case .padLegend:
            PadLegendGlyph()
                .frame(width: size, height: size)
        }
    }
}

private struct CrossedSticksGlyph: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 24
            let style = StrokeStyle(lineWidth: 1.85 * s, lineCap: .round, lineJoin: .round)

            var leftStick = Path()
            leftStick.move(to: CGPoint(x: 4 * s, y: 20 * s))
            leftStick.addLine(to: CGPoint(x: 15 * s, y: 6 * s))

            var rightStick = Path()
            rightStick.move(to: CGPoint(x: 20 * s, y: 20 * s))
            rightStick.addLine(to: CGPoint(x: 9 * s, y: 6 * s))

            let tipRadius = 1.8 * s
            let leftTip = Path(ellipseIn: CGRect(
                x: 8 * s - tipRadius, y: 5 * s - tipRadius,
                width: tipRadius * 2, height: tipRadius * 2
            ))
            let rightTip = Path(ellipseIn: CGRect(
                x: 16 * s - tipRadius, y: 5 * s - tipRadius,
                width: tipRadius * 2, height: tipRadius * 2
            ))

            context.stroke(leftStick, with: .foreground, style: style)
            context.stroke(rightStick, with: .foreground, style: style)
            context.stroke(leftTip, with: .foreground, style: style)
            context.stroke(rightTip, with: .foreground, style: style)
        }
        .accessibilityHidden(true)
    }
}

private struct PadLegendGlyph: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height) / 24
            let style = StrokeStyle(lineWidth: 1.8 * s, lineCap: .round, lineJoin: .round)

            let boxes = [
                CGRect(x: 4 * s, y: 4 * s, width: 7 * s, height: 7 * s),
                CGRect(x: 13 * s, y: 4 * s, width: 7 * s, height: 7 * s),
                CGRect(x: 4 * s, y: 13 * s, width: 7 * s, height: 7 * s)
            ]
            for rect in boxes {
                context.stroke(Path(roundedRect: rect, cornerRadius: 1.5 * s), with: .foreground, style: style)
            }

            var lines = Path()
            lines.move(to: CGPoint(x: 14 * s, y: 15 * s))
            lines.addLine(to: CGPoint(x: 20 * s, y: 15 * s))
            lines.move(to: CGPoint(x: 14 * s, y: 19 * s))
            lines.addLine(to: CGPoint(x: 18 * s, y: 19 * s))
            context.stroke(lines, with: .foreground, style: style)
        }
        .accessibilityHidden(true)
    }
}

/// A tap performs the action; holding the icon reveals its localized name.
struct PracticeIconButton: View {
    @Environment(\.isEnabled) private var isEnabled
    let icon: PracticeToolbarIcon
    let title: String
    var appearance: PracticeToolbarButtonAppearance = .segmented
    var width: CGFloat? = nil
    var count: Int? = nil
    var selected = false
    var disabled = false
    var accessibilityValue: String? = nil
    var accessibilityHint: String? = nil
    let action: () -> Void

    init(
        symbol: String,
        title: String,
        appearance: PracticeToolbarButtonAppearance = .segmented,
        width: CGFloat? = nil,
        count: Int? = nil,
        selected: Bool = false,
        disabled: Bool = false,
        accessibilityValue: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = .symbol(symbol)
        self.title = title
        self.appearance = appearance
        self.width = width
        self.count = count
        self.selected = selected
        self.disabled = disabled
        self.accessibilityValue = accessibilityValue
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    init(
        icon: PracticeToolbarIcon,
        title: String,
        appearance: PracticeToolbarButtonAppearance = .segmented,
        width: CGFloat? = nil,
        count: Int? = nil,
        selected: Bool = false,
        disabled: Bool = false,
        accessibilityValue: String? = nil,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.appearance = appearance
        self.width = width
        self.count = count
        self.selected = selected
        self.disabled = disabled
        self.accessibilityValue = accessibilityValue
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    private var buttonSize: CGSize {
        let base: CGFloat = appearance == .solidDark ? 56 : 48
        return CGSize(width: width ?? base, height: base)
    }

    var body: some View {
        let effectiveEnabled = isEnabled && !disabled
        Button(action: action) {
            buttonContent
        }
        .buttonStyle(PracticeToolbarButtonStyle(
            appearance: appearance,
            selected: selected,
            size: buttonSize
        ))
        .motion(value: effectiveEnabled)
        .motion(value: selected)
        .accessibilityLabel(title)
        .modifier(OptionalAccessibilityModifier(value: accessibilityValue, hint: accessibilityHint))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .disabled(disabled)
        .practiceToolbarHint(title)
    }

    @ViewBuilder
    private var buttonContent: some View {
        if let count {
            HStack(spacing: 4) {
                PracticeToolbarGlyph(icon: icon, size: 16)
                Text("\(count)")
                    .font(Theme.strong(15))
                    .monospacedDigit()
            }
        } else {
            let glyphSize: CGFloat = icon == .symbol(iconName) ? 20 : 22
            PracticeToolbarGlyph(icon: icon, size: glyphSize)
        }
    }

    private var iconName: String {
        if case .symbol(let name) = icon { return name }
        return ""
    }
}

private struct OptionalAccessibilityModifier: ViewModifier {
    let value: String?
    let hint: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let value, let hint {
            content
                .accessibilityValue(value)
                .accessibilityHint(hint)
        } else if let value {
            content
                .accessibilityValue(value)
        } else if let hint {
            content
                .accessibilityHint(hint)
        } else {
            content
        }
    }
}

struct TransportControls: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduced
    let running: Bool
    let enabled: Bool
    var showsResult: Bool = false
    var nextEnabled: Bool = false
    var nextLocked: Bool = false
    var nextHint: String? = nil
    var nextAction: (() -> Void)? = nil
    var squareSize: CGFloat
    var resultSize: CGSize? = nil
    var horizontalResultButtons: Bool = false
    let start: () -> Void
    let stop: () -> Void
    let restart: () -> Void
    var skipAction: (() -> Void)? = nil

    var body: some View {
        if showsResult {
            resultBody
        } else {
            runningOrIdleBody
        }
    }

    @ViewBuilder
    private var resultBody: some View {
        let showNext = nextEnabled && nextAction != nil
        let layout = horizontalResultButtons
            ? AnyLayout(HStackLayout(spacing: Theme.Space.controlGap))
            : AnyLayout(VStackLayout(spacing: Theme.Space.controlGap))
        let buttonHeight: CGFloat? = horizontalResultButtons
            ? 64
            : showNext
                ? resultSize.map { max(0, ($0.height - Theme.Space.controlGap) / 2) }
                : resultSize?.height

        layout {
            if showNext {
                Button {
                    nextAction?()
                } label: {
                    HStack(spacing: Theme.Space.small) {
                        if nextLocked {
                            Image(systemName: "lock")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(settings.localized("Next"))
                            .font(Theme.action)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        if !nextLocked {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadPrimaryButtonStyle())
                .frame(height: buttonHeight)
                .accessibilityHint(nextHint ?? "")
            }

            Button(action: restart) {
                Text(settings.localized("Restart"))
                    .font(Theme.action)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(PadSecondaryButtonStyle())
            .frame(height: buttonHeight)
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)
        }
        .frame(width: horizontalResultButtons ? nil : resultSize?.width,
               height: horizontalResultButtons ? nil : resultSize?.height)
    }

    private var runningOrIdleBody: some View {
        let buttonHeight = max(0, (squareSize - Theme.Space.controlGap) / 2)
        return VStack(spacing: Theme.Space.controlGap) {
            Button(action: running ? stop : start) {
                HStack(spacing: Theme.Space.small) {
                    if running {
                        Rectangle().frame(width: 14, height: 14).transition(.opacity)
                    }
                    Text(settings.localized(running ? "Stop" : "Start"))
                        .font(Theme.action)
                        .lineLimit(1)
                        .fixedSize()
                        .id(running ? "Stop" : "Start")
                        .transition(.opacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(PadPrimaryButtonStyle())
            .frame(width: squareSize, height: buttonHeight)
            .disabled(!running && !enabled)
            .opacity(running || enabled ? 1 : 0.5)

            if !running, let skipAction {
                Button(action: skipAction) {
                    Text(settings.localized("Skip"))
                        .font(Theme.action)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadSecondaryButtonStyle())
                .frame(width: squareSize, height: buttonHeight)
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.5)
            } else {
                Button(action: restart) {
                    HStack(spacing: Theme.Space.small) {
                        PracticeGlyph(kind: .restart).frame(width: 18, height: 18)
                        Text(settings.localized("Restart"))
                            .font(Theme.action)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(PadSecondaryButtonStyle())
                .frame(width: squareSize, height: buttonHeight)
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.5)
            }
        }
        .frame(width: squareSize, height: squareSize)
        .motion(Theme.Motion.standard, value: running)
        .transaction { if Theme.Motion.Policy(reduced: reduced).opacityOnly { $0.animation = nil } }
    }
}

/// The most recent 32 matched strikes, chronological from left to right.
struct HitTimingPlot: View {
    @Environment(SettingsManager.self) private var settings
    let history: TimingHistory

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.small) {
            Text(settings.localized("Last 32 hits")).font(Theme.control)
            if history.samples.isEmpty {
                Text(settings.localized("No matched hits to show.")).font(Theme.meta)
            } else {
                HStack(spacing: Theme.Space.small) {
                    VStack {
                        Text(settings.localized("Early"))
                        Spacer()
                        Text(settings.localized("On time"))
                        Spacer()
                        Text(settings.localized("Late"))
                    }
                    .font(Theme.meta).foregroundStyle(Theme.secondary)
                    Canvas { context, size in
                        let inset = 4.0
                        let height = max(1, size.height - inset * 2)
                        let width = max(1, size.width - inset * 2)
                        let good = history.samples.last.map { $0.goodMilliseconds / $0.maximumMilliseconds } ?? 0
                        context.fill(Path(CGRect(x: 0, y: inset + height * (1 - good) / 2,
                                                 width: size.width, height: height * good)),
                                     with: .color(Theme.orange.opacity(0.12)))
                        context.fill(Path(CGRect(x: 0, y: size.height / 2, width: size.width, height: 1)),
                                     with: .color(Theme.hairline))
                        for (index, sample) in history.samples.enumerated() {
                            let x = inset + width * Double(index) / 31
                            let y = inset + height * (sample.normalized + 1) / 2
                            context.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                                         with: .color(sample.isGood ? Theme.orange : Theme.secondary))
                        }
                    }
                }
                .frame(height: 140)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(settings.localized("Last 32 hits"))
                .accessibilityValue(history.samples.map { sample in
                    sample.errorMilliseconds < 0
                        ? settings.localized("Early %lld ms", Int(abs(sample.errorMilliseconds).rounded()))
                        : settings.localized("Late %lld ms", Int(sample.errorMilliseconds.rounded()))
                }.joined(separator: ", "))
                Text(settings.localized("Orange: within the good window. Grey: outside it."))
                    .font(Theme.meta).foregroundStyle(Theme.secondary)
            }
        }
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
    var runs: [PracticeRunResult] = []
    var firstStar2: Bool = false
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

// MARK: - Drum Glyphs (Ticket 229)

/// Drum category glyph kinds for the band margin and pad legend (Ticket 229).
enum DrumKind: String, CaseIterable, Equatable {
    case kick
    case snare
    case hiHat
    case openHiHat
    case clap
    case tom
    case crashRide
    case genericDrum

    static func forPad(_ pad: Int) -> DrumKind {
        switch pad {
        case 12, 15:
            return .kick
        case 13, 14:
            return .snare
        case 8, 11:
            return .hiHat
        case 7:
            return .openHiHat
        case 9:
            return .clap
        case 0, 1:
            return .tom
        case 2, 3:
            return .crashRide
        default:
            let name = PadVoice.displayName(pad).lowercased()
            if name.contains("kick") { return .kick }
            if name.contains("snare") { return .snare }
            if name.contains("open") && name.contains("hat") { return .openHiHat }
            if name.contains("hat") { return .hiHat }
            if name.contains("clap") { return .clap }
            if name.contains("tom") { return .tom }
            if name.contains("crash") || name.contains("ride") || name.contains("cymbal") { return .crashRide }
            return .genericDrum
        }
    }
}

/// A crisp, vector drum icon drawn to row height with a unified stroke aesthetic (Ticket 229).
struct DrumGlyph: View {
    let kind: DrumKind
    var color: Color = Theme.ink

    init(kind: DrumKind, color: Color = Theme.ink) {
        self.kind = kind
        self.color = color
    }

    var body: some View {
        Canvas { context, size in
            Self.draw(kind: kind, in: CGRect(origin: .zero, size: size), context: &context, color: color)
        }
        .accessibilityHidden(true)
    }

    static func draw(kind: DrumKind, in rect: CGRect, context: inout GraphicsContext, color: Color = Theme.ink) {
        let dim = min(rect.width, rect.height)
        guard dim > 2 else { return }
        let s = dim / 24.0
        let ox = rect.midX - 12.0 * s
        let oy = rect.midY - 12.0 * s
        let p: (CGFloat, CGFloat) -> CGPoint = { CGPoint(x: ox + $0 * s, y: oy + $1 * s) }
        let stroke = StrokeStyle(lineWidth: max(1.1, 1.75 * s), lineCap: .round, lineJoin: .round)

        switch kind {
        case .kick:
            // Bass drum circular shell
            var head = Path()
            head.addEllipse(in: CGRect(x: ox + 4.5 * s, y: oy + 3.5 * s, width: 15.0 * s, height: 15.0 * s))
            context.stroke(head, with: .color(color), style: stroke)

            // Spurs (legs) and bass pedal
            var legs = Path()
            legs.move(to: p(6.5, 16.5))
            legs.addLine(to: p(2.5, 21.5))
            legs.move(to: p(17.5, 16.5))
            legs.addLine(to: p(21.5, 21.5))

            // Center pedal footboard
            legs.move(to: p(12.0, 18.5))
            legs.addLine(to: p(12.0, 21.5))
            legs.move(to: p(9.0, 21.5))
            legs.addLine(to: p(15.0, 21.5))
            context.stroke(legs, with: .color(color), style: stroke)

        case .snare:
            // Top head ellipse
            var top = Path()
            top.addEllipse(in: CGRect(x: ox + 4.5 * s, y: oy + 4.5 * s, width: 15.0 * s, height: 5.0 * s))
            context.stroke(top, with: .color(color), style: stroke)

            // Shallow shell sides & bottom head
            var body = Path()
            body.move(to: p(4.5, 7.0))
            body.addLine(to: p(4.5, 14.5))
            body.addQuadCurve(to: p(19.5, 14.5), control: p(12.0, 18.5))
            body.addLine(to: p(19.5, 7.0))

            // Snare center band
            body.move(to: p(4.5, 11.0))
            body.addQuadCurve(to: p(19.5, 11.0), control: p(12.0, 14.5))

            // Snare lugs
            body.move(to: p(8.5, 9.0))
            body.addLine(to: p(8.5, 13.0))
            body.move(to: p(15.5, 9.0))
            body.addLine(to: p(15.5, 13.0))
            context.stroke(body, with: .color(color), style: stroke)

        case .hiHat:
            // Stand rod
            var path = Path()
            path.move(to: p(12.0, 3.5))
            path.addLine(to: p(12.0, 21.5))

            // Closed cymbals: top and bottom touching closely
            path.move(to: p(4.0, 11.0))
            path.addQuadCurve(to: p(20.0, 11.0), control: p(12.0, 8.0))
            path.move(to: p(4.0, 12.5))
            path.addQuadCurve(to: p(20.0, 12.5), control: p(12.0, 9.5))

            // Tripod legs
            path.move(to: p(7.0, 21.5))
            path.addLine(to: p(12.0, 19.5))
            path.addLine(to: p(17.0, 21.5))
            context.stroke(path, with: .color(color), style: stroke)

        case .openHiHat:
            // Stand rod
            var path = Path()
            path.move(to: p(12.0, 3.0))
            path.addLine(to: p(12.0, 21.5))

            // Open cymbals: top cymbal tilted up, leaving a clear gap
            path.move(to: p(4.5, 7.5))
            path.addQuadCurve(to: p(19.5, 9.5), control: p(12.0, 5.5))

            // Bottom cymbal
            path.move(to: p(4.0, 13.5))
            path.addQuadCurve(to: p(20.0, 13.5), control: p(12.0, 11.5))

            // Tripod legs
            path.move(to: p(7.0, 21.5))
            path.addLine(to: p(12.0, 19.5))
            path.addLine(to: p(17.0, 21.5))
            context.stroke(path, with: .color(color), style: stroke)

        case .clap:
            // Clapping hands angled together
            var path = Path()
            // Left hand
            path.move(to: p(5.0, 18.0))
            path.addLine(to: p(9.5, 9.5))
            path.addQuadCurve(to: p(11.5, 10.5), control: p(10.5, 9.0))
            path.addLine(to: p(8.0, 19.0))

            // Right hand
            path.move(to: p(19.0, 18.0))
            path.addLine(to: p(14.5, 9.5))
            path.addQuadCurve(to: p(12.5, 10.5), control: p(13.5, 9.0))
            path.addLine(to: p(16.0, 19.0))

            // Impact sparks
            path.move(to: p(12.0, 2.5))
            path.addLine(to: p(12.0, 5.5))
            path.move(to: p(8.0, 4.5))
            path.addLine(to: p(10.0, 6.5))
            path.move(to: p(16.0, 4.5))
            path.addLine(to: p(14.0, 6.5))
            context.stroke(path, with: .color(color), style: stroke)

        case .tom:
            // Tom-tom top head
            var head = Path()
            head.addEllipse(in: CGRect(x: ox + 4.5 * s, y: oy + 4.5 * s, width: 15.0 * s, height: 5.5 * s))
            context.stroke(head, with: .color(color), style: stroke)

            // Deep shell & bottom head
            var body = Path()
            body.move(to: p(4.5, 7.2))
            body.addLine(to: p(4.5, 15.5))
            body.addQuadCurve(to: p(19.5, 15.5), control: p(12.0, 19.5))
            body.addLine(to: p(19.5, 7.2))

            // Vertical tension lugs
            body.move(to: p(8.5, 9.5))
            body.addLine(to: p(8.5, 17.5))
            body.move(to: p(15.5, 9.5))
            body.addLine(to: p(15.5, 17.5))
            context.stroke(body, with: .color(color), style: stroke)

        case .crashRide:
            // Stand rod
            var path = Path()
            path.move(to: p(12.0, 4.0))
            path.addLine(to: p(12.0, 21.5))

            // Wing nut
            path.move(to: p(10.0, 4.5))
            path.addLine(to: p(14.0, 4.5))

            // Wide cymbal saucer with center bell dome
            path.move(to: p(3.5, 10.5))
            path.addQuadCurve(to: p(10.0, 7.5), control: p(6.5, 8.5))
            path.addQuadCurve(to: p(14.0, 7.5), control: p(12.0, 5.5))
            path.addQuadCurve(to: p(20.5, 10.5), control: p(17.5, 8.5))

            // Stand legs
            path.move(to: p(7.0, 21.5))
            path.addLine(to: p(12.0, 19.5))
            path.addLine(to: p(17.0, 21.5))
            context.stroke(path, with: .color(color), style: stroke)

        case .genericDrum:
            // Frame drum with crossed drum sticks
            var head = Path()
            head.addEllipse(in: CGRect(x: ox + 4.5 * s, y: oy + 4.5 * s, width: 15.0 * s, height: 5.0 * s))
            context.stroke(head, with: .color(color), style: stroke)

            var body = Path()
            body.move(to: p(4.5, 7.0))
            body.addLine(to: p(4.5, 15.0))
            body.addQuadCurve(to: p(19.5, 15.0), control: p(12.0, 18.5))
            body.addLine(to: p(19.5, 7.0))

            // Crossed sticks
            body.move(to: p(6.5, 19.0))
            body.addLine(to: p(17.5, 9.0))
            body.move(to: p(17.5, 19.0))
            body.addLine(to: p(6.5, 9.0))
            context.stroke(body, with: .color(color), style: stroke)
        }
    }
}

struct PadVoice {
    static let abbreviations = ["TH", "TL", "CR", "RD", "SH", "WD", "CB", "OH", "HH", "CP", "RM", "HH", "KD", "SN", "SN", "KD"]
    static let names = ["High tom", "Low tom", "Crash", "Ride", "Shaker", "Wood", "Cowbell", "Open hi-hat", "Hi-hat", "Clap", "Rim", "Hi-hat", "Kick", "Snare", "Snare", "Kick"]
    static let rowOrder = [2, 3, 0, 1, 6, 5, 4, 7, 8, 11, 9, 10, 13, 14, 12, 15]
    static func abbreviation(_ pad: Int) -> String { abbreviations.indices.contains(pad) ? abbreviations[pad] : "?" }

    /// Canonical English drum name shown in the band, legend, settings, and help across all locales.
    static func displayName(_ pad: Int) -> String {
        guard names.indices.contains(pad) else { return "Pad \(pad + 1)" }
        return names[pad]
    }

    static func name(_ pad: Int, settings: SettingsManager? = nil) -> String {
        _ = settings
        return displayName(pad)
    }
}

/// Precomputed data for a single pad cell in PadLayoutGrid.
public struct PadLayoutCellData: Equatable {
    public let pad: Int
    public let abbreviation: String
    public let keyLabel: String?
    public let combinedLabel: String
    public let isUsed: Bool
    public let accessibilityBase: String
    public let accessibilityWithKey: String

    public init(pad: Int, abbreviation: String, keyLabel: String?, combinedLabel: String, isUsed: Bool, accessibilityBase: String, accessibilityWithKey: String) {
        self.pad = pad
        self.abbreviation = abbreviation
        self.keyLabel = keyLabel
        self.combinedLabel = combinedLabel
        self.isUsed = isUsed
        self.accessibilityBase = accessibilityBase
        self.accessibilityWithKey = accessibilityWithKey
    }
}

/// Precomputed layout and labels for the pad layout grid.
/// Computed once per lesson and controller mapping so toggling key labels only shows/hides.
public struct PadLayoutModel: Equatable {
    public let pads: [Int]
    public let cells: [PadLayoutCellData]
    public let canShowKeys: Bool

    public init(pads: [Int], used: Set<Int>, canShowKeys: Bool, settings: SettingsManager? = nil) {
        self.pads = pads
        self.canShowKeys = canShowKeys
        self.cells = pads.map { pad in
            let abbr = PadVoice.abbreviation(pad)
            let key = KeyboardPadMapping.label(for: pad)
            let combined = key.map { "\(abbr) · \($0)" } ?? abbr
            let name = PadVoice.name(pad, settings: settings)
            let base = "\(name), pad \(pad + 1)"
            let withKey = key.map { "\(base), key \($0)" } ?? base
            return PadLayoutCellData(
                pad: pad,
                abbreviation: abbr,
                keyLabel: key,
                combinedLabel: combined,
                isUsed: used.contains(pad),
                accessibilityBase: base,
                accessibilityWithKey: withKey
            )
        }
    }
}

/// The small diagram used in landscape and when touch pads are off. Tapping it toggles keyboard key labels.
struct PadLayoutGrid: View {
    @Environment(SettingsManager.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduced
    @ScaledMetric(relativeTo: .body) private var width: CGFloat = 176
    var side: CGFloat? = nil
    let model: PadLayoutModel
    var flashes: [Int: PadFlash] = [:]
    var showKeyboardKeys: Bool = false

    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }

    private var grid: PhysicalPadGrid { settings.activeProfile().grid }
    private var displayCells: [PadLayoutCellData] {
        grid.displaySlots.compactMap { slot in
            let target = settings.activeProfile().target(forSlot: slot)
            guard model.pads.indices.contains(target) else { return nil }
            return model.cells.first { $0.pad == model.pads[target] }
        }
    }

    init(side: CGFloat? = nil, model: PadLayoutModel, flashes: [Int: PadFlash] = [:], showKeyboardKeys: Bool = false) {
        self.side = side
        self.model = model
        self.flashes = flashes
        self.showKeyboardKeys = showKeyboardKeys
    }

    init(side: CGFloat? = nil, pads: [Int], used: Set<Int>, flashes: [Int: PadFlash] = [:], showKeyboardKeys: Bool = false) {
        self.side = side
        self.model = PadLayoutModel(pads: pads, used: used, canShowKeys: pads.count == 16)
        self.flashes = flashes
        self.showKeyboardKeys = showKeyboardKeys
    }

    var body: some View {
        TimelineView(PadFlashSchedule(flashes: flashes)) { timeline in
            if let side {
                let spacing = Theme.Space.tight
                let cellSize = max(0, (side - CGFloat(max(grid.rows, grid.columns) - 1) * spacing) / CGFloat(max(grid.rows, grid.columns)))
                VStack(spacing: spacing) {
                    ForEach(0..<grid.rows, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<grid.columns, id: \.self) { col in
                                let index = row * grid.columns + col
                                if displayCells.indices.contains(index) {
                                    cell(displayCells[index], cellSize: cellSize, now: timeline.date)
                                }
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Space.tight), count: grid.columns), spacing: Theme.Space.tight) {
                    ForEach(displayCells, id: \.pad) { cellData in
                        cell(cellData, cellSize: nil, now: timeline.date)
                    }
                }
                .frame(width: width)
            }
        }
    }

    private func cell(_ cellData: PadLayoutCellData, cellSize: CGFloat?, now: Date) -> some View {
        let flash = flashes[cellData.pad]
        let strength = flash?.strength(at: now) ?? 0
        let isUsed = cellData.isUsed
        let tint = (flash?.color ?? Theme.orange).opacity(strength)

        let fontWithoutKeys: Font = {
            if let cellSize {
                return Theme.canvasDisplay(min(18, max(12, cellSize * 0.4)))
            }
            return Theme.text(Theme.Size.dense)
        }()
        let fontWithKeys: Font = {
            if let cellSize {
                return Theme.text(min(11, cellSize * 0.3))
            }
            return Theme.text(12)
        }()

        let textStyle: Color = {
            if strength > 0.35 { return Theme.white }
            if isUsed { return Theme.ink }
            return Theme.ink.opacity(0.75)
        }()
        let cellRadius: CGFloat = 4
        let outlineColor: Color = isUsed ? Theme.ink : Theme.hairline
        let outlineWidth: CGFloat = isUsed ? Theme.Size.border : 1.0

        return ZStack {
            Text(cellData.abbreviation)
                .font(fontWithoutKeys)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(showKeyboardKeys ? 0 : 1)

            Text(cellData.combinedLabel)
                .font(fontWithKeys)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(showKeyboardKeys ? 1 : 0)
        }
        .animation(motion.animation(Theme.Motion.fast), value: showKeyboardKeys)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(width: cellSize, height: cellSize)
        .foregroundStyle(textStyle)
        .background {
            cellBackground(cellRadius: cellRadius, tint: tint, outlineColor: outlineColor, outlineWidth: outlineWidth)
        }
        .accessibilityLabel(showKeyboardKeys ? cellData.accessibilityWithKey : cellData.accessibilityBase)
    }

    private func cellBackground(cellRadius: CGFloat, tint: Color, outlineColor: Color, outlineWidth: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cellRadius)
            .fill(Theme.Skin.Pad.fill)
            .overlay {
                SkinBevel(radius: cellRadius,
                          highlight: Theme.Skin.Pad.highlight,
                          shade: Theme.Skin.Pad.shade,
                          top: 1, bottom: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cellRadius)
                    .fill(tint)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cellRadius)
                    .strokeBorder(outlineColor, lineWidth: outlineWidth)
            }
            .shadow(color: Theme.black.opacity(0.06), radius: 1, y: 1)
    }
}

/// The square in the bottom-left of the practice screen showing the controller layout.
/// Tapping toggles keyboard key labels. State is isolated here so toggling never
/// invalidates or re-renders the rest of PracticeScreen.
struct PracticePadLayoutSquare: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Environment(SettingsManager.self) private var settings
    @State private var showPadKeys = false
    let side: CGFloat
    let model: PadLayoutModel
    let session: PracticeSession
    let showPads: Bool

    private var motion: Theme.Motion.Policy { .init(reduced: reduced) }

    var body: some View {
        ZStack {
            if showPads && !model.cells.isEmpty {
                PadLayoutGrid(
                    side: side,
                    model: model,
                    flashes: session.padFlashes,
                    showKeyboardKeys: model.canShowKeys && showPadKeys
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if model.canShowKeys {
                        withAnimation(motion.animation(Theme.Motion.fast)) {
                            showPadKeys.toggle()
                        }
                    }
                }
                .accessibilityAddTraits(model.canShowKeys ? .isButton : [])
                .accessibilityHint(model.canShowKeys ? settings.localized("Shows or hides keyboard keys") : "")
            }
        }
        .frame(width: side, height: side)
    }
}

/// A stable playing deck: only the reading section above it may scroll.
struct PracticeTouchPadGrid: View {
    @Environment(SettingsManager.self) private var settings
    let session: PracticeSession
    let pads: [Int]
    let used: Set<Int>
    let enabled: Bool
    let onPress: (Int, Bool) -> Void

    var body: some View {
        let flashes = session.padFlashes
        GeometryReader { geometry in
            let cellWidth = max(0, (geometry.size.width - 24) / 4)
            let cellHeight = max(0, (geometry.size.height - 24) / 4)
            TimelineView(PadFlashSchedule(flashes: flashes)) { timeline in
                VStack(spacing: Theme.Space.small) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: Theme.Space.small) {
                            ForEach(0..<4, id: \.self) { column in
                                let pad = pads[row * 4 + column]
                                cell(pad, size: min(cellWidth, cellHeight), now: timeline.date, flashes: flashes)
                                    .frame(width: cellWidth, height: cellHeight)
                            }
                        }
                    }
                }
            }
        }
    }

    private func cell(_ pad: Int, size: CGFloat, now: Date, flashes: [Int: PadFlash]) -> some View {
        let flash = flashes[pad]
        let strength = flash?.strength(at: now) ?? 0
        let isUsed = used.contains(pad)
        return Text(PadVoice.abbreviation(pad))
            .font(Theme.canvasDisplay(min(44, max(24, size * 0.28))))
            .foregroundStyle(strength > 0.35 ? Theme.white : (isUsed ? Theme.ink : Theme.secondary))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    Theme.surface
                    (flash?.color ?? Theme.orange).opacity(strength)
                }
            }
            .overlay(Rectangle().strokeBorder(Theme.ink, lineWidth: isUsed ? Theme.Size.border : 0))
            .overlay {
                PadPressSurface(enabled: enabled) { onPress(pad, $0) }
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(settings.localized("%@, pad %lld", PadVoice.name(pad, settings: settings), pad + 1))
            .accessibilityValue(isUsed ? settings.localized("Used in this lesson") : "")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction {
                guard enabled else { return }
                onPress(pad, true)
                onPress(pad, false)
            }
    }
}

/// Raw UIKit touches keep each pad independent, without a drag recognizer winning
/// over other fingers. A touch belongs to its starting pad until it ends.
struct PadPressSurface: UIViewRepresentable {
    var enabled = true
    let onPress: (Bool) -> Void

    func makeUIView(context: Context) -> PadPressView {
        let view = PadPressView()
        view.isMultipleTouchEnabled = true
        view.isExclusiveTouch = false
        view.backgroundColor = .clear
        view.isOpaque = false
        view.onPress = onPress
        view.inputEnabled = enabled
        return view
    }

    func updateUIView(_ view: PadPressView, context: Context) {
        view.onPress = onPress
        view.inputEnabled = enabled
    }

    static func dismantleUIView(_ view: PadPressView, coordinator: ()) {
        view.release()
    }
}

final class PadPressView: UIView {
    var onPress: (Bool) -> Void = { _ in }
    var inputEnabled = true {
        didSet { if !inputEnabled { release() } }
    }
    private var trackedTouch: UITouch?
    private var pressed = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard inputEnabled, trackedTouch == nil, let touch = touches.first else { return }
        trackedTouch = touch
        pressed = true
        onPress(true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackedTouch, touches.contains(touch) else { return }
        if !bounds.contains(touch.location(in: self)) { release() }
        // Re-entering this or a neighbouring pad never starts another note.
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            release()
            trackedTouch = nil
        }
    }

    private func finish(_ touches: Set<UITouch>) {
        guard let touch = trackedTouch, touches.contains(touch) else { return }
        release()
        trackedTouch = nil
    }

    func release() {
        guard pressed else { return }
        pressed = false
        onPress(false)
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
                    .font(Theme.meta).monospacedDigit()
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
            .frame(minHeight: Theme.Size.minimumTouch)
            .contentShape(Rectangle())
        }
        .padding(.vertical, Theme.Space.tight)
    }
}
