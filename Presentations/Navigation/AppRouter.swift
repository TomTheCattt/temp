//
//  AppRouter.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - AppRouter

/// Centralized navigation state manager using NavigationStack.
@MainActor
@Observable
final class AppRouter {

    static let shared = AppRouter()

    // MARK: - State

    /// Root navigation path for the main tab's NavigationStack.
    var feedPath = NavigationPath()
    var reelsPath = NavigationPath()
    var chatPath = NavigationPath()
    var explorePath = NavigationPath()
    var profilePath = NavigationPath()

    /// Currently selected tab.
    var selectedTab: AppTab = .feed

    /// Whether the user is authenticated.
    var isAuthenticated: Bool = false

    /// Sheet currently presented.
    var presentedSheet: AppSheet?

    /// Full-screen cover currently presented.
    var presentedFullScreen: AppFullScreen?

    private init() {}

    // MARK: - Navigation Actions

    /// Push a route onto the current tab's navigation stack.
    func push(_ route: AppRoute) {
        switch selectedTab {
        case .feed:     feedPath.append(route)
        case .reels:    reelsPath.append(route)
        case .chat:     chatPath.append(route)
        case .explore:  explorePath.append(route)
        case .profile:  profilePath.append(route)
        }
    }

    /// Push a route onto a specific tab's stack.
    func push(_ route: AppRoute, in tab: AppTab) {
        switch tab {
        case .feed:     feedPath.append(route)
        case .reels:    reelsPath.append(route)
        case .chat:     chatPath.append(route)
        case .explore:  explorePath.append(route)
        case .profile:  profilePath.append(route)
        }
    }

    /// Pop the top route from the current tab.
    func pop() {
        switch selectedTab {
        case .feed:     if !feedPath.isEmpty { feedPath.removeLast() }
        case .reels:    if !reelsPath.isEmpty { reelsPath.removeLast() }
        case .chat:     if !chatPath.isEmpty { chatPath.removeLast() }
        case .explore:  if !explorePath.isEmpty { explorePath.removeLast() }
        case .profile:  if !profilePath.isEmpty { profilePath.removeLast() }
        }
    }

    /// Pop multiple routes from the current tab.
    func pop(count: Int) {
        let safeCount = max(1, count)
        switch selectedTab {
        case .feed:     feedPath.removeLast(min(safeCount, feedPath.count))
        case .reels:    reelsPath.removeLast(min(safeCount, reelsPath.count))
        case .chat:     chatPath.removeLast(min(safeCount, chatPath.count))
        case .explore:  explorePath.removeLast(min(safeCount, explorePath.count))
        case .profile:  profilePath.removeLast(min(safeCount, profilePath.count))
        }
    }

    /// Pop to root of the current tab.
    func popToRoot() {
        switch selectedTab {
        case .feed:     feedPath = NavigationPath()
        case .reels:    reelsPath = NavigationPath()
        case .chat:     chatPath = NavigationPath()
        case .explore:  explorePath = NavigationPath()
        case .profile:  profilePath = NavigationPath()
        }
    }

    /// Pop to root of a specific tab.
    func popToRoot(in tab: AppTab) {
        switch tab {
        case .feed:     feedPath = NavigationPath()
        case .reels:    reelsPath = NavigationPath()
        case .chat:     chatPath = NavigationPath()
        case .explore:  explorePath = NavigationPath()
        case .profile:  profilePath = NavigationPath()
        }
    }

    /// Present a sheet.
    func present(sheet: AppSheet) {
        presentedSheet = sheet
    }

    /// Present a full-screen cover.
    func present(fullScreen: AppFullScreen) {
        presentedFullScreen = fullScreen
    }

    /// Dismiss sheet or full-screen.
    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
    }

    /// Switch to a tab and optionally navigate.
    func switchTab(_ tab: AppTab, route: AppRoute? = nil) {
        selectedTab = tab
        if let route {
            push(route, in: tab)
        }
    }

    /// Reset all navigation (e.g. on logout).
    func reset() {
        feedPath = NavigationPath()
        reelsPath = NavigationPath()
        chatPath = NavigationPath()
        explorePath = NavigationPath()
        profilePath = NavigationPath()
        selectedTab = .feed
        presentedSheet = nil
        presentedFullScreen = nil
    }
}
