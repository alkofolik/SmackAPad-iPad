import SwiftUI
import UIKit

/// Orange carries the score; black and white carry hand and hierarchy.
/// IBM Plex Sans and Barlow Condensed are bundled under the SIL Open Font License 1.1.
enum Theme {
    /// Base palette: cream white (#F4EFE6) and warm soft black (#1F1D1A).
    /// Adjust creamHex (or softBlackHex) here to tune warm/cool tone across the app.
    static let creamHex: UInt32 = 0xF4EFE6
    static let softBlackHex: UInt32 = 0x1F1D1A
    private static let creamWhite = UIColor(hex: creamHex)
    private static let softBlack = UIColor(hex: softBlackHex)
    private static let plateCreamTop = UIColor(hex: 0xECE5DC)
    private static let plateCreamBottom = UIColor(hex: 0xDDD5C8)
    private static let cavityBlack = UIColor(hex: 0x0C0B0A)

    static let orange = Color(red: 1, green: 107.0 / 255, blue: 0)
    static let cavity = Color(uiColor: cavityBlack)
    static let black = Color(uiColor: softBlack)
    /// Result marks on the orange band: correct, off the beat, wrong or missed.
    static let markCorrect = Color(red: 0.04, green: 0.34, blue: 0.15)
    static let markOff = Color(red: 0.36, green: 0.26, blue: 0)
    static let markWrong = Color(red: 0.62, green: 0.06, blue: 0.10)
    static let white = Color(uiColor: creamWhite)
    static let background = adaptive(light: creamWhite, dark: softBlack)
    static let ink = adaptive(light: softBlack, dark: creamWhite)
    static let secondary = adaptive(light: UIColor(hex: 0x5E5950), dark: UIColor(hex: 0xB3ADA2))
    static let surface = adaptive(light: UIColor(hex: 0xEBE5DA), dark: UIColor(hex: 0x2A2824))
    /// One hairline for every divider and outline in the chrome.
    static let hairline = ink.opacity(0.15)
    /// Two-tone bevel colours for Home pads (ticket 112, proposal A).
    static let padBevelTop = adaptive(
        light: creamWhite.withAlphaComponent(0.55),
        dark: creamWhite.withAlphaComponent(0.12)
    )
    static let padBevelBottom = adaptive(
        light: softBlack.withAlphaComponent(0.16),
        dark: softBlack.withAlphaComponent(0.45)
    )
    /// One fill for an active or selected control.
    static let activeFill = orange.opacity(0.24)
    /// Unified warm brick red / terracotta for destructive actions (ticket 133).
    static let destructive = adaptive(
        light: UIColor(hex: 0xC0392B),
        dark: UIColor(hex: 0xE74C3C)
    )
    /// 1 px outline for destructive controls (ticket 133).
    static let destructiveOutline = destructive.opacity(0.4)
    /// Inert unpowered matte fill for disabled controls (ticket 133).
    static let disabledFill = adaptive(
        light: UIColor(hex: 0xD6D0C4),
        dark: UIColor(hex: 0x201E1B)
    )
    /// Inactive LED / off segment colour.
    static let ledOff = starColor(for: 0)

    /// Star progression colours: not done grey, 1 star light orange, 2 stars medium orange, 3 stars full orange.
    static func starColor(for stars: Int) -> Color {
        switch stars {
        case 1, 2, 3:
            return orange
        default:
            return adaptive(
                light: UIColor(hex: 0xD6D0C4),
                dark: UIColor(hex: 0x3E3B36)
            )
        }
    }

    static let mainValue = strong(44)
    static let screenTitle = display(28)
    static let handoffTitle = boldDisplay(28)
    static let handoffNext = strong(20)
    static let stepTag = strong(12).monospaced()
    static let sectionTitle = display(22)
    static let rowTitle = display(22)
    static let meta = text(16)
    static let control = text(18)
    static let navigation = text(18)
    static let action = strong(22)


    enum Space {
        static let tight: CGFloat = 4
        static let small: CGFloat = 8
        /// Deliberate segmented control gap (ticket 167).
        static let segmentedGap: CGFloat = 8
        /// Minimum gap between adjacent tappable controls (ticket 167).
        static let controlGap: CGFloat = 12
        static let regular: CGFloat = 16
        static let page: CGFloat = 24
        static let handoff: CGFloat = 28
        static let wide: CGFloat = 32
    }

    enum Size {
        /// Compact row or button.
        static let row: CGFloat = 48     // same as touch
        /// Large row or primary button.
        static let rowLarge: CGFloat = 56
        /// Two-line list row (lesson rows).
        static let listRow: CGFloat = 60

        static let minimumTouch: CGFloat = 44
        static let touch: CGFloat = 48
        static let control: CGFloat = 72
        static let transportWidth: CGFloat = 420
        static let border: CGFloat = 2
        static let bracket: CGFloat = 6
        static let title: CGFloat = 32
        static let emphasis: CGFloat = 24
        static let listTitle: CGFloat = 28
        static let beat: CGFloat = 32
        static let body: CGFloat = 22
        static let small: CGFloat = 20
        static let dense: CGFloat = 20
    }

    enum Radius {
        /// Home pad radius (Akai MPC Tactile Rubber style, ticket 112).
        static let pad: CGFloat = 8
        /// Button & control radius (Variant B studio precision, ticket 133).
        static let button: CGFloat = 6
        /// Controller plate at the reference pad size; scaled with the Home grid.
        static let controllerPlate: CGFloat = 16
    }

    /// Home-only material tints from the controller preview (ticket 119).
    enum HomeController {
        static let bodyTop = adaptive(light: UIColor(hex: 0xF5EFE5), dark: UIColor(hex: 0x24221E))
        static let bodyBottom = adaptive(light: UIColor(hex: 0xE8E0D2), dark: UIColor(hex: 0x171513))
        static let ribLight = adaptive(light: creamWhite.withAlphaComponent(0.55), dark: creamWhite.withAlphaComponent(0.06))
        static let ribShadow = adaptive(light: softBlack.withAlphaComponent(0.08), dark: softBlack.withAlphaComponent(0.45))
        static let plateTop = adaptive(light: UIColor(hex: 0xE6DFD4), dark: UIColor(hex: 0x2C2924))
        static let plateShade = adaptive(light: UIColor(hex: 0xD5CDC0), dark: UIColor(hex: 0x1D1B18))
        static let plateLight = adaptive(light: plateCreamTop, dark: UIColor(hex: 0x312E28))
        static let plateBottom = adaptive(light: plateCreamBottom, dark: UIColor(hex: 0x201E1B))
        static let screwTop = adaptive(light: creamWhite, dark: UIColor(hex: 0x555047))
        static let screwMiddle = adaptive(light: UIColor(hex: 0xDCD6CA), dark: UIColor(hex: 0x32302B))
        static let screwShade = adaptive(light: UIColor(hex: 0xACA597), dark: UIColor(hex: 0x1E1C19))
        static let screwBottom = adaptive(light: UIColor(hex: 0x7E786B), dark: UIColor(hex: 0x100F0E))
        static let slot = adaptive(light: UIColor(hex: 0x1A1816), dark: cavityBlack)
        static let capTop = adaptive(light: UIColor(hex: 0xF3ECE2), dark: UIColor(hex: 0x3A3731))
        static let capMiddle = adaptive(light: UIColor(hex: 0xD7D0C5), dark: UIColor(hex: 0x262420))
        static let capShade = adaptive(light: UIColor(hex: 0xC5BEB2), dark: UIColor(hex: 0x1D1C18))
        static let capBottom = adaptive(light: UIColor(hex: 0xDFD8CC), dark: UIColor(hex: 0x2F2C26))
    }

    /// Opt-in materials for non-Home screens. Geometry belongs to each caller.
    enum Skin {
        enum Chassis {
            static let top = HomeController.bodyTop
            static let bottom = HomeController.bodyBottom
            static let angle: Double = 175
            static let ribPitch: CGFloat = 4
            static let ribOpacity: Double = 0.05
        }

        enum Plate {
            static let top = adaptive(light: plateCreamTop, dark: UIColor(hex: 0x272521))
            static let bottom = adaptive(light: plateCreamBottom, dark: UIColor(hex: 0x1E1C19))
            static let angle: Double = 165
            static let radius = Radius.controllerPlate
            static let bevel: CGFloat = 1.5
            static let highlight = adaptive(light: creamWhite.withAlphaComponent(0.85), dark: creamWhite.withAlphaComponent(0.24))
            static let shade = adaptive(light: softBlack.withAlphaComponent(0.2), dark: softBlack.withAlphaComponent(0.7))
            static let shadow = adaptive(light: softBlack.withAlphaComponent(0.09), dark: softBlack.withAlphaComponent(0.55))
            static let contactShadow = adaptive(light: softBlack.withAlphaComponent(0.06), dark: softBlack.withAlphaComponent(0.35))
            static let shadowRadius: CGFloat = 12
            static let shadowY: CGFloat = 6
            static let contactRadius: CGFloat = 1.5
            static let contactY: CGFloat = 1
        }

        enum Pad {
            static let radius = Radius.button
            static let fill = surface
            static let highlight = padBevelTop
            static let shade = padBevelBottom
            static let heroHighlight = white.opacity(0.42)
            static let heroShade = black.opacity(0.28)
            static let topBevel: CGFloat = 1.5
            static let bottomBevel: CGFloat = 2
            static let heroBottomBevel: CGFloat = 2.5
            static let pressedScale: CGFloat = 0.97
            static let pressedY: CGFloat = 1.0
            static let flashOpacity: Double = 0.25
            static let reducedPressOpacity: Double = 0.12
        }

        enum Display {
            static let fill = Color(uiColor: UIColor(hex: 0x151412))
            static let ink = white
            static let secondary = adaptive(light: UIColor(hex: 0xA59E92), dark: UIColor(hex: 0xB3ADA2))
            static let glassTop = adaptive(light: creamWhite.withAlphaComponent(0.08), dark: creamWhite.withAlphaComponent(0.04))
            static let glassBottom = adaptive(light: softBlack.withAlphaComponent(0.2), dark: softBlack.withAlphaComponent(0.3))
            static let shadow = Color(uiColor: cavityBlack).opacity(0.85)
            static let shadowRadius: CGFloat = 4
            static let shadowY: CGFloat = 3
        }

        enum LightBar {
            static let height: CGFloat = 2
            static let glowRadius: CGFloat = 3
            static let glow = orange.opacity(0.8)
        }

        /// CSS angles: 0° points up, 90° points right, 180° points down.
        static func gradient(_ colors: [Color], degrees: Double) -> LinearGradient {
            let radians = degrees * .pi / 180
            let x = sin(radians) / 2
            let y = -cos(radians) / 2
            return LinearGradient(colors: colors,
                                  startPoint: UnitPoint(x: 0.5 - x, y: 0.5 - y),
                                  endPoint: UnitPoint(x: 0.5 + x, y: 0.5 + y))
        }
    }

    static func display(_ size: CGFloat = Size.title) -> Font {
        _ = verifiedFonts
        return .custom("IBMPlexSans-Medium", size: size, relativeTo: .headline)
    }

    /// Bold display heading matching handoff and end screen typography.
    static func boldDisplay(_ size: CGFloat = Size.listTitle) -> Font {
        _ = verifiedFonts
        return .custom("IBMPlexSans-Bold", size: size, relativeTo: .title)
    }

    /// The one key figure and the primary action label.
    static func strong(_ size: CGFloat) -> Font {
        _ = verifiedFonts
        return .custom("IBMPlexSans-SemiBold", size: size, relativeTo: .headline)
    }

    static func text(_ size: CGFloat = Size.body) -> Font {
        _ = verifiedFonts
        return .custom("IBMPlexSans-Regular", size: size, relativeTo: .body)
    }

    // Callers scale the notation together with its geometry, never to fit a cell.
    static func canvasDisplay(_ size: CGFloat) -> Font {
        _ = verifiedFonts
        return .custom("IBMPlexSans-Bold", fixedSize: size)
    }
    static func canvasText(_ size: CGFloat) -> Font {
        _ = verifiedFonts
        return .custom("IBMPlexSans-Regular", fixedSize: size)
    }

    /// Barlow Condensed ExtraBold pad title font for the Home screen action pads (ticket 140).
    static func padTitle(size: CGFloat) -> Font {
        _ = verifiedFonts
        return .custom("BarlowCondensed-ExtraBold", size: size, relativeTo: .headline)
    }

    /// Fixed-size Barlow Condensed ExtraBold variant for geometric layouts.
    static func canvasPadTitle(size: CGFloat) -> Font {
        _ = verifiedFonts
        return .custom("BarlowCondensed-ExtraBold", fixedSize: size)
    }

    private static let verifiedFonts: Void = {
        for name in ["IBMPlexSans-Regular", "IBMPlexSans-Medium", "IBMPlexSans-SemiBold", "IBMPlexSans-Bold"] {
            precondition(UIFont(name: name, size: 32)?.familyName == "IBM Plex Sans",
                         "Missing bundled IBM Plex Sans face: \(name)")
        }
        precondition(UIFont(name: "BarlowCondensed-ExtraBold", size: 32) != nil,
                     "Missing bundled Barlow Condensed face: BarlowCondensed-ExtraBold")
        #if DEBUG
        assert(UIFont.familyNames.contains("IBM Plex Sans"))
        print("Typography: IBM Plex Sans loaded — \(UIFont.fontNames(forFamilyName: "IBM Plex Sans"))")
        print("Typography: Barlow Condensed loaded — \(UIFont(name: "BarlowCondensed-ExtraBold", size: 32)?.fontName ?? "")")
        #endif
    }()

    /// Retain translated legacy keys while removing all-capital section labels.
    static func sentenceCase(_ text: String) -> String {
        guard text == text.uppercased() else { return text }
        var result = text.lowercased()
        for abbreviation in ["MIDI", "BPM", "USB", "CC"] {
            result = result.replacingOccurrences(of: "\\b\(abbreviation.lowercased())\\b",
                with: abbreviation, options: .regularExpression)
        }
        if let first = result.firstIndex(where: { $0.isLetter }) {
            result.replaceSubrange(first...first, with: String(result[first]).uppercased())
        }
        return result
    }

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    convenience init(hex string: String, alpha: CGFloat = 1.0) {
        let clean = string.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        self.init(hex: UInt32(int), alpha: alpha)
    }
}

extension AppAppearance {
    public var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }

    @MainActor
    public func applyToWindows() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = userInterfaceStyle
            }
        }
    }
}

extension Theme {
    enum Motion {
        static let fast = Animation.easeOut(duration: 0.15)
        static let standard = Animation.easeOut(duration: 0.25)
        static let emphasis = Animation.easeOut(duration: 0.4)
        static let rise: CGFloat = 6
        static let starStagger = Duration.milliseconds(80)

        /// Home pad tactile strike motion tokens (ticket 112, 133).
        static let padPress = Animation.spring(response: 0.18, dampingFraction: 0.7)
        static let padFlash = Animation.easeOut(duration: 0.12)
        static let ledBreath = Animation.easeInOut(duration: 1.6).repeatForever(autoreverses: true)
        static let bootStagger = Duration.milliseconds(40)

        /// App transitions motion tokens (ticket 113).
        static let padZoom = Animation.spring(response: 0.28, dampingFraction: 0.82)
        static let padDismiss = Animation.easeOut(duration: 0.22)
        static let cardStep = Animation.easeOut(duration: 0.24)
        static let cardStepRise: CGFloat = 20

        /// All accessibility decisions live here, including geometry and text effects.
        struct Policy {
            let reduced: Bool
            var opacityOnly: Bool { reduced }
            func animation(_ proposed: Animation) -> Animation { reduced ? fast : proposed }
            func scale(_ proposed: CGFloat) -> CGFloat { reduced ? 1 : proposed }
            func offset(_ proposed: CGFloat) -> CGFloat { reduced ? 0 : proposed }
            func angle(_ proposed: Double) -> Angle { .degrees(reduced ? 0 : proposed) }
            var numeric: ContentTransition { reduced ? .opacity : .numericText() }
            var transition: AnyTransition {
                reduced ? .opacity : .opacity.combined(with: .offset(y: rise))
            }
            var navigation: AnyTransition {
                reduced ? .opacity : .opacity.combined(with: .scale(scale: 0.98))
            }
            var summary: AnyTransition {
                reduced ? .opacity : .opacity.combined(with: .move(edge: .bottom))
            }
            func breathingOpacity(animating: Bool) -> Double {
                reduced ? 1.0 : (animating ? 1.0 : 0.45)
            }
            var cardStep: AnyTransition {
                reduced
                    ? .opacity
                    : .asymmetric(
                        insertion: .opacity.combined(with: .offset(y: cardStepRise)),
                        removal: .opacity
                    )
            }
        }

        static func newStars(before: [Bool], after: [Bool]) -> Set<Int> {
            Set(after.indices.filter { after[$0] && !(before.indices.contains($0) && before[$0]) })
        }
    }
}

private struct MotionModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduced
    let animation: Animation
    let value: Value
    @State private var visible = true
    @ViewBuilder func body(content: Content) -> some View {
        if Theme.Motion.Policy(reduced: reduced).opacityOnly {
            content
                // A fast animation alone would still interpolate widths and positions.
                .transaction { $0.animation = nil }
                .opacity(visible ? 1 : 0)
                .animation(Theme.Motion.fast, value: visible)
                .task(id: value) {
                    visible = false
                    await Task.yield()
                    guard !Task.isCancelled else { return }
                    visible = true
                }
        } else {
            content.animation(animation, value: value)
        }
    }
}

extension View {
    func motion<Value: Equatable>(_ animation: Animation = Theme.Motion.fast, value: Value) -> some View {
        modifier(MotionModifier(animation: animation, value: value))
    }
}

private struct LessonNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}
private struct ConsumeReturnedStarsKey: EnvironmentKey {
    static let defaultValue: (Int) -> Set<Int> = { _ in [] }
}
private struct ReturnedStarsKey: EnvironmentKey {
    static let defaultValue: [Int: Set<Int>] = [:]
}
extension EnvironmentValues {
    var lessonNamespace: Namespace.ID? {
        get { self[LessonNamespaceKey.self] }
        set { self[LessonNamespaceKey.self] = newValue }
    }
    var consumeReturnedStars: (Int) -> Set<Int> {
        get { self[ConsumeReturnedStarsKey.self] }
        set { self[ConsumeReturnedStarsKey.self] = newValue }
    }
    var returnedStars: [Int: Set<Int>] {
        get { self[ReturnedStarsKey.self] }
        set { self[ReturnedStarsKey.self] = newValue }
    }
}

private struct LessonSource: ViewModifier {
    @Environment(\.lessonNamespace) private var namespace
    let id: Int
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, *), let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else { content }
    }
}

/// Generic source pad modifier for iOS 18 zoom navigation transition.
public struct PadZoomSource<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID?

    public init(id: ID, namespace: Namespace.ID?) {
        self.id = id
        self.namespace = namespace
    }

    @ViewBuilder public func body(content: Content) -> some View {
        if #available(iOS 18, *), let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// The iOS 17 overlay avoids the system cover's slide and supports reverse fading.
private struct LessonPresentation<Destination: View>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Binding var lesson: Lesson?
    let namespace: Namespace.ID
    let destination: (Lesson) -> Destination
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 18, *), !Theme.Motion.Policy(reduced: reduced).opacityOnly {
            content.fullScreenCover(item: $lesson) { item in
                destination(item).navigationTransition(.zoom(sourceID: item.id, in: namespace))
            }
        } else {
            let policy = Theme.Motion.Policy(reduced: reduced)
            content
                .allowsHitTesting(lesson == nil)
                .accessibilityHidden(lesson != nil)
                .overlay {
                    if let lesson {
                        destination(lesson)
                            .environment(\.dismissLesson, { self.lesson = nil })
                            .transition(policy.navigation)
                            .zIndex(1)
                    }
                }
                .animation(policy.animation(lesson != nil ? Theme.Motion.padZoom : Theme.Motion.padDismiss), value: lesson != nil)
        }
    }
}

/// Generic pad zoom presentation: iOS 18 native zoom from pad, iOS 17 fallback fade + scale 0.98.
/// Reduce Motion: pure opacity change of <= 0.2 s (Theme.Motion.fast: 0.15 s).
public struct PadPresentation<Item: Identifiable & Equatable, Destination: View>: ViewModifier where Item.ID: Hashable {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @Binding var item: Item?
    let namespace: Namespace.ID
    let destination: (Item) -> Destination

    public init(item: Binding<Item?>, namespace: Namespace.ID, @ViewBuilder destination: @escaping (Item) -> Destination) {
        self._item = item
        self.namespace = namespace
        self.destination = destination
    }

    @ViewBuilder public func body(content: Content) -> some View {
        if #available(iOS 18, *), !Theme.Motion.Policy(reduced: reduced).opacityOnly {
            content.fullScreenCover(item: $item) { currentItem in
                destination(currentItem)
                    .navigationTransition(.zoom(sourceID: currentItem.id, in: namespace))
            }
        } else {
            let policy = Theme.Motion.Policy(reduced: reduced)
            content
                .allowsHitTesting(item == nil)
                .accessibilityHidden(item != nil)
                .overlay {
                    if let item {
                        destination(item)
                            .transition(policy.navigation)
                            .zIndex(1)
                    }
                }
                .animation(policy.animation(item != nil ? Theme.Motion.padZoom : Theme.Motion.padDismiss), value: item != nil)
        }
    }
}

private struct DismissLessonKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}
extension EnvironmentValues {
    var dismissLesson: (() -> Void)? {
        get { self[DismissLessonKey.self] }
        set { self[DismissLessonKey.self] = newValue }
    }
}
extension View {
    func lessonSource(_ id: Int) -> some View { modifier(LessonSource(id: id)) }
    func lessonPresentation<Destination: View>(lesson: Binding<Lesson?>, namespace: Namespace.ID,
                                               @ViewBuilder destination: @escaping (Lesson) -> Destination) -> some View {
        modifier(LessonPresentation(lesson: lesson, namespace: namespace, destination: destination))
    }
    public func padSource<ID: Hashable>(_ id: ID, in namespace: Namespace.ID?) -> some View {
        modifier(PadZoomSource(id: id, namespace: namespace))
    }
    public func padPresentation<Item: Identifiable & Equatable, Destination: View>(
        item: Binding<Item?>,
        namespace: Namespace.ID,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View where Item.ID: Hashable {
        modifier(PadPresentation(item: item, namespace: namespace, destination: destination))
    }
}

/// A beat's animation is local to this label, never the clock-driven pattern.
struct CountInNumeral: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    let number: Int
    let size: CGFloat
    @State private var visible = false
    var body: some View {
        Text("\(number)").font(Theme.canvasDisplay(size)).monospacedDigit().foregroundStyle(Theme.black)
            .scaleEffect(Theme.Motion.Policy(reduced: reduced).scale(visible ? 1 : 1.15))
            .opacity(visible ? 1 : 0)
            .motion(Theme.Motion.fast, value: visible)
            .onAppear { visible = true }
    }
}
