import Foundation
import Observation
import StoreKit

/// StoreKit's verified entitlements are the only source of purchase ownership.
@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()
    static let productPrefix = "cz.kju.SmackAPad"
    static let fullID = productPrefix + ".full"
    static let bundleID = productPrefix + ".bundle.all"
    // Enable only when the bundle is configured for sale in App Store Connect.
    static let bundleEnabled = false

    private(set) var ownedProductIDs: Set<String> = []
    private(set) var products: [String: Product] = [:]
    private(set) var loadingProducts = false
    private(set) var busy = false
    private(set) var entitlementsLoaded = false
    var message: String?
    private(set) var productLoadFailed = false
    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var refreshGeneration = 0

    var hasFullAccess: Bool {
        ownedProductIDs.contains(Self.fullID) || ownedProductIDs.contains(Self.bundleID)
    }

    var packIDs: [String] {
        Set(LessonStore.shared.lessons.compactMap { lesson -> String? in
            guard let access = lesson.access, access.hasPrefix("pack:"), access.count > 5 else { return nil }
            return String(access.dropFirst(5))
        }).sorted()
    }

    func productID(for access: String) -> String? {
        if access == "full" { return Self.fullID }
        if access.hasPrefix("pack:"), access.count > 5 {
            return Self.productPrefix + ".pack." + access.dropFirst(5)
        }
        return nil
    }

    func isUnlocked(_ lesson: Lesson) -> Bool {
        let access = lesson.access ?? "full"
        if access == "free" { return true }
        if access == "full" { return hasFullAccess }
        guard let id = productID(for: access) else { return false }
        return ownedProductIDs.contains(id) || ownedProductIDs.contains(Self.bundleID)
    }

    func start() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                guard let self else { return }
                guard case .verified(let transaction) = result else { continue }
                await self.refreshEntitlements()
                await transaction.finish()
            }
        }
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    func refreshEntitlements() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        var owned: Set<String> = []
        var transactions: [Transaction] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productType == .nonConsumable,
               transaction.revocationDate == nil, !transaction.isUpgraded {
                owned.insert(transaction.productID)
            }
            transactions.append(transaction)
        }
        guard generation == refreshGeneration else { return }
        ownedProductIDs = owned
        entitlementsLoaded = true
        for transaction in transactions { await transaction.finish() }
    }

    func loadProducts() async {
        guard !loadingProducts else { return }
        loadingProducts = true
        productLoadFailed = false
        defer { loadingProducts = false }
        let ids = [Self.fullID] + packIDs.map { Self.productPrefix + ".pack." + $0 }
            + (Self.bundleEnabled ? [Self.bundleID] : [])
        do {
            let loaded = try await Product.products(for: ids)
            products = Dictionary(uniqueKeysWithValues: loaded.filter { $0.type == .nonConsumable }.map { ($0.id, $0) })
            productLoadFailed = ids.contains { products[$0] == nil }
        } catch {
            productLoadFailed = true
        }
    }

    func purchase(_ product: Product) async {
        guard !busy else { return }
        busy = true
        message = nil
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result else {
                    message = "Purchase could not be verified. Please try again."
                    return
                }
                await refreshEntitlements()
                await transaction.finish()
            case .userCancelled: break
            case .pending: message = "Purchase pending approval"
            @unknown default: message = "Purchase failed. Please try again."
            }
        } catch StoreKitError.userCancelled {
            // Cancellation is intentionally silent.
        } catch {
            message = "Purchase failed. Please try again."
        }
    }

    func restore() async {
        guard !busy else { return }
        busy = true
        message = nil
        defer { busy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            let knownOwnership = hasFullAccess || ownedProductIDs.contains { $0.hasPrefix(Self.productPrefix + ".pack.") }
            message = knownOwnership ? "Purchases restored" : "No previous purchases found"
        } catch StoreKitError.userCancelled {
        } catch {
            message = "Restore failed. Please try again."
        }
    }
}
