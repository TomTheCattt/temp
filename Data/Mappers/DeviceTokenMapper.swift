//
//  DeviceTokenMapper.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import Foundation

// MARK: - DeviceTokenMapper

nonisolated enum DeviceTokenMapper {

    static func toEntity(_ dto: DeviceTokenDTO) -> DeviceToken {
        DeviceToken(
            id: dto.id,
            token: dto.token,
            platform: dto.platform,
            createdAt: DateMapper.toDate(dto.createdAt)
        )
    }

    static func toEntityList(_ dtos: [DeviceTokenDTO]) -> [DeviceToken] {
        dtos.map { toEntity($0) }
    }
}