//
//  Progression.swift
//  SmackAPad
//
//  Category unlock logic, progression rules, soft unlock, and 8-pad mode integration.
//

import Foundation
import Observation
import SwiftUI

// MARK: - Constants & Category Order

/// Progression constants specified in SPEC §3.7 and DECISIONS §15.
public enum ProgressionConstant {
    /// Number of passed lessons in the current category required to unlock the next category.
    public static let kLessonsToUnlock: Int = 5

    /// Key used to store manually (soft) unlocked category IDs in UserDefaults.
    public static let softUnlockedCategoriesStorageKey = "smackapad.settings.softUnlockedCategories"

    /// Category ID for introductory lessons.
    public static let introCategoryId = "intro"

    /// Default sequential category progression order.
    public static let defaultCategoryOrder: [String] = CategoryOrder.categories
}

/// Canonical category order for progression (SPEC §3.7).
public enum CategoryOrder {
    public static let categories: [String] = [
        "starter",
        "eighth",
        "sixteenth",
        "electronic",
        "ghost",
        "swing",
        "world",
        "fills"
    ]

    /// The very first category, unlocked by default.
    public static let initialUnlockedCategory: String = "starter"

    /// Returns the next category in progression order, or nil if already at the last category.
    public static func nextCategory(after category: String) -> String? {
        guard let index = categories.firstIndex(of: category), index + 1 < categories.count else {
            return nil
        }
        return categories[index + 1]
    }

    /// Returns the preceding category in progression order, or nil if at the first category.
    public static func previousCategory(before category: String) -> String? {
        guard let index = categories.firstIndex(of: category), index > 0 else {
            return nil
        }
        return categories[index - 1]
    }

    /// Returns whether the given category is in the sequential progression chain.
    public static func contains(_ category: String) -> Bool {
        categories.contains(category)
    }
}

// MARK: - Category Progression Status

/// Snapshot of a category's progression and unlock status.
public struct CategoryProgressionStatus: Equatable, Sendable, Identifiable {
    public var id: String { categoryId }
    public let categoryId: String
    public let title: String
    public let isUnlocked: Bool
    public let isSoftUnlocked: Bool
    public let passedCount: Int
    public let totalCount: Int
    public let requiredToUnlockNext: Int
    public let isNextCategoryUnlocked: Bool
    public let isFirstCategory: Bool
    public let isIntro: Bool

    public init(
        categoryId: String,
        title: String,
        isUnlocked: Bool,
        isSoftUnlocked: Bool,
        passedCount: Int,
        totalCount: Int,
        requiredToUnlockNext: Int = ProgressionConstant.kLessonsToUnlock,
        isNextCategoryUnlocked: Bool,
        isFirstCategory: Bool,
        isIntro: Bool = false
    ) {
        self.categoryId = categoryId
        self.title = title
        self.isUnlocked = isUnlocked
        self.isSoftUnlocked = isSoftUnlocked
        self.passedCount = passedCount
        self.totalCount = totalCount
        self.requiredToUnlockNext = requiredToUnlockNext
        self.isNextCategoryUnlocked = isNextCategoryUnlocked
        self.isFirstCategory = isFirstCategory
        self.isIntro = isIntro
    }
}

// MARK: - ProgressionManager

/// Observable manager for category unlock progression, soft unlocks, and lesson counts.
@Observable
public final class ProgressionManager: @unchecked Sendable {
    public static let shared = ProgressionManager()

    // MARK: Configuration

    /// Ordered categories participating in sequential progression.
    public let categoryOrder: [String]

    /// Threshold of passed lessons needed to unlock the next category.
    public let lessonsToUnlock: Int

    // MARK: State

    /// Categories manually unlocked by the user via soft unlock.
    public private(set) var softUnlockedCategories: Set<String> = []

    /// Pending category for soft-unlock confirmation dialog.
    public var categoryPendingSoftUnlock: String? = nil

    // MARK: Dependencies

    public let lessonStore: LessonStore
    public let progressStore: ProgressStore
    public let settingsManager: SettingsManager
    public let userDefaults: UserDefaults

    private let lock = NSRecursiveLock()

    // MARK: Initialization

    public init(
        lessonStore: LessonStore = .shared,
        progressStore: ProgressStore = .shared,
        settingsManager: SettingsManager = .shared,
        userDefaults: UserDefaults = .standard,
        lessonsToUnlock: Int = ProgressionConstant.kLessonsToUnlock,
        categoryOrder: [String] = CategoryOrder.categories
    ) {
        self.lessonStore = lessonStore
        self.progressStore = progressStore
        self.settingsManager = settingsManager
        self.userDefaults = userDefaults
        self.lessonsToUnlock = lessonsToUnlock
        self.categoryOrder = categoryOrder

        loadSoftUnlocks()
    }

    // MARK: - Canonical Category Mapping (Task 7)

    /// Resolves canonical progression category for a raw category identifier.
    /// Folds electronic-path subcategories (`hardgroove`, `broken-techno`, `uk-club`)
    /// and dance extensions into `"electronic"` (SPEC §3.7, DECISIONS §17).
    public static func canonicalCategory(forCategory cat: String) -> String {
        switch cat {
        case "hardgroove", "broken-techno", "uk-club", "jersey", "footwork":
            return "electronic"
        default:
            return cat
        }
    }

    /// Resolves canonical progression category for a lesson.
    public static func canonicalCategory(for lesson: Lesson) -> String {
        if lesson.tags.contains("electronic path") {
            return "electronic"
        }
        return canonicalCategory(forCategory: lesson.cat)
    }

    // MARK: - Intro Section (Task 6)

    /// Intro exercises are always accessible without any unlock requirements (SPEC §3.7, DECISIONS §16).
    public var isIntroAccessible: Bool {
        true
    }

    /// Returns whether the specified category identifier represents the intro section.
    public func isIntro(_ category: String) -> Bool {
        category == ProgressionConstant.introCategoryId
    }

    public func isIntro(category: String) -> Bool {
        isIntro(category)
    }

    // MARK: - Category Queries & Unlock Logic (Tasks 1, 2, 3, 5)

    /// Returns whether the specified category is unlocked.
    /// - Parameters:
    ///   - category: Category identifier.
    ///   - padCount: Optional pad count (8 or 16). Defaults to active controller profile pad count.
    public func isCategoryUnlocked(_ category: String, padCount: Int? = nil) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // Intro section is always accessible (Task 6)
        if isIntro(category: category) {
            return true
        }

        let canonical = Self.canonicalCategory(forCategory: category)

        // First category (starter) is always unlocked by default (Task 2)
        if canonical == (categoryOrder.first ?? CategoryOrder.initialUnlockedCategory) {
            return true
        }

        // Soft-unlocked categories are immediately unlocked (Task 4)
        if softUnlockedCategories.contains(canonical) || softUnlockedCategories.contains(category) {
            return true
        }

        guard let index = categoryOrder.firstIndex(of: canonical) else {
            // Unknown or external category: default to unlocked if not in progression chain
            return true
        }

        // Sequential unlock rule: index > 0 requires previous category to be unlocked AND
        // to have at least `lessonsToUnlock` passed eligible lessons (Task 3 & 5).
        let previousCategory = categoryOrder[index - 1]
        guard isCategoryUnlocked(previousCategory, padCount: padCount) else {
            return false
        }

        let passedInPrev = passedLessonCount(in: previousCategory, padCount: padCount)
        return passedInPrev >= lessonsToUnlock
    }

    /// Returns all lessons belonging to the category, folding electronic path lessons into `"electronic"`.
    public func lessons(in category: String) -> [Lesson] {
        let canonical = Self.canonicalCategory(forCategory: category)
        if canonical == "electronic" {
            // Direct electronic lessons + folded electronic path & extensions
            return lessonStore.lessons.filter { Self.canonicalCategory(for: $0) == "electronic" }
        }
        if isIntro(category: category) {
            return lessonStore.lessons.filter { $0.cat == ProgressionConstant.introCategoryId }
        }
        return lessonStore.lessons.filter { $0.cat == category }
    }

    /// Counts passed lessons in a category that are eligible under the specified pad mode.
    /// In 8-pad mode, lessons without an 8-pad layout are excluded from the count (Task 5, SPEC §6).
    public func passedLessonCount(in category: String, padCount: Int? = nil) -> Int {
        let effectivePadCount = padCount ?? settingsManager.activeProfile().padCount
        let categoryLessons = lessons(in: category)

        return categoryLessons.filter { lesson in
            guard progressStore.isPassed(lessonId: lesson.id) else {
                return false
            }
            if effectivePadCount == 8 {
                // Must have a valid 8-pad layout to count in 8-pad mode (SPEC §6)
                return EightPadLayout.slots(for: lesson) != nil
            }
            return true
        }.count
    }

    /// Counts total lessons in a category that are playable under the specified pad mode.
    public func totalLessonCount(in category: String, padCount: Int? = nil) -> Int {
        let effectivePadCount = padCount ?? settingsManager.activeProfile().padCount
        let categoryLessons = lessons(in: category)

        if effectivePadCount == 8 {
            return categoryLessons.filter { EightPadLayout.slots(for: $0) != nil }.count
        }
        return categoryLessons.count
    }

    /// Returns a full progression status snapshot for a category.
    public func status(for category: String, padCount: Int? = nil) -> CategoryProgressionStatus {
        let canonical = Self.canonicalCategory(forCategory: category)
        let isFirst = (canonical == categoryOrder.first)
        let isIntroCategory = isIntro(category: canonical)
        let unlocked = isCategoryUnlocked(canonical, padCount: padCount)
        let softUnlocked = softUnlockedCategories.contains(canonical)
        let passed = passedLessonCount(in: canonical, padCount: padCount)
        let total = totalLessonCount(in: canonical, padCount: padCount)

        let nextUnlocked: Bool
        if let next = CategoryOrder.nextCategory(after: canonical) {
            nextUnlocked = isCategoryUnlocked(next, padCount: padCount)
        } else {
            nextUnlocked = true
        }

        return CategoryProgressionStatus(
            categoryId: canonical,
            title: title(for: canonical),
            isUnlocked: unlocked,
            isSoftUnlocked: softUnlocked,
            passedCount: passed,
            totalCount: total,
            requiredToUnlockNext: lessonsToUnlock,
            isNextCategoryUnlocked: nextUnlocked,
            isFirstCategory: isFirst,
            isIntro: isIntroCategory
        )
    }

    // MARK: - Titles & Localization

    /// Display title for a category in English or Czech.
    public func title(for categoryId: String, language: AppLanguage? = nil) -> String {
        let lang = language ?? settingsManager.languagePreference
        switch categoryId {
        case "starter":
            return lang.localized("First steps")
        case "eighth":
            return lang.localized("Eighth-note grooves")
        case "sixteenth":
            return lang.localized("Sixteenth-note grooves")
        case "electronic":
            return lang.localized("Electronic styles")
        case "ghost":
            return lang.localized("Ghost notes & dynamics")
        case "swing":
            return lang.localized("Swing & shuffle")
        case "world":
            return lang.localized("World rhythms")
        case "fills":
            return lang.localized("Fills")
        case ProgressionConstant.introCategoryId:
            return lang.localized("Intro exercises")
        default:
            // Fall back to category title from LessonStore if present
            if let cat = lessonStore.categories.first(where: { $0.id == categoryId }) {
                return cat.title
            }
            return categoryId.capitalized
        }
    }

    // MARK: - Soft Unlock Logic (Task 4)

    /// Immediately unlocks a category and persists the soft-unlock state.
    public func softUnlock(category: String) {
        lock.lock()
        defer { lock.unlock() }

        let canonical = Self.canonicalCategory(forCategory: category)
        softUnlockedCategories.insert(canonical)
        saveSoftUnlocks()

        if categoryPendingSoftUnlock == category || categoryPendingSoftUnlock == canonical {
            categoryPendingSoftUnlock = nil
        }
    }

    /// Re-locks a category by removing its soft-unlock state (e.g. for reset/testing).
    public func lock(category: String) {
        lock.lock()
        defer { lock.unlock() }

        let canonical = Self.canonicalCategory(forCategory: category)
        softUnlockedCategories.remove(canonical)
        softUnlockedCategories.remove(category)
        saveSoftUnlocks()
    }

    /// Returns whether a category was unlocked manually via soft unlock.
    public func isSoftUnlocked(_ category: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let canonical = Self.canonicalCategory(forCategory: category)
        return softUnlockedCategories.contains(canonical) || softUnlockedCategories.contains(category)
    }

    public func isSoftUnlocked(category: String) -> Bool {
        isSoftUnlocked(category)
    }

    /// Requests a soft-unlock confirmation alert for the tapped category.
    public func requestSoftUnlock(for category: String) {
        lock.lock()
        defer { lock.unlock() }
        let canonical = Self.canonicalCategory(forCategory: category)
        guard !isCategoryUnlocked(canonical) else { return }
        categoryPendingSoftUnlock = canonical
    }

    /// Confirms and performs the pending soft-unlock.
    public func confirmSoftUnlock() {
        lock.lock()
        defer { lock.unlock() }
        guard let pending = categoryPendingSoftUnlock else { return }
        softUnlock(category: pending)
        categoryPendingSoftUnlock = nil
    }

    /// Cancels the pending soft-unlock dialog.
    public func cancelSoftUnlock() {
        lock.lock()
        defer { lock.unlock() }
        categoryPendingSoftUnlock = nil
    }

    /// Clears all soft unlocks and resets progression state.
    public func resetProgression(clearSoftUnlocks: Bool = true) {
        lock.lock()
        defer { lock.unlock() }
        categoryPendingSoftUnlock = nil
        if clearSoftUnlocks {
            softUnlockedCategories.removeAll()
            userDefaults.removeObject(forKey: ProgressionConstant.softUnlockedCategoriesStorageKey)
        }
    }

    // MARK: - Alert Strings

    public var softUnlockAlertTitle: String {
        let catTitle = categoryPendingSoftUnlock.map { title(for: $0) } ?? ""
        return settingsManager.localized("Unlock \"%@\"?", catTitle)
    }

    public var softUnlockAlertMessage: String {
        settingsManager.localized("You can practice any category at any time.")
    }

    public var softUnlockConfirmButtonTitle: String {
        settingsManager.localized("Unlock")
    }

    public var softUnlockCancelButtonTitle: String {
        settingsManager.localized("Cancel")
    }

    // MARK: - Persistence Helpers

    private func loadSoftUnlocks() {
        lock.lock()
        defer { lock.unlock() }

        if let array = userDefaults.stringArray(forKey: ProgressionConstant.softUnlockedCategoriesStorageKey) {
            self.softUnlockedCategories = Set(array)
        } else {
            self.softUnlockedCategories = []
        }
    }

    private func saveSoftUnlocks() {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(Array(softUnlockedCategories).sorted(), forKey: ProgressionConstant.softUnlockedCategoriesStorageKey)
    }
}

// MARK: - SwiftUI Soft Unlock Alert Modifier

/// SwiftUI view modifier to present the soft-unlock confirmation alert.
public struct SoftUnlockAlertModifier: ViewModifier {
    @Bindable var progression: ProgressionManager
    var onUnlock: ((String) -> Void)?

    public init(progression: ProgressionManager, onUnlock: ((String) -> Void)? = nil) {
        self.progression = progression
        self.onUnlock = onUnlock
    }

    public func body(content: Content) -> some View {
        content
            .alert(
                progression.softUnlockAlertTitle,
                isPresented: Binding(
                    get: { progression.categoryPendingSoftUnlock != nil },
                    set: { isPresented in
                        if !isPresented {
                            progression.cancelSoftUnlock()
                        }
                    }
                )
            ) {
                Button(progression.softUnlockCancelButtonTitle, role: .cancel) {
                    progression.cancelSoftUnlock()
                }
                Button(progression.softUnlockConfirmButtonTitle) {
                    if let pending = progression.categoryPendingSoftUnlock {
                        progression.confirmSoftUnlock()
                        onUnlock?(pending)
                    }
                }
            } message: {
                Text(progression.softUnlockAlertMessage)
            }
    }
}

public extension View {
    /// Attaches the soft-unlock confirmation alert driven by `ProgressionManager`.
    func softUnlockAlert(progression: ProgressionManager, onUnlock: ((String) -> Void)? = nil) -> some View {
        modifier(SoftUnlockAlertModifier(progression: progression, onUnlock: onUnlock))
    }
}
