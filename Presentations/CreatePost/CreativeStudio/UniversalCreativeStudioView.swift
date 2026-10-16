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
/// Displays a dedicated 1:1 square canvas at top for filtered base image,
/// interactive Photo PIP stickers, and Typography overlays.
/// Separates bottom toolbars (filters, stickers, typography) with native contrast.
struct UniversalCreativeStudioView: View {

    @Binding var baseImageData: Data
    @Binding var selectedFilterId: String
    @Binding var filterIntensity: Float
    @Binding var stickers: [PIPStickerItem]
    @Binding var texts: [TextOverlayItem]
    var onProceedToCaption: ((Data) -> Void)? = nil

    @State private var activeTab: StudioEditTab = .filter
    @State private var selectedPIPItem: PhotosPickerItem?
    @State private var filteredPreviewImage: UIImage?

    // Inline Text Editor State
    @State private var isEditingText = false
    @State private var editingItemId: UUID?
    @State private var editingText = ""
    @State private var editingColor: Color = .white
    @State private var editingHasBackground = true
    @State private var editingFontStyle: TextFontStyle = .modern
    @State private var editingAlignment: TextAlignment = .center
    @FocusState private var isFieldFocused: Bool

    private let availableColors: [Color] = [
        .white,
        .black,
        Color(red: 1.0, green: 0.85, blue: 0.0), // Yellow
        Color.orange,
        Color.red,
        Color.pink,
        Color.purple,
        Color.blue,
        Color.green
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: 1:1 Aspect Ratio Creative Canvas
                ZStack {
                    Color.black

                    if let sourceImage = ImageDownsampler.shared.downsample(data: baseImageData, maxDimension: 1080) {
                        // Filtered Base Image Preview
                        Image(uiImage: filteredPreviewImage ?? sourceImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                        // Multi-layer Overlays: Photo PIP Stickers
                        ForEach($stickers) { $sticker in
                            PhotoPIPStickerView(item: $sticker) {
                                stickers.removeAll { $0.id == sticker.id }
                            }
                        }

                        // Multi-layer Overlays: Typography with Tap-to-edit
                        ForEach($texts) { $textItem in
                            TypographyOverlayView(
                                item: $textItem,
                                onDelete: {
                                    texts.removeAll { $0.id == textItem.id }
                                },
                                onEdit: {
                                    startEditing(item: textItem)
                                }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()

                // MARK: Studio Toolbar Controls
                HStack(spacing: DS.Spacing.xxl) {
                    // Filter Tab
                    Button {
                        activeTab = .filter
                    } label: {
                        VStack(spacing: DS.Spacing.xxxs) {
                            InstagramIcon(.filters, size: 22, color: activeTab == .filter ? ColorTokens.accentPrimary : .secondary)
                            Text(L10n.CreatePost.filter)
                                .font(DS.Font.caption2)
                        }
                        .foregroundStyle(activeTab == .filter ? ColorTokens.accentPrimary : .secondary)
                    }

                    // Add Photo PIP Sticker from Library
                    PhotosPicker(
                        selection: $selectedPIPItem,
                        matching: .images
                    ) {
                        VStack(spacing: DS.Spacing.xxxs) {
                            InstagramIcon(.system(name: "photo.badge.plus"), size: 22, color: .secondary)
                            Text(L10n.CreatePost.addSticker)
                                .font(DS.Font.caption2)
                        }
                        .foregroundStyle(.secondary)
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
                        startEditing()
                    } label: {
                        VStack(spacing: DS.Spacing.xxxs) {
                            InstagramIcon(.text, size: 22, color: .secondary)
                            Text(L10n.CreatePost.text)
                                .font(DS.Font.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, DS.Spacing.sm)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))

                // MARK: Bottom Tool Panels
                if activeTab == .filter,
                   let sourceImage = ImageDownsampler.shared.downsample(data: baseImageData, maxDimension: 1080) {
                    FilterSelectionView(
                        selectedFilterId: $selectedFilterId,
                        filterIntensity: $filterIntensity,
                        sourceImage: sourceImage,
                        showsPreview: false
                    )
                }

                Spacer()
            }
            .background(Color(.systemBackground))
            .task(id: baseImageData) {
                updateFilteredPreview()
            }
            .onChange(of: selectedFilterId) { _, _ in
                updateFilteredPreview()
            }
            .onChange(of: filterIntensity) { _, _ in
                updateFilteredPreview()
            }

            // MARK: Inline Full-Screen Text Editor Overlay
            if isEditingText {
                inlineTextEditorOverlay
            }
        }
    }

    // MARK: - Filter Preview Update

    private func updateFilteredPreview() {
        guard let sourceImage = ImageDownsampler.shared.downsample(data: baseImageData, maxDimension: 1080) else {
            filteredPreviewImage = nil
            return
        }

        guard selectedFilterId != "original",
              let filter = FilterRegistry.filter(byId: selectedFilterId),
              let ciImage = CIImage(image: sourceImage) else {
            filteredPreviewImage = sourceImage
            return
        }

        let engine = FilterEngine.shared
        let filtered = engine.apply(filter: filter, to: ciImage, intensity: filterIntensity)
        filteredPreviewImage = engine.renderToUIImage(filtered)
    }

    // MARK: - Inline Text Editor Overlay

    private var inlineTextEditorOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    finishEditingText()
                }

            VStack(spacing: 0) {
                // Top Action Toolbar
                HStack(spacing: DS.Spacing.md) {
                    Button(L10n.Common.cancel) {
                        isEditingText = false
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(.white)

                    Spacer()

                    // Text Alignment Toggle Button
                    Button {
                        switch editingAlignment {
                        case .leading: editingAlignment = .center
                        case .center: editingAlignment = .trailing
                        case .trailing: editingAlignment = .leading
                        }
                    } label: {
                        InstagramIcon(.system(name: alignmentIconName), size: 18, color: .white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2), in: Circle())
                    }

                    // Background Badge Toggle Button
                    Button {
                        editingHasBackground.toggle()
                    } label: {
                        InstagramIcon(.system(name: editingHasBackground ? "character.textbox" : "textformat"), size: 18, color: editingHasBackground ? Color.black : Color.white)
                            .frame(width: 40, height: 40)
                            .background(editingHasBackground ? Color.white : Color.white.opacity(0.2), in: Circle())
                    }

                    // Done Button
                    Button(L10n.Common.done) {
                        finishEditingText()
                    }
                    .font(DS.Font.headline)
                    .foregroundStyle(ColorTokens.accentPrimary)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, DS.Spacing.xs)
                    .background(Color.white, in: Capsule())
                }
                .padding(.horizontal, DS.Padding.horizontal)
                .padding(.top, DS.Spacing.md)

                Spacer()

                // Center Live Editable Text with Smart Background Badge
                TextField("Nhập chữ...", text: $editingText, axis: .vertical)
                    .focused($isFieldFocused)
                    .font(editingFontStyle.font)
                    .multilineTextAlignment(editingAlignment)
                    .foregroundStyle(editingColor)
                    .padding(.horizontal, editingHasBackground ? 16 : 8)
                    .padding(.vertical, editingHasBackground ? 10 : 4)
                    .background(
                        editingHasBackground ? editingColor.smartBadgeBackgroundColor : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .shadow(color: .black.opacity(editingHasBackground ? 0.35 : 0.7), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, DS.Spacing.lg)

                Spacer()

                // Bottom Formatting Toolbars
                VStack(spacing: DS.Spacing.md) {
                    // Font Style Pills
                    HStack(spacing: DS.Spacing.sm) {
                        ForEach(TextFontStyle.allCases) { style in
                            Button {
                                editingFontStyle = style
                            } label: {
                                Text(style.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(editingFontStyle == style ? .bold : .regular)
                                    .foregroundStyle(editingFontStyle == style ? Color.black : Color.white)
                                    .padding(.horizontal, DS.Spacing.sm)
                                    .padding(.vertical, 6)
                                    .background(
                                        editingFontStyle == style ? Color.white : Color.white.opacity(0.2),
                                        in: Capsule()
                                    )
                            }
                        }
                    }

                    // Color Swatches
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.md) {
                            ForEach(0..<availableColors.count, id: \.self) { idx in
                                let col = availableColors[idx]
                                Button {
                                    editingColor = col
                                } label: {
                                    Circle()
                                        .fill(col)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: editingColor == col ? 3 : 1)
                                        )
                                        .shadow(radius: 2)
                                }
                            }
                        }
                        .padding(.horizontal, DS.Padding.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.bottom, DS.Spacing.lg)
            }
        }
        .onAppear {
            isFieldFocused = true
        }
    }

    private var alignmentIconName: String {
        switch editingAlignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }

    // MARK: - Editing Helpers

    private func startEditing(item: TextOverlayItem? = nil) {
        if let item {
            editingItemId = item.id
            editingText = item.text
            editingColor = item.color
            editingHasBackground = item.hasBackground
            editingFontStyle = item.fontStyle
            editingAlignment = item.alignment
        } else {
            editingItemId = nil
            editingText = ""
            editingColor = .white
            editingHasBackground = true
            editingFontStyle = .modern
            editingAlignment = .center
        }
        isEditingText = true
    }

    private func finishEditingText() {
        let trimmed = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = editingItemId {
            if trimmed.isEmpty {
                texts.removeAll { $0.id == id }
            } else if let index = texts.firstIndex(where: { $0.id == id }) {
                texts[index].text = trimmed
                texts[index].color = editingColor
                texts[index].hasBackground = editingHasBackground
                texts[index].fontStyle = editingFontStyle
                texts[index].alignment = editingAlignment
            }
        } else if !trimmed.isEmpty {
            texts.append(
                TextOverlayItem(
                    text: trimmed,
                    color: editingColor,
                    hasBackground: editingHasBackground,
                    fontStyle: editingFontStyle,
                    alignment: editingAlignment
                )
            )
        }
        isEditingText = false
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
