//
//  ReportUseCases.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - Report Use Cases

// Create Report Use Case
struct CreateReportUseCase: CreateReportUseCaseProtocol {
    private let repository: ReportRepositoryProtocol

    init(repository: ReportRepositoryProtocol) {
        self.repository = repository
    }

    func execute(
        type: ReportType,
        reason: ReportReason,
        description: String?,
        postId: String?,
        commentId: String?,
        reelId: String?,
        storyId: String?,
        userId: String?,
        messageId: String?
    ) -> AnyPublisher<Report, Error> {
        // Validate exactly one target ID is provided
        let targetIds = [postId, commentId, reelId, storyId, userId, messageId].compactMap { $0 }
        guard targetIds.count == 1 else {
            return Fail(error: ReportError.invalidTargetCount)
                .eraseToAnyPublisher()
        }

        // Validate target type matches
        let targetType: ReportType
        if postId != nil { targetType = .post }
        else if commentId != nil { targetType = .comment }
        else if reelId != nil { targetType = .reel }
        else if storyId != nil { targetType = .story }
        else if userId != nil { targetType = .user }
        else if messageId != nil { targetType = .message }
        else {
            return Fail(error: ReportError.noTargetId)
                .eraseToAnyPublisher()
        }

        guard targetType == type else {
            return Fail(error: ReportError.targetTypeMismatch)
                .eraseToAnyPublisher()
        }

        return repository.createReport(
            type: type,
            reason: reason,
            description: description,
            postId: postId,
            commentId: commentId,
            reelId: reelId,
            storyId: storyId,
            userId: userId,
            messageId: messageId
        )
    }
}

// Get My Reports Use Case
struct GetMyReportsUseCase: GetMyReportsUseCaseProtocol {
    private let repository: ReportRepositoryProtocol

    init(repository: ReportRepositoryProtocol) {
        self.repository = repository
    }

    func execute(page: Int = 1, perPage: Int = 20, status: ReportStatus? = nil, type: ReportType? = nil) -> AnyPublisher<PaginatedReports, Error> {
        return repository.getMyReports(page: page, perPage: perPage, status: status, type: type)
    }
}

// Get Report Detail Use Case
struct GetReportDetailUseCase: GetReportDetailUseCaseProtocol {
    private let repository: ReportRepositoryProtocol

    init(repository: ReportRepositoryProtocol) {
        self.repository = repository
    }

    func execute(reportId: String) -> AnyPublisher<Report, Error> {
        return repository.getReportDetail(reportId: reportId)
    }
}

// Get All Reports Use Case (Admin)
struct GetAllReportsUseCase: GetAllReportsUseCaseProtocol {
    private let repository: ReportRepositoryProtocol

    init(repository: ReportRepositoryProtocol) {
        self.repository = repository
    }

    func execute(page: Int = 1, perPage: Int = 20, status: ReportStatus? = nil, type: ReportType? = nil) -> AnyPublisher<PaginatedReports, Error> {
        return repository.getAllReports(page: page, perPage: perPage, status: status, type: type)
    }
}

// Update Report Status Use Case (Admin)
struct UpdateReportStatusUseCase: UpdateReportStatusUseCaseProtocol {
    private let repository: ReportRepositoryProtocol

    init(repository: ReportRepositoryProtocol) {
        self.repository = repository
    }

    func execute(reportId: String, status: ReportStatus, resolution: String?) -> AnyPublisher<Report, Error> {
        return repository.updateReportStatus(reportId: reportId, status: status, resolution: resolution)
    }
}

// MARK: - Report Errors

enum ReportError: Error, LocalizedError {
    case invalidTargetCount
    case noTargetId
    case targetTypeMismatch
    case selfReportNotAllowed
    case alreadyReported
    case reportNotFound
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidTargetCount:
            return "Exactly one target ID must be provided for the report type"
        case .noTargetId:
            return "No target ID provided"
        case .targetTypeMismatch:
            return "Target ID type does not match report type"
        case .selfReportNotAllowed:
            return "Cannot report yourself"
        case .alreadyReported:
            return "You have already reported this content"
        case .reportNotFound:
            return "Report not found"
        case .unauthorized:
            return "Not authorized to perform this action"
        }
    }
}

// Note: ReportError is defined here
// Note: ReportRepositoryProtocol is defined in Data/Repositories/ReportRepository.swift
// Note: Domain models (Report, Reporter, PaginatedReports) are defined in Data/Mappers/ReportMapper.swift
// Note: ReportType, ReportReason, ReportStatus are defined in Shared/Enums.swift