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

    var avatarPickerItem: PhotosPickerItem?
    var newAvatarData: Data?
    var currentAvatarURL: URL?
    var hasRemovedAvatar: Bool = false

    var showDiscardAlert: Bool = false
    var showPhotoActionSheet: Bool = false
    var isShowingPhotoPicker: Bool = false

    var isLoading = false
    var isSaving = false
    var errorMessage: String?
    var isSaved = false

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

        if let currentUser = SessionStore.shared.currentUser {
            name = currentUser.fullName
            username = currentUser.username
            bio = currentUser.bio ?? ""
            website = currentUser.website ?? ""
            currentAvatarURL = currentUser.avatarURL
        }
    }

    // MARK: - Actions

    func loadProfile() async {
        // TODO: Implement loadProfile logic from scratch
    }

    func loadAvatarFromPicker() async {
        guard let item = avatarPickerItem else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

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
        guard !isSaving else { return }
        isSaving = true
        // TODO: Implement updateProfile save logic from scratch
        isSaving = false
    }

    // MARK: - Computed

    var hasChanges: Bool {
        true
    }

    var bioCharacterCount: Int {
        bio.count
    }

    var isBioValid: Bool {
        bio.count <= DS.Layout.maxBioLength
    }
}
