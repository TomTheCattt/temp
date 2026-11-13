//
//  ReportMapper.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation

// MARK: - ReportMapper

struct ReportMapper {
    nonisolated static func map(_ dto: ReportDTO) -> Report {
        return Report(
            id: dto.id,
            reporterId: dto.reporterId,
            type: dto.type.domainType,
            reason: dto.reason.domainReason,
            description: dto.description,
            postId: dto.postId,
            commentId: dto.commentId,
            reelId: dto.reelId,
            storyId: dto.storyId,
            userId: dto.userId,
            messageId: dto.messageId,
            status: dto.status.domainStatus,
            reviewedBy: dto.reviewedBy,
            reviewedAt: dto.reviewedAt,
            resolution: dto.resolution,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            reporter: dto.reporter.map { Reporter(
                id: $0.id,
                username: $0.username,
                fullName: $0.fullName,
                avatarUrl: $0.avatarUrl
            )}
        )
    }

    nonisolated static func map(_ dtos: [ReportDTO]) -> [Report] {
        return dtos.map(map)
    }

    nonisolated static func map(_ dto: ReportsListDataDTO) -> PaginatedReports {
        return PaginatedReports(
            items: map(dto.items),
            page: dto.page,
            perPage: dto.perPage,
            total: dto.total,
            hasMore: dto.hasMore
        )
    }
}

// MARK: - Domain Models

struct Report: Identifiable, Equatable {
    let id: String
    let reporterId: String
    let type: ReportType
    let reason: ReportReason
    let description: String?
    let postId: String?
    let commentId: String?
    let reelId: String?
    let storyId: String?
    let userId: String?
    let messageId: String?
    let status: ReportStatus
    let reviewedBy: String?
    let reviewedAt: Date?
    let resolution: String?
    let createdAt: Date
    let updatedAt: Date
    let reporter: Reporter?
}

struct Reporter: Equatable {
    let id: String
    let username: String
    let fullName: String
    let avatarUrl: String?
}

struct PaginatedReports: Equatable {
    let items: [Report]
    let page: Int
    let perPage: Int
    let total: Int
    let hasMore: Bool
}

// Note: ReportType, ReportReason, ReportStatus are defined in ReportEndpoint.swift
// In a real project, these would be in a shared Enums file