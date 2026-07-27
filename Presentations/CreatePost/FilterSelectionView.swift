//
//  FilterSelectionView.swift
//  Instagram
//
//  Created by Kiro on 26/7/26.
//

import SwiftUI

// MARK: - FilterSelectionView

/// Instagram-style filter picker: full image preview on top, horizontal thumbnail strip below.
struct FilterSelectionView: View {

    @Binding var selectedFilterId: String
    @Binding var filterIntensity: Float
    let sourceImage: UIImage

    @State private var thumbnails: [FilterThumbnail] = []
    @State private var previewImage: UIImage?
    @State private var isLoadingThumbnails = true
    @State private var showIntensitySlider = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Preview
            imagePreview
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()

            // MARK: Intensity Slider
            if showIntensitySlider && selectedFilterId != "original" {
                intensitySlider
            }

            // MARK: Filter Strip
            filterStrip
        }
        .background(Color(.systemBackground))
        .task {
            await loadThumbnails()
            updatePreview()
        }
        .onChange(of: selectedFilterId) { _, _ in
            updatePreview()
            // Show intensity slider briefly when selecting a new filter
            withAnimation(.easeInOut(duration: 0.2)) {
                showIntensitySlider = true
            }
        }
        .onChange(of: filterIntensity) { _, _ in
            updatePreview()
        }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        Group {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(uiImage: sourceImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
    }

    // MARK: - Intensity Slider

    private var intensitySlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: Binding(
                get: { Double(filterIntensity) },
                set: { filterIntensity = Float($0) }
            ), in: 0...1, step: 0.05)
            .tint(.primary)

            Text("\(Int(filterIntensity * 100))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 32)
                .monospacedDigit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Filter Strip

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                if isLoadingThumbnails {
                    ForEach(0..<8, id: \.self) { _ in
                        thumbnailPlaceholder
                    }
                } else {
                    ForEach(thumbnails) { thumbnail in
                        FilterThumbnailCell(
                            thumbnail: thumbnail,
                            isSelected: thumbnail.id == selectedFilterId
                        )
                        .onTapGesture {
                            if thumbnail.id == selectedFilterId && thumbnail.id != "original" {
                                // Double tap same filter: toggle intensity slider
                                withAnimation {
                                    showIntensitySlider.toggle()
                                }
                            } else {
                                selectedFilterId = thumbnail.id
                                filterIntensity = 1.0
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 110)
        .background(Color(.systemBackground))
    }

    private var thumbnailPlaceholder: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(width: 72, height: 72)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray6))
                .frame(width: 50, height: 10)
        }
    }

    // MARK: - Logic

    private func loadThumbnails() async {
        isLoadingThumbnails = true
        thumbnails = await FilterThumbnailGenerator.shared.generateThumbnails(for: sourceImage)
        isLoadingThumbnails = false
    }

    private func updatePreview() {
        guard let filter = FilterRegistry.filter(byId: selectedFilterId),
              let ciImage = CIImage(image: sourceImage) else {
            previewImage = sourceImage
            return
        }

        let engine = FilterEngine.shared
        let filtered = engine.apply(filter: filter, to: ciImage, intensity: filterIntensity)
        previewImage = engine.renderToUIImage(filtered)
    }
}

// MARK: - FilterThumbnailCell

struct FilterThumbnailCell: View {
    let thumbnail: FilterThumbnail
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(uiImage: thumbnail.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2.5)
                )

            Text(thumbnail.displayName)
                .font(.caption2)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
        }
        .frame(width: 72)
    }
}
