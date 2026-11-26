import SwiftUI

/// Horizontal studio fader with recessed track, active accent fill, fader cap with center hairline,
/// and a monospaced value readout on the right (DESIGN.md).
struct HardwareSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var valueFormatter: ((Double) -> String)? = nil

    @Environment(\.isEnabled) private var isEnabled
    @State private var isDragging = false

    private var span: Double {
        max(0.0001, range.upperBound - range.lowerBound)
    }

    private var normalized: Double {
        min(1, max(0, (value - range.lowerBound) / span))
    }

    private var formattedValue: String {
        if let valueFormatter {
            return valueFormatter(value)
        }
        if let step, step < 1 {
            return String(format: "%.1f", value)
        }
        return "\(Int(value.rounded()))"
    }

    var body: some View {
        HStack(spacing: Theme.Space.controlGap) {
            GeometryReader { geo in
                let capWidth: CGFloat = 22
                let capHeight: CGFloat = 28
                let trackHeight: CGFloat = 8
                let usableWidth = max(1, geo.size.width - capWidth)
                let thumbX = usableWidth * normalized

                ZStack(alignment: .leading) {
                    // Recessed fader slot
                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                        .fill(Theme.recessed)
                        .frame(height: trackHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: Theme.Radius.control)
                                .strokeBorder(Theme.hairline, lineWidth: 1)
                        }

                    // Active orange trace
                    RoundedRectangle(cornerRadius: Theme.Radius.control)
                        .fill(Theme.accent)
                        .frame(width: max(trackHeight, thumbX + capWidth / 2), height: trackHeight)
                        .opacity(isEnabled ? 1 : 0.45)

                    // Fader cap with center hairline
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surfaceElevated)
                        .frame(width: capWidth, height: capHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(isDragging ? Theme.accent : Theme.hairline, lineWidth: isDragging ? 1.5 : 1)
                        }
                        .overlay {
                            Rectangle()
                                .fill(isDragging ? Theme.accent : Theme.ink)
                                .frame(width: 1.5, height: 14)
                        }
                        .shadow(color: Theme.black.opacity(0.18), radius: 2, y: 1)
                        .offset(x: thumbX)
                }
                .frame(height: Theme.Size.minimumTouch)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            guard isEnabled else { return }
                            isDragging = true
                            let fraction = min(1, max(0, (gesture.location.x - capWidth / 2) / usableWidth))
                            var updated = range.lowerBound + fraction * span
                            if let step, step > 0 {
                                updated = (updated / step).rounded() * step
                            }
                            value = min(range.upperBound, max(range.lowerBound, updated))
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: Theme.Size.minimumTouch)

            Text(formattedValue)
                .font(Theme.strong(14).monospacedDigit())
                .foregroundStyle(isEnabled ? Theme.ink : Theme.secondary)
                .frame(minWidth: 48, alignment: .trailing)
        }
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(formattedValue)
        .accessibilityAdjustableAction { direction in
            let delta = step ?? max(1, span / 20)
            switch direction {
            case .increment:
                value = min(range.upperBound, value + delta)
            case .decrement:
                value = max(range.lowerBound, value - delta)
            @unknown default:
                break
            }
        }
    }
}

/// 6pt-radius hardware toggle button with glowing/unlit orange LED dot (DESIGN.md).
struct HardwareToggle: View {
    let title: String?
    @Binding var isOn: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduced

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = title
        self._isOn = isOn
    }

    init(isOn: Binding<Bool>) {
        self.title = nil
        self._isOn = isOn
    }

    var body: some View {
        let policy = Theme.Motion.Policy(reduced: reduced)
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.control)

        Button {
            withAnimation(policy.animation(Theme.Motion.fast)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: Theme.Space.small) {
                Circle()
                    .fill(isOn ? Theme.accent : Theme.ledOff)
                    .frame(width: 8, height: 8)
                    .overlay {
                        Circle()
                            .strokeBorder(isOn ? Theme.accent : Theme.hairline, lineWidth: 0.5)
                    }
                    .shadow(color: isOn ? Theme.accentGlow : .clear, radius: isOn ? 5 : 0)

                if let title, !title.isEmpty {
                    Text(title)
                        .font(Theme.strong(14))
                        .foregroundStyle(isOn ? Theme.ink : Theme.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, title == nil ? 16 : 12)
            .frame(minWidth: 52, minHeight: 34)
            .background {
                shape
                    .fill(isOn ? Theme.activeFill : Theme.surfaceElevated)
                    .overlay {
                        shape.strokeBorder(isOn ? Theme.accent : Theme.hairline, lineWidth: isOn ? 1.5 : 1)
                    }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .frame(minWidth: Theme.Size.minimumTouch, minHeight: Theme.Size.minimumTouch)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
