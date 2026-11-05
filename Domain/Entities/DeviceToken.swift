//
//  DeviceToken.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - DeviceToken

/// Represents a device token for push notifications.
struct DeviceToken: Identifiable, Sendable, Hashable {
    let id: String
    let token: String
    let platform: String
    let createdAt: Date
}