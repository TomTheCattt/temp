//
//  InteractiveStickers.swift
//  Instagram
//
//  Created by Kiro on 15/10/26.
//

import SwiftUI
import MapKit

// MARK: - PollStickerItem

public struct PollStickerItem: Identifiable {
    public let id: UUID
    public var question: String
    public var optionA: String
    public var optionB: String
    public var votesA: Int
    public var votesB: Int
    public var offset: CGSize
    public var scale: CGFloat

    public init(
        id: UUID = UUID(),
        question: String = "Có thích điều này không?",
        optionA: String = "CÓ",
        optionB: String = "KHÔNG",
        votesA: Int = 1,
        votesB: Int = 0,
        offset: CGSize = .zero,
        scale: CGFloat = 1.0
    ) {
        self.id = id
        self.question = question
        self.optionA = optionA
        self.optionB = optionB
        self.votesA = votesA
        self.votesB = votesB
        self.offset = offset
        self.scale = scale
    }

    public var totalVotes: Int {
        max(1, votesA + votesB)
    }

    public var percentageA: Int {
        Int((Double(votesA) / Double(totalVotes)) * 100.0)
    }

    public var percentageB: Int {
        100 - percentageA
    }
}

// MARK: - PollStickerView

public struct PollStickerView: View {
    @Binding var item: PollStickerItem
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var hasVoted: Bool = false
    @State private var selectedOption: Int? = nil

    public var body: some View {
        VStack(spacing: 12) {
            Text(item.question)
                .font(.system(size: 17, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .padding(.horizontal, 14)
                .padding(.top, 14)

            HStack(spacing: 8) {
                // Option A
                Button {
                    HapticFeedbackSafe.impact(.medium)
                    if !hasVoted {
                        item.votesA += 1
                        hasVoted = true
                        selectedOption = 0
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(hasVoted ? (selectedOption == 0 ? ColorTokens.accentPrimary.opacity(0.2) : Color(.systemGray6)) : Color(.systemGray6))

                        HStack {
                            Text(item.optionA)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(selectedOption == 0 ? ColorTokens.accentPrimary : .primary)
                            Spacer()
                            if hasVoted {
                                Text("\(item.percentageA)%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                    .frame(height: 44)
                }
                .buttonStyle(.plain)

                // Option B
                Button {
                    HapticFeedbackSafe.impact(.medium)
                    if !hasVoted {
                        item.votesB += 1
                        hasVoted = true
                        selectedOption = 1
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(hasVoted ? (selectedOption == 1 ? ColorTokens.accentPrimary.opacity(0.2) : Color(.systemGray6)) : Color(.systemGray6))

                        HStack {
                            Text(item.optionB)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(selectedOption == 1 ? ColorTokens.accentPrimary : .primary)
                            Spacer()
                            if hasVoted {
                                Text("\(item.percentageB)%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 14)
                    }
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 280)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
        .offset(x: item.offset.width + dragOffset.width, y: item.offset.height + dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { val in dragOffset = val.translation }
                .onEnded { val in
                    item.offset.width += val.translation.width
                    item.offset.height += val.translation.height
                    dragOffset = .zero
                }
        )
    }
}

// MARK: - LinkInputDialog

public struct LinkInputDialog: View {
    @Binding var isPresented: Bool
    let onAddLink: (String) -> Void

    @State private var urlText: String = "https://"

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Người xem Story có thể nhấn vào nhãn dán để truy cập liên kết này.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("URL", text: $urlText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding(DS.Spacing.md)
            .navigationTitle("Thêm liên kết")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong") {
                        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onAddLink(trimmed)
                        }
                        isPresented = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
}

// MARK: - LocationSearchSheet

public struct LocationSearchSheet: View {
    @Binding var isPresented: Bool
    let onSelectLocation: (String) -> Void

    @State private var searchText = ""

    private let presetLocations = [
        "Hà Nội, Việt Nam",
        "TP. Hồ Chí Minh",
        "Đà Nẵng, Việt Nam",
        "Hồ Gươm - Phố Đi Bộ",
        "Phố Cổ Hội An",
        "Đà Lạt, Lâm Đồng",
        "Landmark 81, TP.HCM",
        "Vịnh Hạ Long, Quảng Ninh"
    ]

    public var body: some View {
        NavigationStack {
            List {
                ForEach(filteredLocations, id: \.self) { place in
                    Button {
                        HapticFeedbackSafe.impact(.light)
                        onSelectLocation(place)
                        isPresented = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(place)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Tìm kiếm vị trí...")
            .navigationTitle("Vị trí")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { isPresented = false }
                }
            }
        }
    }

    private var filteredLocations: [String] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return presetLocations
        }
        return presetLocations.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}
