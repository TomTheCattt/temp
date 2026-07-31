//
//  EditProfileView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI
import PhotosUI

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
            .navigationTitle(L10n.EditProfile.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
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
                    .disabled(viewModel.isSaving || !viewModel.isBioValid)
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
                VStack(spacing: DS.Spacing.xs) {
                    if let data = viewModel.newAvatarData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: DS.Size.avatarXLarge, height: DS.Size.avatarXLarge)
                            .clipShape(Circle())
                    } else {
                        AsyncImage(url: viewModel.currentAvatarURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.gray.opacity(DS.Opacity.low))
                        }
                        .frame(width: DS.Size.avatarXLarge, height: DS.Size.avatarXLarge)
                        .clipShape(Circle())
                    }

                    PhotosPicker(
                        selection: $viewModel.avatarPickerItem,
                        matching: .images
                    ) {
                        Text(L10n.EditProfile.changePhoto)
                            .font(DS.Font.subheadlineBold)
                            .foregroundStyle(ColorTokens.accentPrimary)
                    }
                }
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Profile Fields

    private var profileFieldsSection: some View {
        Section {
            LabeledContent(L10n.EditProfile.name) {
                TextField(L10n.EditProfile.name, text: $viewModel.name)
                    .multilineTextAlignment(.trailing)
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
