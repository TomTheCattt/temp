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

    /// Track if current avatar was removed.
    private(set) var hasRemovedAvatar: Bool = false

    /// Initial values for detecting changes
    private(set) var initialName: String = ""
    private(set) var initialBio: String = ""
    private(set) var initialWebsite: String = ""
    private(set) var initialAvatarURL: URL?

    // UI Dialogs
    var showDiscardAlert: Bool = false
    var showPhotoActionSheet: Bool = false
    var isShowingPhotoPicker: Bool = false

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
        errorMessage = nil

        do {
            let user = try await userRepository.fetchCurrentUser()
            name = user.fullName
            username = user.username
            bio = user.bio ?? ""
            website = user.website ?? ""
            currentAvatarURL = user.avatarURL

            initialName = name
            initialBio = bio
            initialWebsite = website
            initialAvatarURL = currentAvatarURL
            newAvatarData = nil
            hasRemovedAvatar = false
        } catch {
            errorMessage = error.userMessage
        }

        isLoading = false
    }

    func loadAvatarFromPicker() async {
        guard let item = avatarPickerItem else { return }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        // Downsample to max 800x800 and compress to JPEG 0.85
        let maxDimension: CGFloat = 800
        let size = image.size
        let ratio = min(maxDimension / max(size.width, 1), maxDimension / max(size.height, 1), 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        if let compressedData = resizedImage.jpegData(compressionQuality: 0.85) {
            newAvatarData = compressedData
            hasRemovedAvatar = false
        }
    }

    func removeAvatar() {
        newAvatarData = nil
        hasRemovedAvatar = true
    }

    func save() async {
        guard !isSaving, hasChanges else { return }
        isSaving = true
        errorMessage = nil
        HUDManager.shared.showLoading(L10n.HUD.saving)

        do {
            var updatedUser: User?

            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)

            let textFieldsChanged = (trimmedName != initialName || bio != initialBio || trimmedWebsite != initialWebsite)

            if textFieldsChanged {
                updatedUser = try await updateProfileUseCase.execute(
                    UpdateProfileInput(
                        name: trimmedName.isEmpty ? nil : trimmedName,
                        bio: bio,
                        website: trimmedWebsite.isEmpty ? nil : trimmedWebsite
                    )
                )
            }

            if let avatarData = newAvatarData {
                updatedUser = try await userRepository.updateAvatar(imageData: avatarData)
            } else if hasRemovedAvatar && initialAvatarURL != nil {
                updatedUser = try await userRepository.updateAvatar(imageData: Data())
            }

            // Fallback to fetchCurrentUser if needed
            if updatedUser == nil {
                updatedUser = try await userRepository.fetchCurrentUser()
            }

            if let result = updatedUser {
                SessionStore.shared.setSession(user: result)
                NotificationCenter.default.post(name: .didUpdateProfile, object: result)
            }

            isSaved = true
            HUDManager.shared.showSuccess(L10n.HUD.saved)
        } catch {
            HUDManager.shared.showError(error.userMessage)
        }

        isSaving = false
    }

    // MARK: - Computed

    var hasChanges: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines) != initialName ||
        bio != initialBio ||
        website.trimmingCharacters(in: .whitespacesAndNewlines) != initialWebsite ||
        newAvatarData != nil ||
        (hasRemovedAvatar && initialAvatarURL != nil)
    }

    var bioCharacterCount: Int {
        bio.count
    }

    var isBioValid: Bool {
        bio.count <= DS.Layout.maxBioLength
    }
}
