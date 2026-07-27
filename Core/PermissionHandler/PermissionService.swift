//
//  PermissionService.swift
//  Instagram
//
//  Created by Nguyễn Việt Anh on 20/7/26.
//

import Foundation

// MARK: - Permission Types

/// OS-level permissions the app may request.
public enum PermissionType: String, Sendable, CaseIterable {
    case camera
    case photoLibrary
    case microphone
    case location
    case locationAlways
    case notifications
    case contacts
    case faceID
    case tracking
}

/// Current authorization status for a permission.
public enum PermissionStatus: Sendable, Equatable {
    /// User has not been asked yet.
    case notDetermined
    /// Access is restricted by system policy (parental controls, MDM).
    case restricted
    /// Limited access
    case limited
    /// User explicitly denied.
    case denied
    /// User granted access.
    case authorized
    /// Location: authorized only while app is in use.
    case authorizedWhenInUse
    /// Provisional (notifications only).
    case provisional
}

// MARK: - Permission Service Protocol

/// Abstraction for checking and requesting OS permissions.
/// Feature modules use this protocol; the concrete implementation lives in the app host
/// or a platform-specific target since it requires UIKit/system frameworks.
public protocol PermissionServiceProtocol: Sendable {
    /// Check the current status without prompting the user.
    func status(for permission: PermissionType) async -> PermissionStatus

    /// Request permission from the user. Returns the resulting status.
    func request(_ permission: PermissionType) async -> PermissionStatus
}

// MARK: - Permission Result

/// A result combining the permission type with its status, useful for batch checks.
public struct PermissionResult: Sendable, Equatable {
    public let type: PermissionType
    public let status: PermissionStatus

    public init(type: PermissionType, status: PermissionStatus) {
        self.type = type
        self.status = status
    }

    public var isGranted: Bool {
        status == .authorized || status == .authorizedWhenInUse || status == .provisional
    }
}

// MARK: - Convenience Extensions

public extension PermissionServiceProtocol {
    /// Check multiple permissions at once.
    func statuses(for permissions: [PermissionType]) async -> [PermissionResult] {
        var results: [PermissionResult] = []
        for permission in permissions {
            let status = await status(for: permission)
            results.append(PermissionResult(type: permission, status: status))
        }
        return results
    }

    /// Returns true if the permission is granted or provisional.
    func isGranted(_ permission: PermissionType) async -> Bool {
        let s = await status(for: permission)
        return s == .authorized || s == .authorizedWhenInUse || s == .provisional
    }

    /// Returns true if the user can still be prompted (not yet determined).
    func canRequest(_ permission: PermissionType) async -> Bool {
        let s = await status(for: permission)
        return s == .notDetermined
    }
}

