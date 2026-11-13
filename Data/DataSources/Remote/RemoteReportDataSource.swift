//
//  RemoteReportDataSource.swift
//  Instagram
//
//  Created by Kiro on 12/11/26.
//

import Foundation
import Combine

// MARK: - RemoteReportDataSource Protocol

protocol RemoteReportDataSourceProtocol {
    func createReport(_ request: CreateReportRequestDTO) -> AnyPublisher<ReportDTO, Error>
    func getMyReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<ReportsListDataDTO, Error>
    func getReportDetail(reportId: String) -> AnyPublisher<ReportDTO, Error>
    func getAllReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<ReportsListDataDTO, Error>
    func updateReportStatus(reportId: String, status: ReportStatus, resolution: String?) -> AnyPublisher<ReportDTO, Error>
}

// MARK: - RemoteReportDataSource Implementation

final class RemoteReportDataSource: RemoteReportDataSourceProtocol {
    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func createReport(_ request: CreateReportRequestDTO) -> AnyPublisher<ReportDTO, Error> {
        let endpoint = ReportEndpoint.create(
            type: request.type.domainType,
            reason: request.reason.domainReason,
            description: request.description,
            postId: request.postId,
            commentId: request.commentId,
            reelId: request.reelId,
            storyId: request.storyId,
            userId: request.userId,
            messageId: request.messageId
        )

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: ReportResponseDTO) in response.data!.report }
            .eraseToAnyPublisher()
    }

    func getMyReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<ReportsListDataDTO, Error> {
        let endpoint = ReportEndpoint.myReports(
            page: page,
            perPage: perPage,
            status: status,
            type: type
        )

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: ReportsListResponseDTO) in response.data! }
            .eraseToAnyPublisher()
    }

    func getReportDetail(reportId: String) -> AnyPublisher<ReportDTO, Error> {
        let endpoint = ReportEndpoint.detail(reportId: reportId)

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: ReportResponseDTO) in response.data!.report }
            .eraseToAnyPublisher()
    }

    func getAllReports(page: Int, perPage: Int, status: ReportStatus?, type: ReportType?) -> AnyPublisher<ReportsListDataDTO, Error> {
        let endpoint = ReportEndpoint.allReports(
            page: page,
            perPage: perPage,
            status: status,
            type: type
        )

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: ReportsListResponseDTO) in response.data! }
            .eraseToAnyPublisher()
    }

    func updateReportStatus(reportId: String, status: ReportStatus, resolution: String?) -> AnyPublisher<ReportDTO, Error> {
        let endpoint = ReportEndpoint.updateStatus(
            reportId: reportId,
            status: status,
            resolution: resolution
        )

        return networkService.requestEnvelopePublisher(endpoint)
            .mapError { $0 as Error }
            .map { (response: ReportResponseDTO) in response.data!.report }
            .eraseToAnyPublisher()
    }
}