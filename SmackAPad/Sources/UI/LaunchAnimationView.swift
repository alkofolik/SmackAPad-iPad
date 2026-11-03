import SwiftUI

/// Cold-start launch animation displaying the Smack-a-Pad logo and wordmark over the cream background.
/// Sequence:
/// - 0.00–0.45 s: three black pads appear one after another with scale/opacity pops (0.12 s apart).
/// - 0.55 s: orange pad smacks in from slightly above and larger, lands at 12° with one small overshoot;
///   three black pads give a tiny 2 pt bounce at impact.
/// - 0.95–1.25 s: wordmark fades and rises below the logo.
/// - Hold until 1.6 s, then fades out (0.25 s) revealing the library. Tap anywhere skips it.
/// - Reduce motion: complete logo with wordmark fades in (0.25 s), holds 0.6 s, fades out (0.25 s).
@MainActor
struct LaunchAnimationView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Sequence states (active only when reduceMotion is false)
    @State private var pad1Popped = false
    @State private var pad2Popped = false
    @State private var pad3Popped = false
    @State private var orangeVisible = false
    @State private var orangeLanded = false
    @State private var blackBounce: CGFloat = 0
    @State private var wordmarkVisible = false

    // Container opacity for fade in / fade out
    @State private var containerOpacity: Double = 1.0
    @State private var hasFinished = false
    @State private var animationTask: Task<Void, Never>?

    // Exact logo colours from docs/design/2026-11-03-logo-source/
    private static let cream = Color(red: 242 / 255.0, green: 240 / 255.0, blue: 234 / 255.0)
    private static let blackPad = Color(red: 17 / 255.0, green: 17 / 255.0, blue: 17 / 255.0)
    private static let orangePad = Color(red: 255 / 255.0, green: 91 / 255.0, blue: 31 / 255.0)

    var body: some View {
        GeometryReader { proxy in
            let shorterSide = min(proxy.size.width, proxy.size.height)
            let logoSize = shorterSide * 0.28
            let wordmarkWidth = logoSize * 1.12
            let spacing = logoSize * 0.12

            ZStack {
                Self.cream
                    .ignoresSafeArea()

                VStack(spacing: spacing) {
                    logoView(size: logoSize)
                    wordmarkView(width: wordmarkWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .opacity(containerOpacity)
            .contentShape(Rectangle())
            .onTapGesture {
                skip()
            }
        }
        .task {
            startAnimation()
        }
    }

    // MARK: - Logo View

    @ViewBuilder
    private func logoView(size: CGFloat) -> some View {
        let unit = size / 100.0
        let padDimension = 32.0 * unit
        let cornerRadius = 3.0 * unit

        ZStack {
            // Three black pads with impact bounce
            ZStack {
                // Top-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Self.blackPad)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad1Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad1Popped ? 1.0 : 0.0))
                    .position(x: 30 * unit, y: 34 * unit)

                // Bottom-left
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Self.blackPad)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad2Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad2Popped ? 1.0 : 0.0))
                    .position(x: 30 * unit, y: 74 * unit)

                // Bottom-right
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Self.blackPad)
                    .frame(width: padDimension, height: padDimension)
                    .scaleEffect(reduceMotion ? 1.0 : (pad3Popped ? 1.0 : 0.4))
                    .opacity(reduceMotion ? 1.0 : (pad3Popped ? 1.0 : 0.0))
                    .position(x: 70 * unit, y: 74 * unit)
            }
            .frame(width: size, height: size)
            .offset(y: reduceMotion ? 0 : blackBounce)

            // Top-right orange pad
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Self.orangePad)
                .frame(width: padDimension, height: padDimension)
                .scaleEffect(reduceMotion ? 1.0 : (orangeLanded ? 1.0 : 1.35))
                .rotationEffect(.degrees(reduceMotion ? 12.0 : (orangeLanded ? 12.0 : 0.0)))
                .offset(y: reduceMotion ? 0 : (orangeLanded ? 0 : -36 * unit))
                .opacity(reduceMotion ? 1.0 : (orangeVisible ? 1.0 : 0.0))
                .position(x: 73 * unit, y: 27 * unit)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Wordmark View

    @ViewBuilder
    private func wordmarkView(width: CGFloat) -> some View {
        Image("LaunchWordmark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Self.blackPad)
            .frame(width: width)
            .offset(y: reduceMotion ? 0 : (wordmarkVisible ? 0 : 8))
            .opacity(reduceMotion ? 1.0 : (wordmarkVisible ? 1.0 : 0.0))
    }

    // MARK: - Animation Control

    private func startAnimation() {
        animationTask?.cancel()
        animationTask = Task { @MainActor in
            if reduceMotion {
                containerOpacity = 0.0
                withAnimation(.easeIn(duration: 0.25)) {
                    containerOpacity = 1.0
                }
                try? await Task.sleep(for: .milliseconds(250 + 600))
                guard !Task.isCancelled else { return }

                withAnimation(.easeOut(duration: 0.25)) {
                    containerOpacity = 0.0
                }
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }

                finishOnce()
            } else {
                containerOpacity = 1.0

                // 0.00–0.45 s: three black pads appear 0.12 s apart
                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                    pad1Popped = true
                }
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { return }

                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                    pad2Popped = true
                }
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { return }

                withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                    pad3Popped = true
                }
                // Wait until 0.55 s (elapsed: 240 ms -> sleep 310 ms)
                try? await Task.sleep(for: .milliseconds(310))
                guard !Task.isCancelled else { return }

                // 0.55 s: orange pad smacks in
                orangeVisible = true
                withAnimation(.spring(response: 0.28, dampingFraction: 0.54)) {
                    orangeLanded = true
                }

                // Impact at ~0.64 s: 2 pt bounce on black pads
                try? await Task.sleep(for: .milliseconds(90))
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.06)) {
                    blackBounce = 2
                }
                try? await Task.sleep(for: .milliseconds(60))
                guard !Task.isCancelled else { return }

                withAnimation(.easeOut(duration: 0.10)) {
                    blackBounce = 0
                }

                // Wait until 0.95 s (elapsed: 550 + 90 + 60 + 100 = 800 ms -> sleep 150 ms)
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }

                // 0.95–1.25 s: wordmark fades and rises
                withAnimation(.easeOut(duration: 0.30)) {
                    wordmarkVisible = true
                }

                // Hold until 1.60 s (elapsed: 950 + 300 = 1250 ms -> sleep 350 ms)
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }

                // 1.60 s: fade out
                withAnimation(.easeOut(duration: 0.25)) {
                    containerOpacity = 0.0
                }
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }

                finishOnce()
            }
        }
    }

    private func skip() {
        guard !hasFinished else { return }
        animationTask?.cancel()
        withAnimation(.easeOut(duration: 0.20)) {
            containerOpacity = 0.0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            finishOnce()
        }
    }

    private func finishOnce() {
        guard !hasFinished else { return }
        hasFinished = true
        onFinished()
    }
}
