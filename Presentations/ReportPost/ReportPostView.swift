//
//  ReportPostView.swift
//  Instagram
//
//  Created by Kiro on 28/7/26.
//

import SwiftUI

// MARK: - ReportReason

enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "It's spam"
    case nudity = "Nudity or sexual activity"
    case hateSpeech = "Hate speech or symbols"
    case violence = "Violence or dangerous organizations"
    case bullying = "Bullying or harassment"
    case falseInfo = "False information"
    case scam = "Scam or fraud"
    case intellectualProperty = "Intellectual property violation"
    case selfHarm = "Suicide or self-injury"
    case other = "Something else"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spam:                  return "xmark.circle"
        case .nudity:                return "eye.slash"
        case .hateSpeech:            return "exclamationmark.bubble"
        case .violence:              return "flame"
        case .bullying:              return "person.2.slash"
        case .falseInfo:             return "info.circle"
        case .scam:                  return "creditcard.trianglebadge.exclamationmark"
        case .selfHarm:              return "heart.slash"
        case .intellectualProperty:  return "doc.badge.ellipsis"
        case .other:                 return "ellipsis.circle"
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
                Text("Why are you reporting this post?")
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
                            Image(systemName: reason.icon)
                                .font(DS.Font.body)
                                .foregroundStyle(.primary)
                                .frame(width: DS.Size.iconDefault)

                            Text(reason.rawValue)
                                .font(DS.Font.subheadline)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(DS.Font.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Report")
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

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DS.Size.iconJumbo))
                .foregroundStyle(ColorTokens.success)

            Text("Thanks for letting us know")
                .font(DS.Font.title3)

            Text("We'll review this post and take action if it goes against our Community Guidelines.")
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
        .navigationTitle("Report")
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
