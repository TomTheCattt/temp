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
/// and adding custom typography.
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
    @State private var isEditingText = false
    @State private var newText = ""

    var body: some View {
        ZStack {
            // Background Dynamic Gradient
            LinearGradient(
                colors: themes[activeThemeIndex].colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Overlaid Content Area
            ZStack {
                // Photo PIP Stickers
                ForEach($stickers) { $sticker in
                    PhotoPIPStickerView(item: $sticker) {
                        stickers.removeAll { $0.id == sticker.id }
                    }
                }

                // Typography Items
                ForEach($texts) { $textItem in
                    TypographyOverlayView(item: $textItem) {
                        texts.removeAll { $0.id == textItem.id }
                    }
                }
            }

            // Top Bar Controls
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
                        newText = ""
                        isEditingText = true
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

                    // Done Button
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
        .sheet(isPresented: $isEditingText) {
            textEditSheet
        }
    }

    // MARK: - Text Edit Sheet

    private var textEditSheet: some View {
        NavigationStack {
            VStack(spacing: DS.Spacing.lg) {
                TextField("Nhập nội dung...", text: $newText)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { isEditingText = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.done) {
                        if !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            texts.append(TextOverlayItem(text: newText, hasBackground: true))
                        }
                        isEditingText = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.height(200)])
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

        // Bake stickers and typography over the background
        let composite = CompositeImageRenderer.shared.render(
            baseImage: bgImage,
            stickers: stickers,
            texts: texts,
            renderSize: renderSize
        )

        if let jpeg = composite.jpegData(compressionQuality: 0.85) {
            onCanvasCompleted(jpeg)
            isPresented = false
        }
    }
}
