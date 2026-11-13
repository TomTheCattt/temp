//
//  ReportUseCaseProtocols.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - Report Use Case Protocols

protocol CreateReportUseCaseProtocol {
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
    ) -> AnyPublisher<Report, Error>
}

protocol GetMyReportsUseCaseProtocol {
    func execute(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<PaginatedReports, Error>
}

protocol GetReportDetailUseCaseProtocol {
    func execute(reportId: String) -> AnyPublisher<Report, Error>
}

protocol GetAllReportsUseCaseProtocol {
    func execute(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<PaginatedReports, Error>
}

protocol UpdateReportStatusUseCaseProtocol {
    func execute(reportId: String, status: ReportStatus, resolution: String?) -> AnyPublisher<Report, Error>
}