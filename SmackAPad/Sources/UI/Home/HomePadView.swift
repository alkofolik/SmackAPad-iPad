import SwiftUI

/// Tactile pad press animation style (scale 0.965 and 1.5 pt down, 60 ms light flash, spring back in 0.18 s).
/// Reduce Motion: darker fill only (0.1 s), no scale or movement.
struct TactilePadButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)
        let isPressed = configuration.isPressed

        configuration.label
            .overlay {
                if policy.reduced {
                    if isPressed {
                        RoundedRectangle(cornerRadius: Theme.Radius.pad)
                            .fill(Theme.black.opacity(0.12))
                            .allowsHitTesting(false)
                    }
                } else {
                    RoundedRectangle(cornerRadius: Theme.Radius.pad)
                        .fill(Theme.white)
                        .opacity(isPressed ? 0.38 : 0.0)
                        .animation(Theme.Motion.padFlash, value: isPressed)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(policy.scale(isPressed ? 0.965 : 1.0))
            .offset(y: policy.offset(isPressed ? 1.5 : 0))
            .animation(
                policy.reduced ? .easeOut(duration: 0.1) : (isPressed ? .easeOut(duration: 0.06) : Theme.Motion.padPress),
                value: isPressed
            )
    }
}

/// Pure subtitle and target helpers for the 8 Home pads so logic stays testable without views.
enum HomePadSubtitles {
    static func singleLine(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func today(plan: TodayPlan?, language: AppLanguage) -> String? {
        guard let plan else { return nil }
        let remaining = plan.remainingStepCount
        guard remaining > 0 else { return language.localized("home.today.done") }
        let format = if remaining == 1 {
            language.localized("%lld step · %lld min")
        } else if language == .czech && remaining >= 5 {
            "%lld kroků · %lld min"
        } else {
            language.localized("%lld steps · %lld min")
        }
        return String(format: format, locale: Locale(identifier: language.rawValue), remaining, plan.estimatedMinutes)
    }

    static func library() -> String? {
        nil
    }

    static func continueLesson(lastPlayedLesson: Lesson?, language: AppLanguage) -> String? {
        guard let lastPlayedLesson else { return nil }
        let shortKey = "home.short.\(lastPlayedLesson.title)"
        let localizedCandidate = language.localizedOptional(shortKey) ?? language.localized(lastPlayedLesson.title)
        let localized = singleLine(localizedCandidate)
        return localized.isEmpty ? nil : localized
    }

    static func continueTarget(
        lastPlayedLesson: Lesson?,
        introFirstLesson: Lesson?,
        pathFirstLesson: Lesson?
    ) -> Lesson? {
        lastPlayedLesson ?? introFirstLesson ?? pathFirstLesson
    }

    static func intro() -> String? {
        nil
    }

    static func controller(connectedName: String?, language: AppLanguage) -> String {
        guard let connectedName else {
            return singleLine(language.localized("Not connected"))
        }
        let trimmed = singleLine(connectedName)
        guard !trimmed.isEmpty else {
            return singleLine(language.localized("Not connected"))
        }

        if isNetworkSession(trimmed) {
            return language == .czech ? "Síťový MIDI" : "Network MIDI"
        }

        return truncateAtWordBoundary(trimmed, limit: 14)
    }

    static func isNetworkSession(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.contains("network session") || lower.contains("síťová relace") || lower.contains("sitova relace") {
            return true
        }
        if lower == "network midi" || lower == "síťový midi" || lower == "sitovy midi" {
            return true
        }
        return false
    }

    static func truncateAtWordBoundary(_ text: String, limit: Int = 14) -> String {
        guard text.count > limit else { return text }
        let words = text.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let first = words.first else { return "" }
        if first.count >= limit {
            return first
        }
        var result = first
        for word in words.dropFirst() {
            let candidate = result + " " + word
            if candidate.count <= limit {
                result = candidate
            } else {
                break
            }
        }
        return result
    }

    static func badges(earned: Int, total: Int) -> String {
        "\(earned) / \(total)"
    }

    static func fullVersion(hasFullAccess: Bool, price: String?, language: AppLanguage) -> String? {
        if hasFullAccess {
            return singleLine(language.localized("Unlocked"))
        }
        guard let price else { return nil }
        let trimmed = singleLine(price)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func settings() -> String? {
        nil
    }
}

/// A tactile button pad on the Home screen.
struct HomePadView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let title: String
    let subtitle: String?
    var numericTransitionValue: Int? = nil
    var accessibilityText: String? = nil
    var accessibilityValue: String? = nil
    var padNumber: Int? = nil
    var cellSize: CGFloat = 146
    let isHero: Bool
    let action: () -> Void

    var body: some View {
        let policy = Theme.Motion.Policy(reduced: reduceMotion)

        Button(action: action) {
            VStack(spacing: Theme.Space.tight) {
                Spacer(minLength: 0)
                let titleSize = 22.0 * (cellSize / 146.0)
                Text(title.uppercased())
                    .font(Theme.padTitle(size: titleSize))
                    .tracking(titleSize * 0.03)
                    .foregroundStyle(isHero ? Theme.black : Theme.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                let trimmedSubtitle = subtitle.map(HomePadSubtitles.singleLine) ?? ""
                let hasSubtitle = !trimmedSubtitle.isEmpty
                subtitleText(trimmedSubtitle: trimmedSubtitle, hasSubtitle: hasSubtitle, policy: policy)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Space.small)
            // Reserve the engraving band before text fitting chooses subtitle variants.
            .padding(.top, padNumber == nil ? 0 : 22)
            .padding(.bottom, Theme.Space.small)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .fill(isHero ? Theme.orange : Theme.surface)
                    .shadow(
                        color: isHero ? Theme.orange.opacity(0.25) : Theme.black.opacity(0.08),
                        radius: isHero ? 3 : 2,
                        x: 0,
                        y: isHero ? 3 : 2
                    )
            )
            .overlay {
                // Two-tone bevel: top 1.5 pt light highlight, bottom 2 pt darker edge (proposal A)
                VStack(spacing: 0) {
                    (isHero ? Theme.white.opacity(0.42) : Theme.padBevelTop)
                        .frame(height: 1.5)
                    Spacer(minLength: 0)
                    (isHero ? Theme.black.opacity(0.28) : Theme.padBevelBottom)
                        .frame(height: isHero ? 2.5 : 2.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
                .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.pad)
                    .strokeBorder(isHero ? Theme.black.opacity(0.12) : Theme.hairline, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                if let padNumber {
                    Text(verbatim: String(format: "%02d", padNumber))
                        .font(Theme.canvasDisplay(9).monospacedDigit())
                        .foregroundStyle(isHero ? Theme.black : Theme.secondary)
                        .shadow(color: Theme.white.opacity(isHero ? 0.3 : 0.45), radius: 0, y: 0.6)
                        .padding(.leading, 8)
                        .padding(.top, 7)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.pad))
        }
        .buttonStyle(TactilePadButtonStyle())
        .accessibilityLabel(accessibilityText ?? defaultAccessibilityText)
        .modifier(AccessibilityValueModifier(value: accessibilityValue))
    }

    @ViewBuilder
    private func subtitleText(
        trimmedSubtitle: String,
        hasSubtitle: Bool,
        policy: Theme.Motion.Policy
    ) -> some View {
        let base = Text(hasSubtitle ? trimmedSubtitle : " ")
            .font(Theme.meta)
            .foregroundStyle(isHero ? Theme.black : Theme.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .opacity(hasSubtitle ? 1 : 0)
            .accessibilityHidden(!hasSubtitle)

        if let numericTransitionValue, hasSubtitle {
            base
                .contentTransition(policy.numeric)
                .motion(value: numericTransitionValue)
        } else {
            base
        }
    }

    private var defaultAccessibilityText: String {
        var parts: [String] = [title]
        if let subtitle {
            let trimmed = HomePadSubtitles.singleLine(subtitle)
            if !trimmed.isEmpty {
                parts.append(trimmed)
            }
        }
        return parts.joined(separator: ", ")
    }
}

private struct AccessibilityValueModifier: ViewModifier {
    let value: String?
    @ViewBuilder
    func body(content: Content) -> some View {
        if let value, !value.isEmpty {
            content.accessibilityValue(value)
        } else {
            content
        }
    }
}

/// The centre logo mark (three pads + rotated orange pad at 8°, optically centred).
struct HomeLogoMarkView: View {
    let size: CGFloat
    let darkAppearance: Bool
    private static let blackPad = Color(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0)
    private static let creamPad = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)
    private static let orangePad = Color(red: 255 / 255.0, green: 91 / 255.0, blue: 31 / 255.0)

    var body: some View {
        let unit = size / 100.0
        let padDimension = 32.0 * unit
        let cornerRadius = 3.0 * unit
        let neutralPadColor = darkAppearance ? Self.creamPad : Self.blackPad

        ZStack {
            // Three neutral pads
            ZStack {
                // Top-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .position(x: 28.4086 * unit, y: 32.5914 * unit)

                // Bottom-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .position(x: 28.4086 * unit, y: 72.5914 * unit)

                // Bottom-right
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(neutralPadColor)
                    .frame(width: padDimension, height: padDimension)
                    .position(x: 68.4086 * unit, y: 72.5914 * unit)
            }
            .frame(width: size, height: size)

            // Top-right orange smack pad
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Self.orangePad)
                .frame(width: padDimension, height: padDimension)
                .rotationEffect(.degrees(8))
                .position(x: 69.9086 * unit, y: 29.0914 * unit)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Smack-a-Pad")
        .accessibilityAddTraits(.isImage)
    }
}
