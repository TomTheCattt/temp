//
//  TermsOfServiceView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - TermsOfServiceView

struct TermsOfServiceView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.md) {
                Text("Terms of Service")
                    .font(DS.Font.titleRegular)
                    .fontWeight(.bold)

                Text("Last updated: July 2026")
                    .font(DS.Font.caption)
                    .foregroundStyle(.secondary)

                Group {
                    sectionContent(
                        title: "1. Agreement to Terms",
                        body: "By accessing or using our service, you agree to be bound by these Terms of Service and all applicable laws and regulations."
                    )

                    sectionContent(
                        title: "2. Use of Service",
                        body: "You must be at least 13 years old to use the service. You are responsible for maintaining the security of your account and all activity that occurs under it."
                    )

                    sectionContent(
                        title: "3. Content",
                        body: "You retain ownership of content you post. By posting content, you grant us a non-exclusive, royalty-free license to use, display, and distribute that content on our platform."
                    )

                    sectionContent(
                        title: "4. Prohibited Conduct",
                        body: "You agree not to use the service for any unlawful purpose, harass other users, post harmful content, or attempt to gain unauthorized access to the service."
                    )

                    sectionContent(
                        title: "5. Termination",
                        body: "We may terminate or suspend your account at any time for violations of these terms, without prior notice or liability."
                    )
                }
            }
            .padding(DS.Padding.horizontal)
        }
        .navigationTitle("Terms of Service")
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
