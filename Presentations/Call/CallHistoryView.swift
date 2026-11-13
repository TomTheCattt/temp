//
//  CallHistoryView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI
import NukeUI

// MARK: - CallHistoryView

struct CallHistoryView: View {

    @State private var viewModel = CallHistoryViewModel(
        callHistoryUseCase: DIContainer.shared.resolve(CallHistoryUseCaseProtocol.self)
    )

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(CallHistoryViewModel.Filter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.title,
                                icon: filter.icon,
                                isSelected: viewModel.selectedFilter == filter
                            ) {
                                withAnimation(DS.Animation.standard) {
                                    viewModel.selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.vertical, DS.Spacing.xs)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())

                // MARK: - Call History
                if viewModel.isLoading && viewModel.filteredCalls.isEmpty {
                    loadingPlaceholder
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else if viewModel.filteredCalls.isEmpty {
                    emptyStateView
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.filteredCalls) { call in
                        CallHistoryRow(call: call)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: DS.Padding.horizontal, bottom: 0, trailing: DS.Padding.horizontal))
                            .onTapGesture {
                                HapticFeedbackSafe.impact(.light)
                                viewModel.selectCall(call)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteCall(id: call.id)
                                    }
                                } label: {
                                    Label(L10n.Common.delete, systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.loadCalls()
            }
            .navigationTitle(L10n.CallHistory.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        AppRouter.shared.pop()
                    } label: {
                        InstagramIcon(.chevronLeft, size: 20, color: Color.primary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.clearHistory()
                        } label: {
                            Label(L10n.CallHistory.clearAll, systemImage: "trash")
                        }
                    } label: {
                        InstagramIcon(.system(name: "ellipsis"), size: 20, color: Color.primary)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .task {
                await viewModel.loadCalls()
            }
            .sheet(item: $viewModel.selectedCall) { call in
                CallDetailSheet(call: call)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Subviews

    private var loadingPlaceholder: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text(L10n.Common.loading)
                .font(DS.Font.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xxl)
    }

    private var emptyStateView: some View {
        VStack(spacing: DS.Spacing.md) {
            InstagramIcon(.system(name: "phone"), size: 64, color: .secondary)
            Text(L10n.CallHistory.emptyTitle)
                .font(DS.Font.headline)
                .foregroundStyle(.primary)
            Text(L10n.CallHistory.emptyMessage)
                .font(DS.Font.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Padding.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xxl)
    }
}

// MARK: - Call History Row

private struct CallHistoryRow: View {
    let call: CallHistoryItem

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                LazyImage(url: call.otherUserAvatarURL) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Circle().fill(ColorTokens.buttonSecondary)
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())

                // Call type icon
                Image(systemName: call.type.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(call.type.color, in: Circle())
                    .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                    .offset(x: 4, y: 4)
            }

            // Call Info
            VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                HStack(spacing: DS.Spacing.xxs) {
                    Text(call.otherUserName)
                        .font(DS.Font.subheadlineBold)
                        .foregroundStyle(.primary)

                    // Direction indicator
                    Image(systemName: call.direction.icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(call.direction == .incoming ? ColorTokens.accentPrimary : .secondary)

                    if call.isMissed {
                        Text(L10n.CallHistory.missed)
                            .font(DS.Font.caption2Bold)
                            .foregroundStyle(.red)
                            .padding(.horizontal, DS.Spacing.xxs)
                            .padding(.vertical, 1)
                            .background(Color.red.opacity(0.15), in: Capsule())
                    }
                }

                HStack(spacing: DS.Spacing.xs) {
                    Text(call.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)

                    if let duration = call.duration {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(duration.formattedDuration)
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Call Back Button
            Button {
                HapticFeedbackSafe.impact(.light)
                // Initiate call back
            } label: {
                Image(systemName: call.type == .video ? "video.fill" : "phone.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .frame(width: 40, height: 40)
                    .background(ColorTokens.accentPrimary.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DS.Spacing.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(DS.Font.caption)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.xs)
            .background(
                isSelected ? ColorTokens.accentPrimary : ColorTokens.backgroundSecondary,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Call Detail Sheet

private struct CallDetailSheet: View {
    let call: CallHistoryItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: DS.Spacing.md) {
                        LazyImage(url: call.otherUserAvatarURL) { state in
                            if let image = state.image {
                                image.resizable().scaledToFill()
                            } else {
                                Circle().fill(ColorTokens.buttonSecondary)
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                            Text(call.otherUserName)
                                .font(DS.Font.headline)
                            Text("@\(call.otherUserUsername)")
                                .font(DS.Font.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, DS.Spacing.xs)
                }

                Section {
                    DetailRow(
                        icon: call.type.icon,
                        iconColor: call.type.color,
                        title: L10n.CallHistory.callType,
                        value: call.type.title
                    )

                    DetailRow(
                        icon: call.direction.icon,
                        iconColor: call.direction == .incoming ? ColorTokens.accentPrimary : .secondary,
                        title: L10n.CallHistory.direction,
                        value: call.direction.title
                    )

                    DetailRow(
                        icon: "calendar",
                        iconColor: .secondary,
                        title: L10n.CallHistory.date,
                        value: call.startedAt.formatted(date: .complete, time: .complete)
                    )

                    if let duration = call.duration {
                        DetailRow(
                            icon: "clock",
                            iconColor: .secondary,
                            title: L10n.CallHistory.duration,
                            value: duration.formattedDuration
                        )
                    }

                    if call.isMissed {
                        DetailRow(
                            icon: "exclamationmark.circle",
                            iconColor: .red,
                            title: L10n.CallHistory.status,
                            value: L10n.CallHistory.missed
                        )
                    } else {
                        DetailRow(
                            icon: "checkmark.circle",
                            iconColor: .green,
                            title: L10n.CallHistory.status,
                            value: L10n.CallHistory.completed
                        )
                    }
                } header: {
                    Text(L10n.CallHistory.details)
                        .textCase(.uppercase)
                        .font(DS.Font.captionBold)
                }

                Section {
                    Button {
                        // Call back
                    } label: {
                        HStack {
                            Spacer()
                            Text(call.type == .video ? L10n.CallHistory.videoCall : L10n.CallHistory.audioCall)
                                .font(DS.Font.body)
                                .foregroundStyle(ColorTokens.accentPrimary)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(L10n.CallHistory.detailTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            Text(title)
                .font(DS.Font.body)
                .foregroundStyle(.primary)

            Spacer()

            Text(value)
                .font(DS.Font.body)
                .foregroundStyle(.secondary)
        }
    }
}

