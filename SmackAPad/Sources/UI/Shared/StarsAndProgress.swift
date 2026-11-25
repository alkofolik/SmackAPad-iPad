import SwiftUI

/// A single glyph size for all three stars, including the requirements popover.
struct StarsView: View {
    @Environment(SettingsManager.self) private var settings
    let record: LessonProgress?
    var lesson: Lesson? = nil
    @State private var showingRequirements = false
    @Environment(\.returnedStars) private var returnedStars
    @Environment(\.consumeReturnedStars) private var consumeReturnedStars
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var popping: Set<Int> = []

    private var earned: [Bool] {
        [record?.passed ?? false, record?.mastery ?? false, record?.memory ?? false]
    }

    private var starCount: Int {
        earned.filter { $0 }.count
    }

    var body: some View {
        HStack(spacing: Theme.Space.tight) {
            if let lesson {
                Button { showingRequirements.toggle() } label: {
                    stars.padding(.horizontal, Theme.Space.tight)
                        .frame(minHeight: Theme.Size.touch).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Lesson stars"))

                Button { showingRequirements.toggle() } label: {
                    Image(systemName: "info.circle")
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                        .frame(minWidth: 28)
                        .textButtonTarget(alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.localized("Star requirements"))
                .popover(isPresented: $showingRequirements, arrowEdge: .trailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Space.regular) {
                            SectionHeader(title: settings.localized("Lesson stars"))
                            ForEach(0..<3, id: \.self) { index in
                                HStack(spacing: Theme.Space.small) {
                                    Image(systemName: earned[index] ? "star.fill" : "star")
                                        .font(Theme.control).frame(minWidth: 28, minHeight: 32)
                                        .foregroundStyle(earned[index] ? Theme.starColor(for: index + 1) : Theme.starColor(for: 0))
                                    Text(StarRequirement.requirementText(for: index, lesson: lesson,
                                        progress: record, padCount: settings.activeProfile().padCount, settings: settings))
                                        .font(Theme.control).fixedSize(horizontal: false, vertical: true)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(Theme.Space.page).frame(maxWidth: 380)
                        .foregroundStyle(Theme.ink).satinPlate()
                    }
                    .frame(idealWidth: 380, maxHeight: 560)
                }
            } else {
                stars
            }
        }
    }

    private var stars: some View {
        HStack(spacing: Theme.Space.small) {
            ForEach(0..<3, id: \.self) { index in
                star(index)
                    .scaleEffect(Theme.Motion.Policy(reduced: reduced).scale(popping.contains(index) ? 1.25 : 1))
                    .opacity(Theme.Motion.Policy(reduced: reduced).opacityOnly && popping.contains(index) ? 0.45 : 1)
                    .motion(Theme.Motion.emphasis, value: popping)
            }
        }
        .task(id: lesson.map { returnedStars[$0.id] ?? [] } ?? []) {
            guard let lesson else { return }
            let fresh = consumeReturnedStars(lesson.id)
            guard !fresh.isEmpty else { return }
            for index in fresh.sorted() {
                popping.insert(index)
                do { try await Task.sleep(for: Theme.Motion.starStagger) } catch { return }
            }
            do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
            popping = []
        }
    }

    private func star(_ index: Int) -> some View {
        let isEarned = earned[index]
        return Image(systemName: isEarned ? "star.fill" : "star")
            .font(Theme.control).frame(minWidth: 28, minHeight: 32)
            .foregroundStyle(isEarned ? Theme.starColor(for: starCount) : Theme.starColor(for: 0))
            .accessibilityLabel(settings.localized(StarRequirement.titleKeys[index]))
            .accessibilityValue(settings.localized(isEarned ? "On" : "Off"))
    }
}

struct ProgressLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduced
    @State private var appeared = false
    let threeStars: Int
    let twoStars: Int
    let oneStar: Int
    let total: Int

    init(threeStars: Int, twoStars: Int = 0, oneStar: Int = 0, total: Int) {
        self.threeStars = threeStars
        self.twoStars = twoStars
        self.oneStar = oneStar
        self.total = total
    }

    init(full: Int, partial: Int = 0, total: Int) {
        self.init(threeStars: full, twoStars: partial, oneStar: 0, total: total)
    }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let t = CGFloat(max(1, total))
            let factor = appeared || Theme.Motion.Policy(reduced: reduced).opacityOnly ? 1.0 : 0.0
            HStack(spacing: 0) {
                Rectangle().fill(Theme.starColor(for: 3))
                    .frame(width: w * CGFloat(threeStars) / t * factor)
                Rectangle().fill(Theme.starColor(for: 2))
                    .frame(width: w * CGFloat(twoStars) / t * factor)
                Rectangle().fill(Theme.starColor(for: 1))
                    .frame(width: w * CGFloat(oneStar) / t * factor)
                Spacer(minLength: 0)
            }
            .background(Theme.starColor(for: 0))
        }
        .frame(height: Theme.Size.border).accessibilityHidden(true)
        .onAppear { appeared = true }
        .motion(Theme.Motion.emphasis, value: appeared)
        .motion(Theme.Motion.emphasis, value: threeStars)
        .motion(Theme.Motion.emphasis, value: twoStars)
        .motion(Theme.Motion.emphasis, value: oneStar)
        .transaction { transaction in
            // Reduce Motion fades the completed line instead of interpolating its width.
            if Theme.Motion.Policy(reduced: reduced).opacityOnly { transaction.animation = nil }
        }
        .opacity(appeared ? 1 : 0)
        .motion(value: appeared)
    }
}

/// Retains an opening lock long enough to read it before it fades away.
struct AnimatedLock: View {
    let locked: Bool
    @State private var showing = false
    @State private var open = false
    var body: some View {
        Image(systemName: open ? "lock.open" : "lock")
            .contentTransition(.opacity)
            .opacity(locked || showing ? 1 : 0)
            .frame(width: locked || showing ? 16 : 0)
            .motion(value: open)
            .motion(value: showing)
            .onAppear { open = !locked }
            .task(id: locked) {
                if locked { open = false; showing = false }
                else {
                    showing = true; open = true
                    do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                    showing = false
                }
            }
            .accessibilityHidden(!locked)
    }
}
