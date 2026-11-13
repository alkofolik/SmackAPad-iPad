import SwiftUI
import UIKit

/// Recessed glass shared by the settled Home and its power-on animation.
/// The status input is intentionally independent of the logo and controller lookup.
struct HomeHardwareDisplay: View {
    let status: String
    var pixelsVisible = true
    var powered = true

    private static let glyphs: [Character: [String]] = [
        "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
        "M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
        "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
        "C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
        "K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
        "-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
        "P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
        "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"]
    ]

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                matrix(litOnly: false).opacity(pixelsVisible ? 1 : 0)
                matrix(litOnly: true)
                    .shadow(color: Theme.orange.opacity(0.38), radius: 3)
                    .opacity(powered ? 1 : 0)
            }
            Text(status)
                .font(Theme.text(14))
                .foregroundStyle(Theme.Skin.Display.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .opacity(powered ? 1 : 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: Theme.Radius.button)
                .fill(Theme.Skin.Display.fill)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(LinearGradient(colors: [Theme.Skin.Display.glassTop, Theme.Skin.Display.glassBottom],
                                             startPoint: .top, endPoint: .bottom))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .strokeBorder(Theme.HomeController.slot, lineWidth: 3)
                }
                .shadow(color: Theme.padBevelTop, radius: 0, y: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Smack-a-Pad")
        .accessibilityValue(status)
        .allowsHitTesting(false)
    }

    private func matrix(litOnly: Bool) -> some View {
        Canvas { context, size in
            let title = Array("SMACK-A-PAD")
            let columns = title.count * 6 - 1
            let pitch = min(size.width / CGFloat(columns), size.height / 7)
            let origin = CGPoint(x: (size.width - CGFloat(columns) * pitch) / 2,
                                 y: (size.height - 7 * pitch) / 2)
            var lit = Path()
            var unlit = Path()
            for (index, letter) in title.enumerated() {
                guard let glyph = Self.glyphs[letter] else { continue }
                for (row, line) in glyph.enumerated() {
                    for (column, pixel) in line.enumerated() {
                        let dot = CGRect(x: origin.x + CGFloat(index * 6 + column) * pitch,
                                         y: origin.y + CGFloat(row) * pitch,
                                         width: pitch * 0.64, height: pitch * 0.64)
                        unlit.addEllipse(in: dot)
                        if pixel == "1" { lit.addEllipse(in: dot) }
                    }
                }
            }
            if litOnly {
                context.fill(lit, with: .color(Theme.orange))
            } else {
                context.fill(unlit, with: .color(Theme.white.opacity(0.07)))
            }
        }
        .accessibilityHidden(true)
    }
}

struct HomeLanguageKnob: View {
    @Environment(SettingsManager.self) private var settings
    @State private var dragAngle: Double?
    @State private var previousTouchAngle: Double?

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: 46)
            let radius = min(57, max(36, proxy.size.width / 2 - 22))
            ZStack {
                Circle()
                    .fill(Theme.cavity)
                    .frame(width: 66, height: 66)
                    .overlay {
                        Circle()
                            .fill(LinearGradient(colors: [Theme.HomeController.capTop, Theme.HomeController.capShade],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .padding(5)
                            .overlay {
                                Capsule()
                                    .fill(Theme.orange)
                                    .frame(width: 3, height: 15)
                                    .offset(y: -16)
                                    .rotationEffect(.degrees(LanguageKnobMapping.angle(for: settings.languagePreference)))
                            }
                    }
                    .shadow(color: Theme.black.opacity(0.25), radius: 2, y: 2)
                    .frame(width: 72, height: 72)
                    .contentShape(Circle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let angle = atan2(Double(value.location.x - 36), Double(36 - value.location.y)) * 180 / .pi
                                if let previousTouchAngle {
                                    var delta = angle - previousTouchAngle
                                    if delta > 180 { delta -= 360 }
                                    if delta < -180 { delta += 360 }
                                    let next = min(max((dragAngle ?? 0) + delta,
                                                       LanguageKnobMapping.minimumAngle), LanguageKnobMapping.maximumAngle)
                                    dragAngle = next
                                    select(LanguageKnobMapping.language(fromAngle: next))
                                } else {
                                    dragAngle = LanguageKnobMapping.angle(for: settings.languagePreference)
                                }
                                previousTouchAngle = angle
                            }
                            .onEnded { _ in
                                dragAngle = nil
                                previousTouchAngle = nil
                            }
                    )
                    .position(center)

                ForEach(AppLanguage.allCases) { language in
                    let angle = LanguageKnobMapping.angle(for: language) * .pi / 180
                    Button { select(language) } label: {
                        Text(language.homeDetentLabel)
                            .font(Theme.text(14))
                            .foregroundStyle(Theme.ink)
                            .underline(settings.languagePreference == language)
                            .frame(minWidth: Theme.Size.minimumTouch, minHeight: Theme.Size.minimumTouch)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(x: center.x + sin(angle) * radius, y: center.y - cos(angle) * radius)
                }
                Text(settings.localized("Language"))
                    .font(Theme.text(14))
                    .foregroundStyle(Theme.secondary)
                    .position(x: center.x, y: 125)
            }
        }
        .frame(height: 144)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Language"))
        .accessibilityValue(settings.languagePreference.displayName)
        .accessibilityAdjustableAction { direction in
            let cases = AppLanguage.allCases
            let current = cases.firstIndex(of: settings.languagePreference) ?? 0
            switch direction {
            case .increment: select(cases[min(current + 1, cases.count - 1)])
            case .decrement: select(cases[max(current - 1, 0)])
            @unknown default: break
            }
        }
    }

    private func select(_ language: AppLanguage) {
        guard settings.languagePreference != language else { return }
        settings.languagePreference = language
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct HomeAppearanceSwitch: View {
    @Environment(SettingsManager.self) private var settings

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let capWidth = min(40.0, proxy.size.width / 3)
                let travel = max(1, proxy.size.width - capWidth)
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.cavity)
                    RoundedRectangle(cornerRadius: Theme.Radius.button)
                        .fill(LinearGradient(colors: [Theme.HomeController.capTop, Theme.HomeController.capBottom],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay {
                            HStack(spacing: 3) {
                                ForEach(0..<3) { _ in
                                    Capsule().fill(Theme.HomeController.slot.opacity(0.6)).frame(width: 2, height: 17)
                                }
                            }
                        }
                        .padding(3)
                        .frame(width: capWidth)
                        .offset(x: AppearanceSwitchMapping.position(for: settings.appearance) * travel)
                }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            settings.appearance = AppearanceSwitchMapping.appearance(
                                fromPosition: (value.location.x - capWidth / 2) / travel)
                        }
                )
            }
            .frame(height: Theme.Size.minimumTouch)
            HStack(spacing: 0) {
                ForEach(AppearanceSwitchMapping.positions) { appearance in
                    Button { settings.appearance = appearance } label: {
                        Text(settings.localized(appearance == .system ? "home.appearance.auto" : appearance.title))
                            .font(Theme.text(14))
                            .foregroundStyle(Theme.ink)
                            .underline(settings.appearance == appearance)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.minimumTouch)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(settings.localized("Appearance"))
                .font(Theme.text(14))
                .foregroundStyle(Theme.secondary)
        }
        .frame(height: 144)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Appearance"))
        .accessibilityValue(settings.localized(settings.appearance == .system ? "home.appearance.auto" : settings.appearance.title))
        .accessibilityAdjustableAction { direction in
            let current = AppearanceSwitchMapping.position(for: settings.appearance)
            switch direction {
            case .increment: settings.appearance = AppearanceSwitchMapping.appearance(fromPosition: current + 0.5)
            case .decrement: settings.appearance = AppearanceSwitchMapping.appearance(fromPosition: current - 0.5)
            @unknown default: break
            }
        }
    }
}
