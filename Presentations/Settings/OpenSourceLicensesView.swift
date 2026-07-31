//
//  OpenSourceLicensesView.swift
//  Instagram
//
//  Created by Kiro on 31/7/26.
//

import SwiftUI

// MARK: - OpenSourceLicensesView

struct OpenSourceLicensesView: View {

    var body: some View {
        List {
            ForEach(licenses, id: \.name) { license in
                DisclosureGroup {
                    Text(license.text)
                        .font(DS.Font.caption)
                        .foregroundStyle(.secondary)
                } label: {
                    VStack(alignment: .leading, spacing: DS.Spacing.xxxs) {
                        Text(license.name)
                            .font(DS.Font.subheadlineBold)
                        Text(license.url)
                            .font(DS.Font.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - License Data

    private var licenses: [LicenseInfo] {
        [
            LicenseInfo(
                name: "Swinject",
                url: "https://github.com/Swinject/Swinject",
                text: "MIT License\n\nCopyright (c) 2015 Swinject Contributors\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software."
            ),
            LicenseInfo(
                name: "Nuke",
                url: "https://github.com/kean/Nuke",
                text: "MIT License\n\nCopyright (c) 2015-2024 Alexander Grebenyuk\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software."
            ),
            LicenseInfo(
                name: "Starscream",
                url: "https://github.com/daltoniam/Starscream",
                text: "Apache License 2.0\n\nCopyright (c) 2014-2016 Dalton Cherry\n\nLicensed under the Apache License, Version 2.0."
            )
        ]
    }
}

// MARK: - LicenseInfo

private struct LicenseInfo {
    let name: String
    let url: String
    let text: String
}
