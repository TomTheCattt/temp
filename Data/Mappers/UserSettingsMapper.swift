//
//  UserSettingsMapper.swift
//  Instagram
//
//  Created by Kiro on 13/9/26.
//

import Foundation

// MARK: - UserSettingsMapper

nonisolated enum UserSettingsMapper {

    static func toEntity(_ dto: UserSettingsDTO) -> UserSettings {
        let defaults = UserSettings.default
        return UserSettings(
            pushEnabled: dto.pushEnabled ?? defaults.pushEnabled,
            likeNotifications: dto.likeNotifications ?? defaults.likeNotifications,
            commentNotifications: dto.commentNotifications ?? defaults.commentNotifications,
            followNotifications: dto.followNotifications ?? defaults.followNotifications,
            directMessageNotifications: dto.directMessageNotifications ?? defaults.directMessageNotifications,
            activityStatusVisible: dto.activityStatusVisible ?? defaults.activityStatusVisible,
            highQualityUploads: dto.highQualityUploads ?? defaults.highQualityUploads,
            cellularDataEnabled: dto.cellularDataEnabled ?? defaults.cellularDataEnabled
        )
    }
}
