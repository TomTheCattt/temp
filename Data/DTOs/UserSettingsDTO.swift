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
