//
//  EditProfileViewModel.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

// MARK: - EditProfileViewModel

@MainActor
@Observable
final class EditProfileViewModel {

    // MARK: - State

    var name: String = ""
    var username: String = ""
    var bio: String = ""
    var website: String = ""

    /// Avatar photo picker item.
    var avatarPickerItem: PhotosPickerItem?

    /// Avatar image data (new selection).
    private(set) var newAvatarData: Data?

    /// Current avatar URL (from loaded profile).
    private(set) var currentAvatarURL: URL?

    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?
    private(set) var isSaved = false

    // MARK: - Dependencies

    private let updateProfileUseCase: UpdateProfileUseCaseProtocol
    private let userRepository: UserRepositoryProtocol

    // MARK: - Init

    init(
        updateProfileUseCase: UpdateProfileUseCaseProtocol,
        userRepository: UserRepositoryProtocol
    ) {
        self.updateProfileUseCase = updateProfileUseCase
        self.userRepository = userRepository
    }

    // MARK: - Actions

    func loadProfile() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let user = try await userRepository.fetchCurrentUser()
            name = user.fullName
            username = user.username
            bio = user.bio ?? ""
            website = user.website ?? ""
            currentAvatarURL = user.avatarURL
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func loadAvatarFromPicker() async {
        guard let item = avatarPickerItem else { return }

        if let data = try? await item.loadTransferable(type: Data.self) {
            newAvatarData = data
        }
    }

    func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        do {
            // Update profile info
            _ = try await updateProfileUseCase.execute(
                UpdateProfileInput(
                    name: name.isEmpty ? nil : name,
                    bio: bio,
                    website: website.isEmpty ? nil : website
                )
            )

            // Update avatar if changed
            if let avatarData = newAvatarData {
                _ = try await userRepository.updateAvatar(imageData: avatarData)
            }

            isSaved = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Computed

    var hasChanges: Bool {
        // Simple check — in production compare against original values
        !name.isEmpty || !bio.isEmpty || !website.isEmpty || newAvatarData != nil
    }

    var bioCharacterCount: Int {
        bio.count
    }

    var isBioValid: Bool {
        bio.count <= 150
    }
}
