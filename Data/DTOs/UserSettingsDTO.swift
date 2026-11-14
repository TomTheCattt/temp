//
//  UserSettingsDTO.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation

// MARK: - UserSettingsDTO

/// API response model for per-account settings.
/// Matches `GET/PUT /v1/users/me/settings`. All fields optional so partial
/// responses (or a partial PUT echo) decode safely; missing values fall back
/// to the entity defaults during mapping.
nonisolated struct UserSettingsDTO: Decodable, Sendable {
    let language: String?
    let darkMode: Bool?
    let biometricEnabled: Bool?
    let pushEnabled: Bool?
    let likeNotifications: Bool?
    let commentNotifications: Bool?
    let followNotifications: Bool?
    let directMessageNotifications: Bool?
    let activityStatusVisible: Bool?
    let highQualityUploads: Bool?
    let cellularDataEnabled: Bool?
}

// MARK: - UserSettingsWrapperDTO

/// Wrapper for `{ "settings": {...} }` inside the data envelope.
nonisolated struct UserSettingsWrapperDTO: Decodable, Sendable {
    let settings: UserSettingsDTO
}

/// Patch model for partial settings updates (PUT /v1/users/me/settings).
/// All fields are optional - only provided fields will be updated.
nonisolated struct UserSettingsPatch: Encodable, Sendable {
    let language: String?
    let biometricEnabled: Bool?
    let pushEnabled: Bool?
    let darkMode: Bool?
}

// MARK: - DeviceTokensDTO

/// Response for device tokens list.
nonisolated struct DeviceTokensDTO: Decodable, Sendable {
    let tokens: [DeviceTokenDTO]
}

/// Individual device token.
nonisolated struct DeviceTokenDTO: Decodable, Sendable {
    let id: String
    let token: String
    let platform: String
    let createdAt: String
}
