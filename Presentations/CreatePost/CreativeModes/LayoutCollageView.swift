//
//  LayoutCollageView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import PhotosUI

// MARK: - LayoutGridPreset

enum LayoutGridPreset: String, CaseIterable, Identifiable {
    case grid2x2 = "2x2"
    case grid1x2 = "1x2"
    case grid2x1 = "2x1"

    var id: String { rawValue }

    var cellCount: Int {
        switch self {
        case .grid2x2: return 4
        case .grid1x2: return 2
        case .grid2x1: return 2
        }
    }
}

// MARK: - LayoutCollageView

/// Instagram Layout / Grid Collage Mode:
/// Divides canvas into grid cells (2x2, 1x2, 2x1), allows picking photos for each cell,
/// and merges them into a single high-res composite image.
struct LayoutCollageView: View {

    @Binding var isPresented: Bool
    let onCollageCompleted: (Data) -> Void

    @State private var activePreset: LayoutGridPreset = .grid2x2
    @State private var cellImages: [Data?] = Array(repeating: nil, count: 4)
    @State private var activeCellIndex: Int = 0
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.md) {
                // Top Preset Selector
                Picker("Bố cục", selection: $activePreset) {
                    ForEach(LayoutGridPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DS.Padding.horizontal)
                .onChange(of: activePreset) { _, newPreset in
                    cellImages = Array(repeating: nil, count: newPreset.cellCount)
                }

                // Grid Canvas
                ZStack {
                    Color.black

                    switch activePreset {
                    case .grid2x2:
                        VStack(spacing: 3) {
                            HStack(spacing: 3) {
                                cellView(0)
                                cellView(1)
                            }
                            HStack(spacing: 3) {
                                cellView(2)
                                cellView(3)
                            }
                        }
                    case .grid1x2:
                        HStack(spacing: 3) {
                            cellView(0)
                            cellView(1)
                        }
                    case .grid2x1:
                        VStack(spacing: 3) {
                            cellView(0)
                            cellView(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.input))
                .padding(.horizontal, DS.Padding.horizontal)

                Spacer()

                // Instructions & PhotosPicker
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label("Chọn ảnh cho ô đang chọn", systemImage: "photo.stack")
                        .font(DS.Font.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.formGap)
                        .background(ColorTokens.buttonPrimary, in: RoundedRectangle(cornerRadius: DS.Radius.input))
                        .padding(.horizontal, DS.Padding.horizontal)
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                if activeCellIndex < cellImages.count {
                                    cellImages[activeCellIndex] = data
                                    // Auto advance to next empty cell
                                    if let nextEmpty = cellImages.firstIndex(where: { $0 == nil }) {
                                        activeCellIndex = nextEmpty
                                    }
                                }
                                selectedPhotoItem = nil
                            }
                        }
                    }
                }

                Spacer().frame(height: DS.Spacing.md)
            }
            .navigationTitle("Ghép ảnh (Layout)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { isPresented = false }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        exportCollage()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .disabled(cellImages.compactMap { $0 }.isEmpty)
                }
            }
        }
    }

    // MARK: - Cell View

    @ViewBuilder
    private func cellView(_ index: Int) -> some View {
        let isSelected = activeCellIndex == index
        let imageData = index < cellImages.count ? cellImages[index] : nil

        ZStack {
            Color(.systemGray6)

            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                VStack(spacing: DS.Spacing.xxs) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Ô \(index + 1)")
                        .font(DS.Font.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            Rectangle()
                .stroke(isSelected ? ColorTokens.accentPrimary : Color.clear, lineWidth: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            activeCellIndex = index
        }
    }

    // MARK: - Export

    private func exportCollage() {
        let renderSize = CGSize(width: 1080, height: 1080)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0

        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        let composite = renderer.image { _ in
            let spacing: CGFloat = 4
            let halfWidth = (renderSize.width - spacing) / 2
            let halfHeight = (renderSize.height - spacing) / 2

            switch activePreset {
            case .grid2x2:
                let rects = [
                    CGRect(x: 0, y: 0, width: halfWidth, height: halfHeight),
                    CGRect(x: halfWidth + spacing, y: 0, width: halfWidth, height: halfHeight),
                    CGRect(x: 0, y: halfHeight + spacing, width: halfWidth, height: halfHeight),
                    CGRect(x: halfWidth + spacing, y: halfHeight + spacing, width: halfWidth, height: halfHeight)
                ]
                for (i, rect) in rects.enumerated() {
                    if i < cellImages.count, let data = cellImages[i], let img = UIImage(data: data) {
                        img.draw(in: rect)
                    }
                }
            case .grid1x2:
                let rects = [
                    CGRect(x: 0, y: 0, width: halfWidth, height: renderSize.height),
                    CGRect(x: halfWidth + spacing, y: 0, width: halfWidth, height: renderSize.height)
                ]
                for (i, rect) in rects.enumerated() {
                    if i < cellImages.count, let data = cellImages[i], let img = UIImage(data: data) {
                        img.draw(in: rect)
                    }
                }
            case .grid2x1:
                let rects = [
                    CGRect(x: 0, y: 0, width: renderSize.width, height: halfHeight),
                    CGRect(x: 0, y: halfHeight + spacing, width: renderSize.width, height: halfHeight)
                ]
                for (i, rect) in rects.enumerated() {
                    if i < cellImages.count, let data = cellImages[i], let img = UIImage(data: data) {
                        img.draw(in: rect)
                    }
                }
            }
        }

        if let jpeg = composite.jpegData(compressionQuality: 0.85) {
            onCollageCompleted(jpeg)
            isPresented = false
        }
    }
}
