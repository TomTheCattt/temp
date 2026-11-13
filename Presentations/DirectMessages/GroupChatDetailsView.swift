//
//  GroupChatDetailsView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - GroupChatDetailsView

struct GroupChatDetailsView: View {

    let conversationId: String

    @State private var viewModel: GroupChatDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    init(conversationId: String) {
        self.conversationId = conversationId
        _viewModel = State(initialValue: GroupChatDetailsViewModel(
            conversationId: conversationId,
            groupChatUseCase: DIContainer.shared.resolve(GroupChatUseCaseProtocol.self)
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.md) {
                    // Group Header
                    groupHeaderSection

                    Divider().padding(.horizontal, DS.Padding.horizontal)

                    // Notification Settings
                    notificationsSection

                    Divider().padding(.horizontal, DS.Padding.horizontal)

                    // Members
                    membersSection

                    Divider().padding(.horizontal, DS.Padding.horizontal)

                    // Media & Links
                    sharedMediaSection

                    Divider().padding(.horizontal, DS.Padding.horizontal)

                    // Actions
                    actionsSection
                }
                .padding(.vertical, DS.Spacing.md)
            }
            .navigationTitle(L10n.GroupChat.detailsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        dismiss()
                    } label: {
                        InstagramIcon(.chevronLeft, size: 20, color: Color.primary)
                    }
                }
            }
            .task {
                await viewModel.loadDetails()
            }
            .confirmationDialog(
                L10n.GroupChat.leaveConfirmation,
                isPresented: $viewModel.showLeaveConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.GroupChat.leaveGroup, role: .destructive) {
                    Task {
                        await viewModel.leaveGroup()
                    }
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            }
            .confirmationDialog(
                L10n.GroupChat.deleteConfirmation,
                isPresented: $viewModel.showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.Common.delete, role: .destructive) {
                    Task {
                        await viewModel.deleteGroup()
                    }
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            }
        }
    }

    // MARK: - Subviews

    private var groupHeaderSection: some View {
        VStack(spacing: DS.Spacing.md) {
            // Group Avatar
            ZStack(alignment: .bottomTrailing) {
                GroupAvatarView(avatarURL: viewModel.groupAvatarURL, name: viewModel.groupName, size: 100)

                // Edit avatar button (for admins)
                if viewModel.isAdmin {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        viewModel.showAvatarPicker = true
                    } label: {
                        InstagramIcon(.system(name: "camera.fill"), size: 18, color: .white)
                            .frame(width: 32, height: 32)
                            .background(ColorTokens.accentPrimary, in: Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    .offset(x: 4, y: 4)
                }
            }

            // Group Name
            VStack(spacing: DS.Spacing.xs) {
                Text(viewModel.groupName)
                    .font(DS.Font.title3)
                    .foregroundStyle(.primary)

                if viewModel.isAdmin {
                    Text(L10n.GroupChat.tapToEdit)
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onTapGesture {
                if viewModel.isAdmin {
                    viewModel.showEditName = true
                }
            }

            // Member Count
            Text(String(format: L10n.GroupChat.memberCount, viewModel.memberCount))
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)

            // Admin badge
            if viewModel.isAdmin {
                Label(L10n.GroupChat.admin, systemImage: "star.fill")
                    .font(DS.Font.captionBold)
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.xxs)
                    .background(Color.yellow.opacity(0.15), in: Capsule())
            }
        }
        .padding(.top, DS.Spacing.sm)
    }

    private var notificationsSection: some View {
        VStack(spacing: DS.Spacing.xs) {
            Toggle(isOn: $viewModel.muteMessages) {
                HStack {
                    InstagramIcon(.system(name: "bell.slash"), size: 20, color: .primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.GroupChat.muteMessages)
                            .font(DS.Font.body)
                        Text(L10n.GroupChat.muteMessagesSubtitle)
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(ColorTokens.accentPrimary)
            .onChange(of: viewModel.muteMessages) { _, newValue in
                Task { await viewModel.updateMuteMessages(newValue) }
            }

            Toggle(isOn: $viewModel.muteCalls) {
                HStack {
                    InstagramIcon(.system(name: "phone.down"), size: 20, color: .primary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.GroupChat.muteCalls)
                            .font(DS.Font.body)
                        Text(L10n.GroupChat.muteCallsSubtitle)
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(ColorTokens.accentPrimary)
            .onChange(of: viewModel.muteCalls) { _, newValue in
                Task { await viewModel.updateMuteCalls(newValue) }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Text(L10n.GroupChat.members)
                    .font(DS.Font.headline)
                Spacer()
                NavigationLink {
                    GroupMembersListView(viewModel: viewModel)
                } label: {
                    Text(L10n.Common.seeAll)
                        .font(DS.Font.caption)
                        .foregroundStyle(ColorTokens.accentPrimary)
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.sm) {
                    ForEach(viewModel.members.prefix(10)) { member in
                        MemberAvatarView(
                            member: member,
                            isAdmin: viewModel.adminIds.contains(member.id),
                            size: 56
                        )
                    }

                    if viewModel.members.count > 10 {
                        Button {
                            HapticFeedbackSafe.impact(.light)
                            // Navigate to full members list
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(ColorTokens.backgroundSecondary)
                                    .frame(width: 56, height: 56)
                                Text("+\(viewModel.members.count - 10)")
                                    .font(DS.Font.captionBold)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }

            // Add Member Button (for admins)
            if viewModel.isAdmin {
                Button {
                    HapticFeedbackSafe.impact(.light)
                    viewModel.showAddMembers = true
                } label: {
                    HStack {
                        Spacer()
                        InstagramIcon(.system(name: "person.badge.plus"), size: 20, color: ColorTokens.accentPrimary)
                        Text(L10n.GroupChat.addMembers)
                            .font(DS.Font.subheadline)
                            .foregroundStyle(ColorTokens.accentPrimary)
                        Spacer()
                    }
                    .padding(.vertical, DS.Spacing.sm)
                    .background(ColorTokens.accentPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: DS.Radius.medium))
                }
                .padding(.horizontal, DS.Padding.horizontal)
            }
        }
    }

    private var sharedMediaSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack {
                Text(L10n.GroupChat.mediaLinks)
                    .font(DS.Font.headline)
                Spacer()
                Text(L10n.Common.seeAll)
                    .font(DS.Font.caption)
                    .foregroundStyle(ColorTokens.accentPrimary)
            }
            .padding(.horizontal, DS.Padding.horizontal)

            // Media grid preview
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.xxs), count: 3), spacing: DS.Spacing.xxs) {
                ForEach(0..<min(viewModel.sharedMedia.count, 6), id: \.self) { index in
                    if index < viewModel.sharedMedia.count {
                        SharedMediaThumbnail(media: viewModel.sharedMedia[index])
                    } else {
                        // Placeholder
                        ZStack {
                            ColorTokens.buttonSecondary
                            InstagramIcon(.picture, size: 24, color: .secondary)
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                    }
                }
            }
            .padding(.horizontal, DS.Padding.horizontal)
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            if viewModel.isAdmin {
                // Admin actions
                Button {
                    HapticFeedbackSafe.impact(.light)
                    viewModel.showEditName = true
                } label: {
                    actionRow(icon: "pencil", title: L10n.GroupChat.editGroupName, color: .primary)
                }

                Button {
                    HapticFeedbackSafe.impact(.light)
                    viewModel.showAvatarPicker = true
                } label: {
                    actionRow(icon: "camera", title: L10n.GroupChat.changeGroupPhoto, color: .primary)
                }

                Divider().padding(.horizontal, DS.Padding.horizontal)
            }

            // Member actions
            NavigationLink {
                GroupMembersListView(viewModel: viewModel)
            } label: {
                actionRow(icon: "person.2", title: L10n.GroupChat.viewMembers, color: .primary)
            }

            Divider().padding(.horizontal, DS.Padding.horizontal)

            // Report
            Button {
                HapticFeedbackSafe.impact(.light)
                viewModel.reportGroup()
            } label: {
                actionRow(icon: "flag", title: L10n.GroupChat.reportGroup, color: .red)
            }

            Divider().padding(.horizontal, DS.Padding.horizontal)

            // Leave / Delete
            if viewModel.isAdmin {
                Button {
                    HapticFeedbackSafe.impact(.medium)
                    viewModel.showDeleteConfirmation = true
                } label: {
                    actionRow(icon: "trash", title: L10n.GroupChat.deleteGroup, color: .red)
                }
            } else {
                Button {
                    HapticFeedbackSafe.impact(.medium)
                    viewModel.showLeaveConfirmation = true
                } label: {
                    actionRow(icon: "rectangle.portrait.and.arrow.right", title: L10n.GroupChat.leaveGroup, color: .red)
                }
            }
        }
        .padding(.horizontal, DS.Padding.horizontal)
    }

    private func actionRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: DS.Spacing.md) {
            InstagramIcon(.system(name: icon), size: 20, color: color)
                .frame(width: 24)
            Text(title)
                .font(DS.Font.body)
                .foregroundStyle(color)
            Spacer()
            InstagramIcon(.chevronRight, size: 14, color: .secondary)
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}

// MARK: - Supporting Views

private struct GroupAvatarView: View {
    let avatarURL: URL?
    let name: String
    let size: CGFloat

    var body: some View {
        ZStack {
            if let url = avatarURL {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var defaultAvatar: some View {
        Circle()
            .fill(ColorTokens.accentPrimary.gradient)
            .overlay {
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

private struct MemberAvatarView: View {
    let member: GroupMember
    let isAdmin: Bool
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LazyImage(url: member.avatarURL) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Circle().fill(ColorTokens.buttonSecondary)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())

            if isAdmin {
                Image(systemName: "star.fill")
                    .font(.system(size: size * 0.2, weight: .bold))
                    .foregroundStyle(.yellow)
                    .frame(width: size * 0.35, height: size * 0.35)
                    .background(Color(UIColor.systemBackground), in: Circle())
                    .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                    .offset(x: size * 0.05, y: size * 0.05)
            }
        }
    }
}

private struct SharedMediaThumbnail: View {
    let media: SharedMediaItem

    var body: some View {
        ZStack {
            if let url = media.thumbnailURL {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        ColorTokens.buttonSecondary
                    }
                }
            } else {
                ColorTokens.buttonSecondary
            }

            if media.isVideo {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.black.opacity(0.6), in: Circle())
                    }
                    .padding(DS.Spacing.xxs)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

// MARK: - Group Members List View

private struct GroupMembersListView: View {
    @Bindable var viewModel: GroupChatDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(viewModel.members) { member in
                HStack(spacing: DS.Spacing.md) {
                    LazyImage(url: member.avatarURL) { state in
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            Circle().fill(ColorTokens.buttonSecondary)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                        HStack(spacing: DS.Spacing.xxs) {
                            Text(member.fullName.isEmpty ? member.username : member.fullName)
                                .font(DS.Font.subheadline)
                            if viewModel.adminIds.contains(member.id) {
                                Text(L10n.GroupChat.admin)
                                    .font(DS.Font.caption2Bold)
                                    .foregroundStyle(.yellow)
                                    .padding(.horizontal, DS.Spacing.xxs)
                                    .padding(.vertical, 1)
                                    .background(Color.yellow.opacity(0.2), in: Capsule())
                            }
                        }
                        Text("@\(member.username)")
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, DS.Spacing.xxs)
            }
        }
        .navigationTitle(L10n.GroupChat.members)
        .navigationBarTitleDisplayMode(.inline)
    }
}


