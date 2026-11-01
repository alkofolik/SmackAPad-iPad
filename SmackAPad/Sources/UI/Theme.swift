import SwiftUI
import UIKit

/// Orange carries the score; black and white carry hand and hierarchy.
/// Both typefaces are supplied by iPadOS. No font files are redistributed.
enum Theme {
    static let orange = Color(red: 1, green: 107.0 / 255, blue: 0)
    static let black = Color.black
    /// Result marks on the orange band: correct, off the beat, wrong or missed.
    static let markCorrect = Color(red: 0.04, green: 0.34, blue: 0.15)
    static let markOff = Color(red: 0.36, green: 0.26, blue: 0)
    static let markWrong = Color(red: 0.62, green: 0.06, blue: 0.10)
    static let white = Color.white
    static let background = adaptive(light: .white, dark: .black)
    static let ink = adaptive(light: .black, dark: .white)
    static let secondary = adaptive(light: UIColor(white: 0.35, alpha: 1), dark: UIColor(white: 0.7, alpha: 1))
    static let surface = adaptive(light: UIColor(white: 0.94, alpha: 1), dark: UIColor(white: 0.09, alpha: 1))

    // Five roles for screen chrome. Pattern notation keeps its fixed canvas sizes.
    static let screenTitle = display(28)
    static let sectionTitle = display(22)
    static let rowTitle = display(18)
    static let meta = text(13)
    static let control = text(16)

    enum Space {
        static let tight: CGFloat = 4
        static let small: CGFloat = 8
        static let regular: CGFloat = 16
        static let page: CGFloat = 24
        static let wide: CGFloat = 32
    }

    enum Size {
        static let touch: CGFloat = 48
        static let control: CGFloat = 72
        static let transportWidth: CGFloat = 380
        static let border: CGFloat = 2
        static let bracket: CGFloat = 6
        static let blockRadius: CGFloat = 3
        static let panelRadius: CGFloat = 0
        static let title: CGFloat = 28
        static let emphasis: CGFloat = 24
        static let listTitle: CGFloat = 22
        static let beat: CGFloat = 32
        static let body: CGFloat = 18
        static let small: CGFloat = 16
        static let dense: CGFloat = 13
    }

    static func display(_ size: CGFloat = Size.title) -> Font {
        .custom("AvenirNext-Heavy", size: size, relativeTo: .headline)
    }

    static func text(_ size: CGFloat = Size.body) -> Font {
        .custom("Menlo-Regular", size: size, relativeTo: .body)
    }

    static func canvasDisplay(_ size: CGFloat) -> Font { .custom("AvenirNext-Heavy", fixedSize: size) }
    static func canvasText(_ size: CGFloat) -> Font { .custom("Menlo-Regular", fixedSize: size) }

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

extension Theme {
    enum Motion {
        static let fast = Animation.easeOut(duration: 0.15)
        static let standard = Animation.easeOut(duration: 0.25)
        static let emphasis = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let rise: CGFloat = 6
        static let starStagger = Duration.milliseconds(80)

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
            content
                .allowsHitTesting(lesson == nil)
                .accessibilityHidden(lesson != nil)
                .overlay {
                    if let lesson {
                        destination(lesson)
                            .environment(\.dismissLesson, { self.lesson = nil })
                            .transition(Theme.Motion.Policy(reduced: reduced).navigation)
                            .zIndex(1)
                    }
                }
                .motion(Theme.Motion.standard, value: lesson?.id)
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
}

/// A beat's animation is local to this label, never the clock-driven pattern.
struct CountInNumeral: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    let number: Int
    let size: CGFloat
    @State private var visible = false
    var body: some View {
        Text("\(number)").font(Theme.canvasDisplay(size)).foregroundStyle(Theme.black)
            .scaleEffect(Theme.Motion.Policy(reduced: reduced).scale(visible ? 1 : 1.15))
            .opacity(visible ? 1 : 0)
            .motion(Theme.Motion.fast, value: visible)
            .onAppear { visible = true }
    }
}
