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
