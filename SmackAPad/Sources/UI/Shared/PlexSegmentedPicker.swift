import SwiftUI

enum PlexSegmentedPickerSize {
    case regular
    case compact

    var controlHeight: CGFloat {
        switch self {
        case .regular: return 40
        case .compact: return 32
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .regular: return 15
        case .compact: return 13
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .regular: return 14
        case .compact: return 10
        }
    }

    var trackPadding: CGFloat { 3 }
}

/// Hardware segmented control with recessed track and 6pt studio segments (DESIGN.md).
struct PlexSegmentedPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(Value, String)]
    var fitsColumn = false
    var size: PlexSegmentedPickerSize = .regular

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduced

    var body: some View {
        Group {
            if fitsColumn {
                segmentTrack(equalWidth: true)
                    .frame(maxWidth: .infinity)
            } else {
                ViewThatFits(in: .horizontal) {
                    segmentTrack(equalWidth: false)
                        .fixedSize(horizontal: true, vertical: false)
                    ScrollView(.horizontal) {
                        segmentTrack(equalWidth: false)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }

    private func segmentTrack(equalWidth: Bool) -> some View {
        let trackShape = RoundedRectangle(cornerRadius: Theme.Radius.control + 2)
        return HStack(spacing: 2) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                segmentButton(value: option.0, label: option.1, equalWidth: equalWidth)
            }
        }
        .padding(size.trackPadding)
        .background {
            trackShape
                .fill(Theme.recessed)
                .overlay {
                    trackShape.strokeBorder(Theme.hairline, lineWidth: 1)
                }
        }
        .opacity(isEnabled ? 1 : 0.45)
    }

    private func segmentButton(value: Value, label: String, equalWidth: Bool) -> some View {
        let isSelected = selection == value
        let segmentShape = RoundedRectangle(cornerRadius: Theme.Radius.control)
        let policy = Theme.Motion.Policy(reduced: reduced)

        return Button {
            guard selection != value else { return }
            withAnimation(policy.animation(Theme.Motion.fast)) {
                selection = value
            }
        } label: {
            Text(label)
                .font(isSelected ? Theme.strong(size.fontSize) : Theme.text(size.fontSize))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isSelected ? Theme.ink : Theme.secondary)
                .padding(.horizontal, size.horizontalPadding)
                .frame(maxWidth: equalWidth ? .infinity : nil)
                .frame(minHeight: size.controlHeight)
                .background {
                    if isSelected {
                        segmentShape
                            .fill(Theme.surfaceElevated)
                            .overlay {
                                segmentShape.strokeBorder(Theme.accent, lineWidth: 1.5)
                            }
                            .shadow(color: Theme.accentGlow.opacity(0.6), radius: 3)
                    }
                }
                .contentShape(segmentShape)
        }
        .buttonStyle(.plain)
        .frame(minHeight: Theme.Size.minimumTouch)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
