//
//  UserSettingsUseCase.swift
//  Instagram
//
//  Created by Kiro on 13/11/26.
//

import Foundation

// MARK: - UserSettingsUseCase

protocol UserSettingsUseCaseProtocol: Sendable {
    func fetchSettings() async throws -> UserSettings
    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings
}

final class UserSettingsUseCase: UserSettingsUseCaseProtocol, Sendable {

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    func fetchSettings() async throws -> UserSettings {
        try await userRepository.fetchSettings()
    }

    func updateSettings(_ patch: UserSettingsPatch) async throws -> UserSettings {
        try await userRepository.updateSettings(patch)
    }
}
