//
//  ReportPostView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - ReportReason UI Extensions

extension ReportReason: Identifiable {
    public var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .spam: return L10n.ReportPost.reasonSpam
        case .inappropriateContent: return L10n.ReportPost.reasonInappropriate
        case .harassment: return L10n.ReportPost.reasonHarassment
        case .hateSpeech: return L10n.ReportPost.reasonHateSpeech
        case .violence: return L10n.ReportPost.reasonViolence
        case .sexualContent: return L10n.ReportPost.reasonSexualContent
        case .selfHarm: return L10n.ReportPost.reasonSelfHarm
        case .fakeAccount: return L10n.ReportPost.reasonFakeAccount
        case .intellectualProperty: return L10n.ReportPost.reasonIntellectualProperty
        case .other: return L10n.ReportPost.reasonOther
        }
    }

    var icon: String {
        switch self {
        case .spam: return "xmark.circle"
        case .inappropriateContent: return "eye.slash"
        case .harassment: return "person.2.slash"
        case .hateSpeech: return "exclamationmark.bubble"
        case .violence: return "flame"
        case .sexualContent: return "eye.slash"
        case .selfHarm: return "heart.slash"
        case .fakeAccount: return "person.badge.questionmark"
        case .intellectualProperty: return "doc.badge.ellipsis"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - ReportPostView

struct ReportPostView: View {

    let postId: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var isSubmitted = false
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            if isSubmitted {
                submittedView
            } else {
                reasonSelectionView
            }
        }
    }

    // MARK: - Reason Selection

    private var reasonSelectionView: some View {
        List {
            Section {
                Text(L10n.ReportPost.question)
                    .font(DS.Font.subheadline)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(ReportReason.allCases) { reason in
                    Button(action: {
                        selectedReason = reason
                        submitReport()
                    }) {
                        HStack(spacing: DS.Spacing.sm) {
                            InstagramIcon(.system(name: reason.icon), size: DS.Size.iconDefault, color: .primary)
                                .frame(width: DS.Size.iconDefault)

                            Text(reason.displayTitle)
                                .font(DS.Font.subheadline)
                                .foregroundStyle(.primary)

                            Spacer()

                            InstagramIcon(.chevronRight, size: DS.Size.iconSmall, color: .secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.ReportPost.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.Common.cancel) { dismiss() }
            }
        }
        .overlay {
            if isSubmitting {
                Color.black.opacity(DS.Opacity.low)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.3)
            }
        }
    }

    // MARK: - Submitted View

    private var submittedView: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()

            InstagramIcon(.system(name: "checkmark.circle.fill"), size: DS.Size.iconJumbo, color: ColorTokens.success)

            Text(L10n.ReportPost.submittedTitle)
                .font(DS.Font.title3)

            Text(L10n.ReportPost.submittedMessage)
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xxl)

            Spacer()

            Button(action: { dismiss() }) {
                Text(L10n.Common.done)
                    .font(DS.Font.subheadlineBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.formGap)
                    .background(ColorTokens.accentPrimary, in: RoundedRectangle(cornerRadius: DS.Radius.input))
            }
            .padding(.horizontal)
            .padding(.bottom, DS.Spacing.lg)
        }
        .navigationTitle(L10n.ReportPost.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Submit

    private func submitReport() {
        isSubmitting = true

        // Simulate API call
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isSubmitting = false
            isSubmitted = true
        }
    }
}
