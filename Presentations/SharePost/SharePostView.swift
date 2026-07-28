//
//  SharePostView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - SharePostView

struct SharePostView: View {

    @State private var viewModel: SharePostViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""

    init(viewModel: SharePostViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: DS.Spacing.inputVertical) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(DS.Font.subheadline)
                }
                .padding(.horizontal, DS.Padding.content)
                .padding(.vertical, DS.Spacing.xs)
                .background(ColorTokens.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.input))
                .padding(.horizontal)
                .padding(.top, DS.Spacing.xs)

                // Share options
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Quick share row
                        quickShareSection

                        Divider().padding(.vertical, DS.Spacing.xs)

                        // Contacts / conversations
                        ForEach(viewModel.filteredUsers(query: searchQuery)) { user in
                            shareUserRow(user)
                        }
                    }
                }

                Divider()

                // Bottom: external share options
                externalShareBar
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadUsers()
            }
        }
    }

    // MARK: - Quick Share Section

    private var quickShareSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("Quick Share")
                .font(DS.Font.captionBold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.md) {
                    quickShareItem(icon: "plus.circle", label: "Add to Story")
                    quickShareItem(icon: "star.circle.fill", label: "Close Friends")
                    quickShareItem(icon: "link", label: "Copy Link")
                }
                .padding(.horizontal)
            }
        }
        .padding(.top, DS.Spacing.sm)
    }

    @ViewBuilder
    private func quickShareItem(icon: String, label: String) -> some View {
        Button(action: {
            if label == "Copy Link" {
                viewModel.copyLink()
                dismiss()
            }
        }) {
            VStack(spacing: DS.Spacing.iconGap) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: DS.Size.avatarStoryCircle, height: DS.Size.avatarStoryCircle)
                    .background(ColorTokens.buttonSecondary, in: Circle())
                Text(label)
                    .font(DS.Font.caption2)
                    .lineLimit(1)
            }
            .foregroundStyle(.primary)
        }
    }

    // MARK: - User Row

    @ViewBuilder
    private func shareUserRow(_ user: User) -> some View {
        let isSelected = viewModel.selectedUserIds.contains(user.id)

        HStack(spacing: DS.Spacing.sm) {
            AsyncImage(url: user.avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(DS.Opacity.low))
            }
            .frame(width: DS.Size.avatarList, height: DS.Size.avatarList)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                Text(user.username)
                    .font(DS.Font.username)
                Text(user.fullName)
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Selection circle
            Button(action: { viewModel.toggleUser(user.id) }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(DS.Font.title3)
                    .foregroundStyle(isSelected ? ColorTokens.accentPrimary : .secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, DS.Spacing.iconGap)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleUser(user.id) }
    }

    // MARK: - External Share Bar

    private var externalShareBar: some View {
        HStack(spacing: 0) {
            if !viewModel.selectedUserIds.isEmpty {
                // Send button
                Button(action: {
                    Task {
                        await viewModel.sendToSelected()
                        dismiss()
                    }
                }) {
                    Text("Send")
                        .font(DS.Font.subheadlineBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(ColorTokens.accentPrimary, in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
                .padding()
            } else {
                // External options
                HStack(spacing: DS.Spacing.xl) {
                    externalButton(icon: "message.fill", label: "Message")
                    externalButton(icon: "envelope.fill", label: "Email")
                    externalButton(icon: "square.and.arrow.up", label: "More")
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func externalButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: DS.Spacing.xxs) {
                Image(systemName: icon)
                    .font(DS.Font.title3)
                Text(label)
                    .font(DS.Font.caption2)
            }
            .foregroundStyle(.primary)
        }
    }
}
