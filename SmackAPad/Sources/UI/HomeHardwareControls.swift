import SwiftUI
import UIKit

/// Recessed glass shared by the settled Home and its power-on animation.
/// The status input is intentionally independent of the logo and controller lookup.
struct HomeHardwareDisplay: View {
    let status: String
    var accessibilityStatus: String? = nil
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
        .accessibilityValue(accessibilityStatus ?? status)
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

/// Small circular hardware LED next to the display that flashes on incoming MIDI notes and fades out (ticket 207).
struct HomeMidiActivityLed: View {
    let brightness: Double

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Theme.cavity)
                .frame(width: 14, height: 14)
                .overlay {
                    Circle()
                        .fill(brightness > 0 ? Theme.orange.opacity(0.25 + 0.75 * brightness) : Theme.ledOff)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.orange.opacity(brightness * 0.9), radius: 4)
                }
                .overlay {
                    Circle()
                        .strokeBorder(Theme.black.opacity(0.2), lineWidth: 0.5)
                        .frame(width: 14, height: 14)
                }
            Text("MIDI")
                .font(Theme.canvasDisplay(9))
                .tracking(0.5)
                .foregroundStyle(Theme.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityHidden(true)
    }
}

/// Pure builder for the hardware display's status line text on MIDI hits (ticket 207).
public enum HomeDisplayStatusBuilder {
    public static func statusText(
        for note: Int,
        channel: Int = 1,
        profile: ControllerProfile,
        padIndices: [Int]? = nil,
        controls: MIDIControlConfiguration = MIDIControlConfiguration()
    ) -> String {
        let signal = MIDIControlSignal(kind: .note, channel: channel, number: note)
        return statusText(for: signal, profile: profile, padIndices: padIndices, controls: controls)
    }

    public static func statusText(
        for signal: MIDIControlSignal,
        profile: ControllerProfile,
        padIndices: [Int]? = nil,
        controls: MIDIControlConfiguration = MIDIControlConfiguration()
    ) -> String {
        // 1. Controller button (MIDIControl)
        if let action = MIDIPracticeAction.allCases.first(where: {
            guard let btnSignal = controls.buttons[$0.rawValue]?.signal else { return false }
            return btnSignal == signal || (btnSignal.kind == signal.kind && btnSignal.number == signal.number)
        }) {
            return action.title
        }

        // 2. Mapped note
        if signal.kind == .note,
           let target = profile.target(forMidiNote: signal.number) {
            let pads = padIndices ?? (profile.isEightPad ? EightPadLayout.baseSlots : Array(0..<16))
            if pads.indices.contains(target) {
                let padIndex = pads[target]
                let drum = PadVoice.displayName(padIndex)
                return "\(drum) · \(signal.number)"
            }
        }

        // 3. Unmapped note
        if signal.kind == .note {
            return "Note \(signal.number) · not mapped"
        }

        return "CC \(signal.number) · not mapped"
    }

    public static func statusText(for action: MIDIPracticeAction) -> String {
        action.title
    }
}

/// Tick marks around the language knob.
/// Positioned on a circle around the groove, not on the cap.
private struct HomeKnobTicksView: View {
    let detentAngles: [Double]
    let center: CGPoint

    private let innerRadius: CGFloat = 34
    private let majorOuterRadius: CGFloat = 40
    private let minorOuterRadius: CGFloat = 37.5

    var body: some View {
        Canvas { context, _ in
            var anglesToDraw: [(angle: Double, isDetent: Bool)] = []
            for deg in stride(from: LanguageKnobMapping.minimumAngle, through: LanguageKnobMapping.maximumAngle, by: 45.0) {
                let isDetent = detentAngles.contains { abs($0 - deg) < 1.0 }
                anglesToDraw.append((deg, isDetent))
            }
            for detent in detentAngles {
                if !anglesToDraw.contains(where: { abs($0.angle - detent) < 1.0 }) {
                    anglesToDraw.append((detent, true))
                }
            }

            for item in anglesToDraw {
                let rad = item.angle * .pi / 180.0
                let sinA = sin(rad)
                let cosA = cos(rad)
                let rOuter = item.isDetent ? majorOuterRadius : minorOuterRadius
                let p1 = CGPoint(x: center.x + sinA * innerRadius, y: center.y - cosA * innerRadius)
                let p2 = CGPoint(x: center.x + sinA * rOuter, y: center.y - cosA * rOuter)

                var path = Path()
                path.move(to: p1)
                path.addLine(to: p2)
                context.stroke(
                    path,
                    with: .color(Theme.ink.opacity(item.isDetent ? 0.65 : 0.32)),
                    lineWidth: item.isDetent ? 1.5 : 1.0
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct HomeLanguageKnob: View {
    @Environment(SettingsManager.self) private var settings
    @State private var dragAngle: Double?
    @State private var previousTouchAngle: Double?

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: 46)
            let radius = min(57, max(46, proxy.size.width / 2 - 22))
            let detentAngles = AppLanguage.allCases.map { LanguageKnobMapping.angle(for: $0) }
            let currentAngle = dragAngle ?? LanguageKnobMapping.angle(for: settings.languagePreference)

            ZStack {
                // Static groove ring around the knob body
                Circle()
                    .fill(LinearGradient(colors: [Theme.HomeController.plateShade, Theme.HomeController.plateBottom],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Circle()
                            .strokeBorder(Theme.HomeController.slot.opacity(0.35), lineWidth: 1)
                    }
                    .position(center)

                // Static drop shadow underneath the cap (does not rotate with the cap)
                Circle()
                    .fill(Theme.black.opacity(0.25))
                    .frame(width: 50, height: 50)
                    .blur(radius: 2)
                    .offset(y: 2)
                    .position(center)

                // Static tick marks around the groove
                HomeKnobTicksView(detentAngles: detentAngles, center: center)

                // Rotating cap and indicator
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Theme.HomeController.capTop, Theme.HomeController.capShade],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            Circle()
                                .strokeBorder(Theme.black.opacity(0.2), lineWidth: 0.5)
                        }
                    Capsule()
                        .fill(Theme.orange)
                        .frame(width: 3, height: 14)
                        .offset(y: -14)
                }
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(currentAngle))
                .position(center)

                // Knob drag touch area
                Circle()
                    .fill(Color.clear)
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

                // Detent labels with panel lettering and LED dots
                ForEach(AppLanguage.allCases) { language in
                    let angle = LanguageKnobMapping.angle(for: language) * .pi / 180
                    let isSelected = settings.languagePreference == language
                    Button { select(language) } label: {
                        VStack(spacing: 3) {
                            Circle()
                                .fill(isSelected ? Theme.orange : Theme.ledOff)
                                .frame(width: 5, height: 5)
                                .shadow(color: isSelected ? Theme.orange.opacity(0.8) : .clear, radius: 2)
                            Text(language.homeDetentLabel)
                                .font(Theme.padTitle(size: 13))
                                .tracking(1.2)
                                .foregroundStyle(isSelected ? Theme.ink : Theme.secondary)
                        }
                        .frame(minWidth: Theme.Size.minimumTouch, minHeight: Theme.Size.minimumTouch)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(x: center.x + sin(angle) * radius, y: center.y - cos(angle) * radius)
                }

                // Panel caption
                Text(settings.localized("Language").uppercased())
                    .font(Theme.padTitle(size: 11))
                    .tracking(1.2)
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
                let activePosition = AppearanceSwitchMapping.position(for: settings.appearance)

                ZStack(alignment: .leading) {
                    // Recessed slide track in hardware colours
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [Theme.HomeController.plateShade, Theme.HomeController.plateBottom],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Theme.HomeController.slot.opacity(0.35), lineWidth: 1)
                        }
                        .overlay {
                            // Center slot groove
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(Theme.HomeController.slot.opacity(0.4))
                                .frame(height: 3)
                                .padding(.horizontal, 8)
                        }
                        .overlay {
                            // Three detent marks
                            ForEach(AppearanceSwitchMapping.positions) { appearance in
                                let pos = AppearanceSwitchMapping.position(for: appearance)
                                let detentX = capWidth / 2 + pos * travel
                                Rectangle()
                                    .fill(Theme.ink.opacity(0.35))
                                    .frame(width: 1.5, height: 8)
                                    .position(x: detentX, y: 13)
                            }
                        }
                        .frame(height: 26)
                        .frame(maxHeight: .infinity, alignment: .center)

                    // Cap with grip lines
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [Theme.HomeController.capTop, Theme.HomeController.capMiddle, Theme.HomeController.capBottom],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Theme.black.opacity(0.2), lineWidth: 0.5)
                        }
                        .overlay {
                            HStack(spacing: 3) {
                                ForEach(0..<3) { _ in
                                    Capsule()
                                        .fill(Theme.HomeController.slot.opacity(0.55))
                                        .frame(width: 2, height: 16)
                                }
                            }
                        }
                        .shadow(color: Theme.black.opacity(0.25), radius: 2, y: 1.5)
                        .frame(width: capWidth, height: 28)
                        .offset(x: activePosition * travel)
                        .frame(maxHeight: .infinity, alignment: .center)
                }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let next = AppearanceSwitchMapping.appearance(
                                fromPosition: (value.location.x - capWidth / 2) / travel)
                            select(next)
                        }
                )
            }
            .frame(height: Theme.Size.minimumTouch)

            // Detent labels with panel lettering and LED dots
            HStack(spacing: 0) {
                ForEach(AppearanceSwitchMapping.positions) { appearance in
                    let isSelected = settings.appearance == appearance
                    Button {
                        select(appearance)
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(isSelected ? Theme.orange : Theme.ledOff)
                                .frame(width: 5, height: 5)
                                .shadow(color: isSelected ? Theme.orange.opacity(0.8) : .clear, radius: 2)
                            Text(settings.localized(appearance == .system ? "home.appearance.auto" : appearance.title).uppercased())
                                .font(Theme.padTitle(size: 13))
                                .tracking(1.2)
                                .foregroundStyle(isSelected ? Theme.ink : Theme.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.minimumTouch)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Panel caption
            Text(settings.localized("Appearance").uppercased())
                .font(Theme.padTitle(size: 11))
                .tracking(1.2)
                .foregroundStyle(Theme.secondary)
        }
        .frame(height: 144)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(settings.localized("Appearance"))
        .accessibilityValue(settings.localized(settings.appearance == .system ? "home.appearance.auto" : settings.appearance.title))
        .accessibilityAdjustableAction { direction in
            let current = AppearanceSwitchMapping.position(for: settings.appearance)
            switch direction {
            case .increment: select(AppearanceSwitchMapping.appearance(fromPosition: current + 0.5))
            case .decrement: select(AppearanceSwitchMapping.appearance(fromPosition: current - 0.5))
            @unknown default: break
            }
        }
    }

    private func select(_ appearance: AppAppearance) {
        guard settings.appearance != appearance else { return }
        settings.appearance = appearance
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
