//
//  TrainingScreen.swift
//  SmackAPad
//
//  Training screen presenting the Due card and spaced reviews (Ticket 98).
//

import SwiftUI

/// Training screen opened from Home pad 3.
/// Displays spaced review ("Due" card) and leaves room for Mix and Play after me.
@MainActor
public struct TrainingScreen: View {
    let onHome: () -> Void

    @Environment(StoreManager.self) private var store
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(ProgressionManager.self) private var progression
    @Environment(MIDIInput.self) private var midi
    @State private var lessonStore = LessonStore.shared
    @State private var selectedLesson: Lesson?
    @State private var mixLessonIDs: [Int] = []
    @State private var playingMix: [Lesson] = []
    @State private var showingMix = false
    @State private var mixFromMemory = false
    @AppStorage("smackapad.training.dailyMixes") private var dailyMixes = "{}"
    @Namespace private var lessonNamespace

    public init(onHome: @escaping () -> Void = {}) {
        self.onHome = onHome
    }

    private var today: String {
        AppCalendar.today()
    }

    private var dueLessons: [Lesson] {
        let ids = progress.dueLessonIds(today: today)
        return ids.compactMap { lessonStore.lesson(for: $0) }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Space.page) {
                    dueCard
                    mixCard
                    Spacer(minLength: Theme.Space.page)
                }
                .padding(Theme.Space.page)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(settings.localized("Training"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onHome) {
                        Text(settings.localized("Home"))
                            .font(Theme.control)
                            .frame(minHeight: Theme.Size.touch)
                    }
                }
            }
            .task(id: mixContext) { refreshMix() }
            .fullScreenCover(isPresented: $showingMix) {
                if let first = playingMix.first {
                    PracticeScreen(lesson: first, settings: settings, progress: progress, midi: midi,
                                   initialFromMemory: mixFromMemory, mixLessons: playingMix)
                }
            }
            .environment(\.lessonNamespace, lessonNamespace)
            .lessonPresentation(lesson: $selectedLesson, namespace: lessonNamespace) { lesson in
                PracticeScreen(
                    lesson: lesson,
                    settings: settings,
                    progress: progress,
                    midi: midi,
                    initialFromMemory: true,
                    initialBpm: lesson.targetBpm
                )
            }
        }
    }

    private var mixCandidates: [Lesson] {
        TrainingMix.candidates(lessons: progression.catalog.lessons, progress: progress.records,
            padCount: midi.activeProfile.padCount, openLessonIDs: openMixLessonIDs)
    }

    private var openMixLessonIDs: Set<Int> {
        Set(progression.catalog.lessons.filter { store.isUnlocked($0) && progression.isLessonOpen($0) }.map(\.id))
    }

    private var mixContext: String {
        "\(today):\(midi.activeProfile.padCount):" + mixCandidates.map(\.id).sorted().map(String.init).joined(separator: ",")
    }

    private var mixLessons: [Lesson] {
        mixLessonIDs.compactMap { id in mixCandidates.first { $0.id == id } }
    }

    private var mixCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            SectionHeader(title: settings.localized("Mix"))
            VStack(alignment: .leading, spacing: Theme.Space.regular) {
                ForEach(mixLessons) { lesson in
                    Text(settings.localized(lesson.title))
                        .font(Theme.rowTitle)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if mixLessons.count < 2 {
                    Text(settings.localized("Mix needs two lessons with two stars."))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }
                Toggle(settings.localized("From memory"), isOn: $mixFromMemory)
                    .font(Theme.control)
                    .tint(Theme.ink)
                    .frame(minHeight: Theme.Size.touch)
                    .disabled(mixLessons.count < 2)
                HStack(spacing: Theme.Space.regular) {
                    Button(settings.localized("Start")) {
                        playingMix = mixLessons
                        showingMix = true
                    }
                    .buttonStyle(InstrumentButtonStyle(filled: true, main: true))
                    Button(settings.localized("New mix")) { refreshMix(newDraw: true) }
                        .buttonStyle(InstrumentButtonStyle())
                }
                .disabled(mixLessons.count < 2)
            }
            .padding(Theme.Space.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .overlay(Rectangle().stroke(Theme.hairline, lineWidth: 1))
        }
    }

    private func refreshMix(newDraw: Bool = false) {
        let key = "\(today):\(midi.activeProfile.padCount)"
        var saved = (try? JSONDecoder().decode([String: [Int]].self, from: Data(dailyMixes.utf8))) ?? [:]
        let eligible = Set(mixCandidates.map(\.id))
        if !newDraw, let cached = saved[key], cached.count >= 2,
           cached.allSatisfy({ eligible.contains($0) }) {
            mixLessonIDs = cached
            return
        }
        func draw(_ seed: UInt64) -> [Int] {
            TrainingMix.select(lessons: progression.catalog.lessons, progress: progress.records,
                padCount: midi.activeProfile.padCount, openLessonIDs: openMixLessonIDs,
                day: today, draw: seed).map(\.id)
        }
        var chosen = draw(newDraw ? UInt64.random(in: 1...1_000_000) : 0)
        if newDraw, Set(chosen) == Set(mixLessonIDs) {
            // Prefer different members where possible; otherwise change the order.
            for seed in 1...50 {
                let alternative = draw(UInt64(seed))
                if Set(alternative) != Set(mixLessonIDs) { chosen = alternative; break }
            }
            if chosen == mixLessonIDs, let first = chosen.first {
                chosen = Array(chosen.dropFirst()) + [first]
            }
        }
        mixLessonIDs = chosen
        saved = saved.filter { $0.key.hasPrefix(today + ":") }
        saved[key] = chosen
        if let data = try? JSONEncoder().encode(saved), let json = String(data: data, encoding: .utf8) {
            dailyMixes = json
        }
    }

    private var dueCard: some View {
        VStack(alignment: .leading, spacing: Theme.Space.regular) {
            SectionHeader(title: settings.localized("Due"))

            VStack(spacing: 0) {
                if !progress.hasAnyMasteredLesson {
                    emptyCardText(settings.localized("Reviews start once a lesson has two stars."))
                } else if dueLessons.isEmpty {
                    let nextDateFormatted: String = {
                        if let nearest = progress.nearestDueDay(today: today) {
                            return formattedDate(from: nearest)
                        } else {
                            return "—"
                        }
                    }()
                    emptyCardText(settings.localized("Nothing to review today. Next: %@", nextDateFormatted))
                } else {
                    ForEach(Array(dueLessons.enumerated()), id: \.element.id) { index, lesson in
                        if index > 0 {
                            Rectangle()
                                .fill(Theme.hairline)
                                .frame(height: 1)
                        }
                        dueLessonRow(lesson)
                    }
                }
            }
            .background(Theme.surface)
            .overlay(
                Rectangle()
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
    }

    private func emptyCardText(_ text: String) -> some View {
        Text(text)
            .font(Theme.meta)
            .foregroundStyle(Theme.secondary)
            .padding(Theme.Space.regular)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dueLessonRow(_ lesson: Lesson) -> some View {
        let record = progress.progress(for: lesson.id)
        let step = (record?.reviewStep ?? 0) + 1

        return Button {
            selectedLesson = lesson
        } label: {
            HStack(spacing: Theme.Space.regular) {
                VStack(alignment: .leading, spacing: Theme.Space.tight) {
                    Text(settings.localized(lesson.title))
                        .font(Theme.rowTitle)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(settings.localized("Step %lld of 4", step))
                        .font(Theme.meta)
                        .foregroundStyle(Theme.secondary)
                }

                Spacer(minLength: Theme.Space.small)

                StarsView(record: record, lesson: lesson)
            }
            .padding(.horizontal, Theme.Space.regular)
            .frame(minHeight: Theme.Size.touch)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .lessonSource(lesson.id)
    }

    private func formattedDate(from dayString: String) -> String {
        let parts = dayString.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return dayString }
        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        guard let date = cal.date(from: components) else { return dayString }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settings.languagePreference.rawValue)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
