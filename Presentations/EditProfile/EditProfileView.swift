//
//  EditProfileView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI
import NukeUI

// MARK: - EditProfileView

struct EditProfileView: View {

    @State private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: EditProfileViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                avatarSection
                profileFieldsSection
                bioSection
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(L10n.EditProfile.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        if viewModel.hasChanges {
                            viewModel.showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        Task {
                            await viewModel.save()
                            if viewModel.isSaved {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.isSaving || !viewModel.hasChanges || !viewModel.isBioValid)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert(L10n.Common.error, isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(L10n.Common.ok) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .confirmationDialog(
                L10n.EditProfile.discardTitle,
                isPresented: $viewModel.showDiscardAlert,
                titleVisibility: .visible
            ) {
                Button(L10n.EditProfile.discardConfirm, role: .destructive) {
                    dismiss()
                }
                Button(L10n.EditProfile.keepEditing, role: .cancel) {}
            }
            .confirmationDialog(
                L10n.EditProfile.changePhoto,
                isPresented: $viewModel.showPhotoActionSheet,
                titleVisibility: .visible
            ) {
                Button(L10n.EditProfile.chooseFromLibrary) {
                    viewModel.isShowingPhotoPicker = true
                }
                if viewModel.newAvatarData != nil || (!viewModel.hasRemovedAvatar && viewModel.currentAvatarURL != nil) {
                    Button(L10n.EditProfile.removeCurrentPhoto, role: .destructive) {
                        viewModel.removeAvatar()
                    }
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            }
            .photosPicker(
                isPresented: $viewModel.isShowingPhotoPicker,
                selection: $viewModel.avatarPickerItem,
                matching: .images
            )
            .task {
                await viewModel.loadProfile()
            }
            .onChange(of: viewModel.avatarPickerItem) { _, _ in
                Task { await viewModel.loadAvatarFromPicker() }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        Section {
            HStack {
                Spacer()
                Button {
                    viewModel.showPhotoActionSheet = true
                } label: {
                    VStack(spacing: DS.Spacing.xs) {
                        avatarPreview
                            .frame(width: DS.Size.avatarXLarge, height: DS.Size.avatarXLarge)
                            .clipShape(Circle())

                        Text(L10n.EditProfile.changePhoto)
                            .font(DS.Font.subheadlineBold)
                            .foregroundStyle(ColorTokens.accentPrimary)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let data = viewModel.newAvatarData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if !viewModel.hasRemovedAvatar, let url = viewModel.currentAvatarURL {
            LazyImage(url: url) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else if state.error != nil {
                    avatarPlaceholder
                } else {
                    Circle().fill(Color.gray.opacity(DS.Opacity.low))
                }
            }
        } else {
            avatarPlaceholder
        }
    }

    private var avatarPlaceholder: some View {
        ZStack {
            Circle().fill(Color(.systemGray5))
            InstagramIcon(.profile(selected: true), size: DS.Size.avatarXLarge, color: .gray.opacity(0.6))
        }
    }

    // MARK: - Profile Fields

    private var profileFieldsSection: some View {
        Section {
            LabeledContent(L10n.EditProfile.name) {
                TextField(L10n.EditProfile.name, text: $viewModel.name)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.words)
            }

            LabeledContent(L10n.EditProfile.username) {
                TextField(L10n.EditProfile.username, text: $viewModel.username)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .disabled(true)
                    .foregroundStyle(.secondary)
            }

            LabeledContent(L10n.EditProfile.website) {
                TextField(L10n.EditProfile.website, text: $viewModel.website)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.URL)
            }
        }
        .font(DS.Font.subheadline)
    }

    // MARK: - Bio Section

    private var bioSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(L10n.EditProfile.bio)
                    .font(DS.Font.subheadline)
                    .foregroundStyle(.secondary)

                TextField(L10n.EditProfile.bio, text: $viewModel.bio, axis: .vertical)
                    .font(DS.Font.subheadline)
                    .lineLimit(3...5)

                HStack {
                    Spacer()
                    Text("\(viewModel.bioCharacterCount)/\(DS.Layout.maxBioLength)")
                        .font(DS.Font.caption)
                        .foregroundStyle(viewModel.isBioValid ? .secondary : ColorTokens.destructive)
                }
            }
        }
    }
}
