//
//  AppNavigation.swift
//  SmackAPad
//
//  Global navigation state managing top-level routes (Ticket 105).
//

import Foundation
import SwiftUI
import Observation

/// Global app navigation state managing top-level routes.
@Observable
@MainActor
public final class AppNavigation {
    public static let shared = AppNavigation()

    public var route: AppRoute = .home

    public init(route: AppRoute = .home) {
        self.route = route
    }

    public func openTraining() {
        route = .training
    }

    public func openHome() {
        route = .home
    }

    public func openLibrary(_ target: LibraryLaunchTarget = .none) {
        route = .library(target)
    }
}

/// One session setup for Library and Training.
enum LessonLaunch: Identifiable {
    case lesson(Lesson)
    case review(Lesson)
    case afterMe(Lesson)

    var lesson: Lesson {
        switch self {
        case .lesson(let lesson), .review(let lesson), .afterMe(let lesson):
            return lesson
        }
    }

    var id: Int { lesson.id }

    static func library(_ lesson: Lesson, progress: LessonProgress?, today: String) -> Self {
        progress?.reviewSchedule.isDueReview(on: today) == true ? .review(lesson) : .lesson(lesson)
    }

    var reviewTempo: Int? {
        if case .review(let lesson) = self { return lesson.targetBpm }
        return nil
    }
}

@MainActor
struct PracticeLessonDestination: View {
    let launch: LessonLaunch
    @Environment(SettingsManager.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(MIDIInput.self) private var midi

    var body: some View {
        switch launch {
        case .lesson(let lesson), .review(let lesson):
            PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi,
                           initialFromMemory: launch.reviewTempo != nil, initialBpm: launch.reviewTempo)
        case .afterMe(let lesson):
            PracticeScreen(lesson: lesson, settings: settings, progress: progress, midi: midi,
                           initialAfterMe: true)
        }
    }
}

private struct PracticeLessonPresentation: ViewModifier {
    @Binding var launch: LessonLaunch?
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        content.lessonPresentation(lesson: Binding(
            get: { launch?.lesson },
            set: { if $0 == nil { launch = nil } }
        ), namespace: namespace) { lesson in
            PracticeLessonDestination(launch: launch ?? .lesson(lesson))
        }
    }
}

extension View {
    func practiceLessonPresentation(launch: Binding<LessonLaunch?>, namespace: Namespace.ID) -> some View {
        modifier(PracticeLessonPresentation(launch: launch, namespace: namespace))
    }
}

/// Debug-only tap-to-presentation measurement, shared across the Home/Training boundary.
@MainActor
enum TrainingOpenMeasurement {
    #if DEBUG
    private static var started: TimeInterval?
    #endif

    static func begin() {
        #if DEBUG
        started = Date.timeIntervalSinceReferenceDate
        #endif
    }

    static func appeared() {
        #if DEBUG
        guard let started else { return }
        print(String(format: "[TrainingOpen] tap to shell %.1f ms", (Date.timeIntervalSinceReferenceDate - started) * 1000))
        self.started = nil
        #endif
    }
}
