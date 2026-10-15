//
//  CreateCanvasView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import PhotosUI

// MARK: - CanvasTheme

struct CanvasTheme: Identifiable {
    let id: UUID = UUID()
    let name: String
    let colors: [Color]
}

// MARK: - CreateCanvasView

/// Instagram "Create" (Aa) Mode: Starts from a blank gradient/solid canvas.
/// Allows cycling background palettes, adding Photo PIP stickers from library,
/// and adding custom typography with full-screen inline editing.
struct CreateCanvasView: View {

    @Binding var isPresented: Bool
    let onCanvasCompleted: (Data) -> Void

    @State private var themes: [CanvasTheme] = [
        CanvasTheme(name: "Instagram", colors: [Color(red: 0.51, green: 0.14, blue: 0.81), Color(red: 0.94, green: 0.28, blue: 0.44), Color(red: 0.99, green: 0.69, blue: 0.34)]),
        CanvasTheme(name: "Sunset", colors: [Color.orange, Color.pink]),
        CanvasTheme(name: "Ocean", colors: [Color.blue, Color.teal]),
        CanvasTheme(name: "Emerald", colors: [Color.green, Color.mint]),
        CanvasTheme(name: "Dark", colors: [Color(.systemGray6), Color.black]),
        CanvasTheme(name: "Neon", colors: [Color.purple, Color.indigo])
    ]
    @State private var activeThemeIndex = 0

    @State private var stickers: [PIPStickerItem] = []
    @State private var texts: [TextOverlayItem] = [
        TextOverlayItem(text: "Chạm để nhập chữ...", hasBackground: true)
    ]
    @State private var selectedStickerItem: PhotosPickerItem?

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
            // Background Dynamic Gradient with Tap-to-type support
            LinearGradient(
                colors: themes[activeThemeIndex].colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                if !isEditingText {
                    if let placeholder = texts.first(where: { $0.text == "Chạm để nhập chữ..." }) {
                        startEditing(item: placeholder)
                    } else {
                        startEditing()
                    }
                }
            }

            // Overlaid Content Area
            ZStack {
                // Photo PIP Stickers
                ForEach($stickers) { $sticker in
                    PhotoPIPStickerView(item: $sticker) {
                        stickers.removeAll { $0.id == sticker.id }
                    }
                }

                // Typography Items with tap-to-edit callback
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

            // Top Bar Controls (Hidden when editing text)
            if !isEditingText {
                VStack {
                    HStack(spacing: DS.Spacing.md) {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.35), in: Circle())
                        }

                        Spacer()

                        // Add Text Button
                        Button {
                            startEditing()
                        } label: {
                            Image(systemName: "textformat")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.35), in: Circle())
                        }

                        // Add Photo Sticker from Library
                        PhotosPicker(
                            selection: $selectedStickerItem,
                            matching: .images
                        ) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.35), in: Circle())
                        }
                        .onChange(of: selectedStickerItem) { _, newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    await MainActor.run {
                                        stickers.append(PIPStickerItem(imageData: data))
                                        selectedStickerItem = nil
                                    }
                                }
                            }
                        }

                        // Next / Export Button
                        Button {
                            finishAndExport()
                        } label: {
                            Text(L10n.Common.next)
                                .font(DS.Font.headline)
                                .foregroundStyle(ColorTokens.accentPrimary)
                                .padding(.horizontal, DS.Spacing.md)
                                .padding(.vertical, DS.Spacing.xs)
                                .background(Color.white, in: Capsule())
                        }
                    }
                    .padding(.horizontal, DS.Padding.horizontal)
                    .padding(.top, DS.Spacing.md)

                    Spacer()

                    // Bottom Bar: Theme Color Switcher Bubble
                    HStack {
                        Spacer()

                        Button {
                            activeThemeIndex = (activeThemeIndex + 1) % themes.count
                        } label: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: themes[(activeThemeIndex + 1) % themes.count].colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, DS.Padding.horizontal)
                        .padding(.bottom, DS.Spacing.xl)
                    }
                }
            }

            // Inline Full-Screen Text Editor Overlay
            if isEditingText {
                inlineTextEditorOverlay
            }
        }
    }

    // MARK: - Inline Text Editor Overlay

    private var inlineTextEditorOverlay: some View {
        ZStack {
            // Semi-transparent backdrop
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
                        Image(systemName: alignmentIconName)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2), in: Circle())
                    }

                    // Background Badge Toggle Button
                    Button {
                        editingHasBackground.toggle()
                    } label: {
                        Image(systemName: editingHasBackground ? "character.textbox" : "textformat")
                            .font(.title3)
                            .foregroundStyle(editingHasBackground ? Color.black : Color.white)
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
                TextField("Nhập nội dung...", text: $editingText, axis: .vertical)
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
            if item.text == "Chạm để nhập chữ..." {
                editingText = ""
            } else {
                editingText = item.text
            }
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
            // Remove initial placeholder if present
            texts.removeAll { $0.text == "Chạm để nhập chữ..." }
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

    // MARK: - Export

    private func finishAndExport() {
        // Render solid/gradient background to UIImage
        let renderSize = CGSize(width: 1080, height: 1080)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let bgRenderer = UIGraphicsImageRenderer(size: renderSize, format: format)

        let bgImage = bgRenderer.image { context in
            let cgContext = context.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors = themes[activeThemeIndex].colors.compactMap { UIColor($0).cgColor } as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: nil) {
                cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: renderSize.width, y: renderSize.height),
                    options: []
                )
            }
        }

        // Filter out untouched placeholder text before composite baking
        let validTexts = texts.filter {
            let t = $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return !t.isEmpty && t != "Chạm để nhập chữ..."
        }

        // Bake stickers and typography over the background
        let composite = CompositeImageRenderer.shared.render(
            baseImage: bgImage,
            stickers: stickers,
            texts: validTexts,
            renderSize: renderSize
        )

        if let jpeg = composite.jpegData(compressionQuality: 0.85) {
            onCanvasCompleted(jpeg)
            isPresented = false
        }
    }
}
