//
//  LogoutUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - LogoutUseCase

protocol LogoutUseCaseProtocol: Sendable {
    func execute() async throws
}

final class LogoutUseCase: LogoutUseCaseProtocol, Sendable {

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    func execute() async throws {
        try await authRepository.logout()
    }
}
