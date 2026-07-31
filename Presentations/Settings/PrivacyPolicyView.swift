//
//  PrivacyPolicyView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - PrivacyPolicyView

struct PrivacyPolicyView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Privacy Policy")
                    .font(DS.Font.titleRegular)
                    .fontWeight(.bold)

                Text("Last updated: July 2026")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)

                Group {
                    sectionContent(
                        title: "1. Information We Collect",
                        body: "We collect information you provide directly, such as your profile data, photos, and messages. We also collect usage data, device information, and location data when you use our services."
                    )

                    sectionContent(
                        title: "2. How We Use Information",
                        body: "We use collected information to provide and improve our services, personalize your experience, communicate with you, and ensure the safety of our platform."
                    )

                    sectionContent(
                        title: "3. Information Sharing",
                        body: "We do not sell your personal information. We may share information with service providers, for legal reasons, or when you consent to sharing."
                    )

                    sectionContent(
                        title: "4. Data Retention",
                        body: "We retain your information as long as your account is active or as needed to provide services. You can request deletion of your data at any time."
                    )

                    sectionContent(
                        title: "5. Your Rights",
                        body: "You have the right to access, correct, or delete your personal data. You can also object to processing or request data portability."
                    )
                }
            }
            .padding(DS.Padding.horizontal)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionContent(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(title)
                .font(DS.Font.subheadlineBold)
            Text(body)
                .font(DS.Font.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, DS.Spacing.xs)
    }
}
