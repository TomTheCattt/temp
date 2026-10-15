//
//  NewMessageSheet.swift
//  Instagram
//
//  Created by Antigravity on 15/10/26.
//

import SwiftUI
import NukeUI

// MARK: - NewMessageSheet

struct NewMessageSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedUsers: [User] = []
    @State private var suggestedUsers: [User] = []
    @State private var isCreating = false

    private let messageRepository: MessageRepositoryProtocol = DIContainer.shared.resolve(MessageRepositoryProtocol.self)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // "To: " and Chips Search Box
                toInputSection

                Divider()

                // List of users
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if filteredUsers.isEmpty {
                            EmptyStateView(
                                message: "Không tìm thấy người dùng phù hợp",
                                systemImage: "person.slash"
                            )
                            .padding(.top, DS.Spacing.xxl)
                        } else {
                            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                                Text(selectedUsers.isEmpty ? "Gợi ý" : "Người dùng")
                                    .font(DS.Font.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, DS.Padding.horizontal)
                                    .padding(.top, DS.Spacing.xs)

                                ForEach(filteredUsers) { user in
                                    userSelectRow(user)
                                        .padding(.horizontal, DS.Padding.horizontal)
                                        .padding(.vertical, DS.Spacing.xxs)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(selectedUsers.count > 1 ? "Nhóm mới" : "Tin nhắn mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .tint(.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(selectedUsers.count > 1 ? "Tạo nhóm" : "Chat") {
                        HapticFeedbackSafe.impact(.medium)
                        Task { await handleStartChat() }
                    }
                    .fontWeight(.bold)
                    .tint(ColorTokens.accentPrimary)
                    .disabled(selectedUsers.isEmpty || isCreating)
                }
            }
            .task {
                loadSuggestedUsers()
            }
        }
    }

    // MARK: - To Input Section

    private var toInputSection: some View {
        HStack(alignment: .center, spacing: DS.Spacing.xs) {
            Text("Đến:")
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)

            // Chips of selected users
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.xxs) {
                    ForEach(selectedUsers) { user in
                        HStack(spacing: 4) {
                            Text(user.username)
                                .font(DS.Font.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(ColorTokens.accentPrimary)

                            Button {
                                withAnimation {
                                    selectedUsers.removeAll { $0.id == user.id }
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ColorTokens.accentPrimary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(ColorTokens.accentPrimary.opacity(0.12), in: Capsule())
                    }

                    TextField("Tìm kiếm...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(DS.Font.subheadline)
                        .frame(minWidth: 120)
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
        .padding(.vertical, DS.Spacing.xs)
    }

    // MARK: - User Select Row

    private func userSelectRow(_ user: User) -> some View {
        let isSelected = selectedUsers.contains { $0.id == user.id }

        return Button {
            HapticFeedbackSafe.impact(.light)
            withAnimation {
                if isSelected {
                    selectedUsers.removeAll { $0.id == user.id }
                } else {
                    selectedUsers.append(user)
                }
            }
        } label: {
            HStack(spacing: DS.Spacing.sm) {
                LazyImage(url: user.avatarURL) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Circle().fill(ColorTokens.buttonSecondary)
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(user.username)
                            .font(DS.Font.headline)
                            .foregroundStyle(Color.primary)

                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(DS.Font.caption2)
                                .foregroundStyle(ColorTokens.accentPrimary)
                        }
                    }

                    Text(user.fullName.isEmpty ? user.username : user.fullName)
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Checkbox Circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? ColorTokens.accentPrimary : Color.gray.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(ColorTokens.accentPrimary)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .contentShape(Rectangle())
        }
    }

    // MARK: - Computed Properties

    private var filteredUsers: [User] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return suggestedUsers
        }
        let lower = searchText.lowercased()
        return suggestedUsers.filter {
            $0.username.lowercased().contains(lower) || $0.fullName.lowercased().contains(lower)
        }
    }

    // MARK: - Actions

    private func loadSuggestedUsers() {
        suggestedUsers = MockData.users.filter { $0.id != SessionStore.shared.currentUserId }
    }

    private func handleStartChat() async {
        guard !selectedUsers.isEmpty else { return }
        isCreating = true

        let userIds = selectedUsers.map(\.id)
        let firstUser = selectedUsers.first

        do {
            let conv = try await messageRepository.createConversation(participantIds: userIds)
            dismiss()
            // Small delay for sheet dismiss animation
            try? await Task.sleep(nanoseconds: 300_000_000)
            AppRouter.shared.push(.conversation(conversationId: conv.id, recipient: firstUser))
        } catch {
            ToastManager.shared.error(error.userMessage)
        }

        isCreating = false
    }
}
