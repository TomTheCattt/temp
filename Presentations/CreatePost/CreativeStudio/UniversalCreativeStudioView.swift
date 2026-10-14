//
//  UniversalCreativeStudioView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import PhotosUI

// MARK: - StudioEditTab

enum StudioEditTab: String, CaseIterable, Identifiable {
    case filter = "Bộ lọc"
    case stickers = "Thêm ảnh"
    case text = "Chữ"

    var id: String { rawValue }
}

// MARK: - UniversalCreativeStudioView

/// Universal multi-layer creative studio matching Instagram iOS:
/// Applies Photo PIP stickers, Typography overlays, and Metal GPU filters
/// equally across any source media (library image/video, camera capture, canvas, or layout).
struct UniversalCreativeStudioView: View {

    @Binding var baseImageData: Data
    @Binding var selectedFilterId: String
    @Binding var filterIntensity: Float
    let onProceedToCaption: (Data) -> Void

    @State private var stickers: [PIPStickerItem] = []
    @State private var texts: [TextOverlayItem] = []
    @State private var activeTab: StudioEditTab = .filter
    @State private var selectedPIPItem: PhotosPickerItem?
    @State private var isShowingTextDialog: Bool = false
    @State private var newTextContent: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Main Creative Canvas Area
            ZStack {
                Color.black

                if let uiImage = ImageDownsampler.shared.downsample(data: baseImageData, maxDimension: 1080) {
                    // Filtered Base Image
                    FilterSelectionView(
                        selectedFilterId: $selectedFilterId,
                        filterIntensity: $filterIntensity,
                        sourceImage: uiImage
                    )
                    .aspectRatio(1, contentMode: .fit)

                    // Multi-layer Overlays: Photo PIP Stickers
                    ForEach($stickers) { $sticker in
                        PhotoPIPStickerView(item: $sticker) {
                            stickers.removeAll { $0.id == sticker.id }
                        }
                    }

                    // Multi-layer Overlays: Typography
                    ForEach($texts) { $textItem in
                        TypographyOverlayView(item: $textItem) {
                            texts.removeAll { $0.id == textItem.id }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipped()

            // Studio Toolbar Controls
            HStack(spacing: DS.Spacing.xxl) {
                // Add Photo PIP Sticker from Library
                PhotosPicker(
                    selection: $selectedPIPItem,
                    matching: .images
                ) {
                    VStack(spacing: DS.Spacing.xxxs) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                        Text(L10n.CreatePost.addSticker)
                            .font(DS.Font.caption2)
                    }
                    .foregroundStyle(.primary)
                }
                .onChange(of: selectedPIPItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            await MainActor.run {
                                stickers.append(PIPStickerItem(imageData: data))
                                selectedPIPItem = nil
                            }
                        }
                    }
                }

                // Add Typography Text
                Button {
                    newTextContent = ""
                    isShowingTextDialog = true
                } label: {
                    VStack(spacing: DS.Spacing.xxxs) {
                        Image(systemName: "textformat")
                            .font(.title3)
                        Text(L10n.CreatePost.text)
                            .font(DS.Font.caption2)
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.vertical, DS.Spacing.sm)
            .background(Color(.secondarySystemBackground))

            Spacer()
        }
        .sheet(isPresented: $isShowingTextDialog) {
            textEditorSheet
        }
    }

    // MARK: - Text Editor Sheet

    private var textEditorSheet: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.lg) {
                TextField("Nhập chữ...", text: $newTextContent)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { isShowingTextDialog = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        if !newTextContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            texts.append(TextOverlayItem(text: newTextContent, hasBackground: true))
                        }
                        isShowingTextDialog = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(200)])
    }

    // MARK: - Composite Bake & Export

    public func bakeCurrentState() -> Data {
        guard let base = UIImage(data: baseImageData) else { return baseImageData }

        // First apply filter if not original
        var filteredBase = base
        if selectedFilterId != "original",
           let filter = FilterRegistry.filter(byId: selectedFilterId),
           let ciImage = CIImage(image: base) {
            let engine = FilterEngine.shared
            let outputCI = engine.apply(filter: filter, to: ciImage, intensity: filterIntensity)
            if let rendered = engine.renderToUIImage(outputCI) {
                filteredBase = rendered
            }
        }

        // Second bake stickers & texts over base
        let composite = CompositeImageRenderer.shared.render(
            baseImage: filteredBase,
            stickers: stickers,
            texts: texts,
            renderSize: CGSize(width: 1080, height: 1080)
        )

        return composite.jpegData(compressionQuality: 0.85) ?? baseImageData
    }
}
