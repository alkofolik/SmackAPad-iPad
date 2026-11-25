import SwiftUI
import UIKit

/// Native segmented controls ignore SwiftUI's custom font environment.
/// Keep the native control, but give both states real Plex faces and enough height.
struct PlexSegmentedPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(Value, String)]
    var fitsColumn = false
    @ScaledMetric(relativeTo: .body) private var pointSize: CGFloat = 24

    private var control: some View {
        PlexSegments(title: title, selection: $selection, options: options, pointSize: pointSize, fitsColumn: fitsColumn)
    }

    var body: some View {
        Group {
            if fitsColumn {
                control.frame(maxWidth: .infinity)
            } else {
                ViewThatFits(in: .horizontal) {
                    control.fixedSize()
                    ScrollView(.horizontal) { control.fixedSize() }
                        .fixedSize(horizontal: false, vertical: true)
                        .scrollIndicators(.hidden)
                        .scrollBounceBehavior(.basedOnSize)
                }
            }
        }
        .frame(minHeight: Theme.Size.touch)
    }
}

private final class PlexSegmentedControl: UISegmentedControl {
    var labelHeight: CGFloat = 48
    var fittedPointSize: CGFloat?

    override func layoutSubviews() {
        if let pointSize = fittedPointSize, bounds.width > 0 {
            let font = UIFont(name: "IBMPlexSans-Bold", size: pointSize)!
            let textWidth = (0..<numberOfSegments).reduce(CGFloat.zero) { width, index in
                width + ((titleForSegment(at: index) ?? "") as NSString).size(withAttributes: [.font: font]).width
            }
            let available = max(1, bounds.width - CGFloat(numberOfSegments) * 24)
            let size = pointSize * min(1, available / max(1, textWidth))
            let currentSize = (titleTextAttributes(for: .normal)?[.font] as? UIFont)?.pointSize
            if currentSize != size {
                setTitleTextAttributes([.font: UIFont(name: "IBMPlexSans-Regular", size: size)!], for: .normal)
                setTitleTextAttributes([.font: UIFont(name: "IBMPlexSans-Bold", size: size)!], for: .selected)
            }
        }
        super.layoutSubviews()
    }
    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: max(48, labelHeight))
    }
}

private struct PlexSegments<Value: Hashable>: UIViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    let title: String
    @Binding var selection: Value
    let options: [(Value, String)]
    let pointSize: CGFloat
    let fitsColumn: Bool

    final class Coordinator {
        var parent: PlexSegments
        init(_ parent: PlexSegments) { self.parent = parent }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PlexSegmentedControl {
        let control = PlexSegmentedControl(items: options.map(\.1))
        control.apportionsSegmentWidthsByContent = true
        let coordinator = context.coordinator
        control.addAction(UIAction { [weak control] _ in
            guard let control, coordinator.parent.options.indices.contains(control.selectedSegmentIndex) else { return }
            coordinator.parent.selection = coordinator.parent.options[control.selectedSegmentIndex].0
        }, for: .valueChanged)
        return control
    }

    func updateUIView(_ control: PlexSegmentedControl, context: Context) {
        context.coordinator.parent = self
        if control.numberOfSegments != options.count {
            control.removeAllSegments()
            for (index, option) in options.enumerated() {
                control.insertSegment(withTitle: option.1, at: index, animated: false)
            }
        } else {
            for (index, option) in options.enumerated() { control.setTitle(option.1, forSegmentAt: index) }
        }
        let regular = UIFont(name: "IBMPlexSans-Regular", size: pointSize)!
        let bold = UIFont(name: "IBMPlexSans-Bold", size: pointSize)!
        control.setTitleTextAttributes([.font: regular], for: .normal)
        control.setTitleTextAttributes([.font: bold], for: .selected)
        control.fittedPointSize = fitsColumn ? pointSize : nil
        control.setNeedsLayout()
        control.labelHeight = max(regular.lineHeight, bold.lineHeight) + 16
        control.selectedSegmentIndex = options.firstIndex { $0.0 == selection } ?? UISegmentedControl.noSegment
        control.isEnabled = isEnabled
        control.accessibilityLabel = title
        control.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PlexSegmentedControl, context: Context) -> CGSize? {
        let intrinsic = uiView.intrinsicContentSize
        return CGSize(width: fitsColumn ? (proposal.width ?? intrinsic.width) : intrinsic.width,
                      height: intrinsic.height)
    }
}
