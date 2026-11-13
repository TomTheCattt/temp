//
//  CallHistoryUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - CallHistoryUseCase

protocol CallHistoryUseCaseProtocol: Sendable {
    func fetchCallHistory() async throws -> [CallHistoryItem]
    func deleteCallHistory(id: String) async throws
    func clearCallHistory() async throws
}

final class CallHistoryUseCase: CallHistoryUseCaseProtocol, Sendable {

    private let callRepository: CallRepositoryProtocol

    init(callRepository: CallRepositoryProtocol) {
        self.callRepository = callRepository
    }

    func fetchCallHistory() async throws -> [CallHistoryItem] {
        try await callRepository.fetchCallHistory()
    }

    func deleteCallHistory(id: String) async throws {
        try await callRepository.deleteCallHistory(id: id)
    }

    func clearCallHistory() async throws {
        try await callRepository.clearCallHistory()
    }
}
