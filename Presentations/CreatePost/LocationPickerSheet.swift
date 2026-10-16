//
//  LocationPickerSheet.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI

// MARK: - LocationPickerSheet

struct LocationPickerSheet: View {

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    let onSelectLocation: (PostLocation) -> Void

    private let predefinedLocations: [PostLocation] = [
        PostLocation(name: "Ho Chi Minh City, Vietnam", latitude: 10.8231, longitude: 106.6297),
        PostLocation(name: "Hanoi, Vietnam", latitude: 21.0285, longitude: 105.8542),
        PostLocation(name: "Da Nang, Vietnam", latitude: 16.0544, longitude: 108.2022),
        PostLocation(name: "Phu Quoc Island, Vietnam", latitude: 10.2899, longitude: 103.9840),
        PostLocation(name: "Tokyo, Japan", latitude: 35.6762, longitude: 139.6503),
        PostLocation(name: "Seoul, South Korea", latitude: 37.5665, longitude: 126.9780),
        PostLocation(name: "Singapore", latitude: 1.3521, longitude: 103.8198),
        PostLocation(name: "New York, USA", latitude: 40.7128, longitude: -74.0060),
        PostLocation(name: "Paris, France", latitude: 48.8566, longitude: 2.3522),
        PostLocation(name: "London, United Kingdom", latitude: 51.5074, longitude: -0.1278)
    ]

    private var filteredLocations: [PostLocation] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return predefinedLocations
        }
        return predefinedLocations.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty && !filteredLocations.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                    Section {
                        Button {
                            select(PostLocation(name: trimmed, latitude: nil, longitude: nil))
                        } label: {
                            HStack {
                                InstagramIcon(.system(name: "mappin.circle.fill"), size: DS.Size.iconDefault, color: ColorTokens.accentPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(trimmed)
                                        .font(DS.Font.body)
                                        .foregroundStyle(.primary)
                                    Text("Use custom location")
                                        .font(DS.Font.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section("Suggestions") {
                    ForEach(filteredLocations, id: \.name) { loc in
                        Button {
                            select(loc)
                        } label: {
                            HStack {
                                InstagramIcon(.system(name: "mappin.and.ellipse"), size: DS.Size.iconDefault, color: .secondary)
                                    .frame(width: 24)
                                Text(loc.name)
                                    .font(DS.Font.body)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search location...")
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func select(_ location: PostLocation) {
        onSelectLocation(location)
        dismiss()
    }
}
