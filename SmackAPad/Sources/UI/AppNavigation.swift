//
//  AppNavigation.swift
//  SmackAPad
//
//  Global navigation state managing top-level routes (Ticket 105).
//

import Foundation
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
