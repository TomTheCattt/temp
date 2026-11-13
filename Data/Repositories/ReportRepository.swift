//
//  ReportRepository.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - ReportRepository Protocol

protocol ReportRepositoryProtocol {
    func createReport(
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

    func getMyReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<PaginatedReports, Error>

    func getReportDetail(reportId: String) -> AnyPublisher<Report, Error>

    func getAllReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<PaginatedReports, Error>

    func updateReportStatus(reportId: String, status: ReportStatus, resolution: String?) -> AnyPublisher<Report, Error>
}

// MARK: - ReportRepository Implementation

final class ReportRepository: ReportRepositoryProtocol {
    private let dataSource: RemoteReportDataSourceProtocol
    private let mapper: ReportMapper.Type = ReportMapper.self

    init(dataSource: RemoteReportDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func createReport(
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
        let request = CreateReportRequestDTO(
            type: ReportTypeDTO(rawValue: type.rawValue)!,
            reason: ReportReasonDTO(rawValue: reason.rawValue)!,
            description: description,
            postId: postId,
            commentId: commentId,
            reelId: reelId,
            storyId: storyId,
            userId: userId,
            messageId: messageId
        )

        return dataSource.createReport(request)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getMyReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<PaginatedReports, Error> {
        return dataSource.getMyReports(page: page, perPage: perPage, status: status, type: type)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getReportDetail(reportId: String) -> AnyPublisher<Report, Error> {
        return dataSource.getReportDetail(reportId: reportId)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func getAllReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<PaginatedReports, Error> {
        return dataSource.getAllReports(page: page, perPage: perPage, status: status, type: type)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }

    func updateReportStatus(reportId: String, status: ReportStatus, resolution: String?) -> AnyPublisher<Report, Error> {
        return dataSource.updateReportStatus(reportId: reportId, status: status, resolution: resolution)
            .map { self.mapper.map($0) }
            .eraseToAnyPublisher()
    }
}