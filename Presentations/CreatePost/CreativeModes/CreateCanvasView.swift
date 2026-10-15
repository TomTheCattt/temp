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

/// Instagram "Create" (Aa) Mode matching official iOS Instagram 1:1:
/// - Idle: Fullscreen gradient canvas, tap anywhere to begin typing, right vertical tools (collapsed/expanded),
///   and bottom "Thêm chú thích...", "Tin của bạn", "Bạn thân", blue next `->` button.
/// - Typing: Softly dimmed blurred gradient background, top-right "Xong", left vertical font size slider,
///   font styles carousel, typography tools (color, slant, alignment, highlight), quick tags,
///   and keyboard retention while interacting with format options.
struct CreateCanvasView: View {

    @Binding var isPresented: Bool
    let onCanvasCompleted: (Data) -> Void

    @State private var themes: [CanvasTheme] = [
        CanvasTheme(name: "Sunset", colors: [
            Color(red: 0.85, green: 0.12, blue: 0.38),
            Color(red: 0.98, green: 0.45, blue: 0.12),
            Color(red: 1.0, green: 0.75, blue: 0.15)
        ]),
        CanvasTheme(name: "Instagram", colors: [
            Color(red: 0.51, green: 0.14, blue: 0.81),
            Color(red: 0.94, green: 0.28, blue: 0.44),
            Color(red: 0.99, green: 0.69, blue: 0.34)
        ]),
        CanvasTheme(name: "Ocean", colors: [Color.blue, Color.teal]),
        CanvasTheme(name: "Emerald", colors: [Color.green, Color.mint]),
        CanvasTheme(name: "Dark", colors: [Color(.systemGray6), Color.black]),
        CanvasTheme(name: "Neon", colors: [Color.purple, Color.indigo])
    ]
    @State private var activeThemeIndex = 0

    @State private var stickers: [PIPStickerItem] = []
    @State private var texts: [TextOverlayItem] = []
    @State private var selectedStickerItem: PhotosPickerItem?
    @State private var isRightMenuExpanded = false

    // Inline Text Editor State
    @State private var isEditingText = false
    @State private var editingItemId: UUID?
    @State private var editingText = ""
    @State private var editingColor: Color = .white
    @State private var editingHasBackground = false
    @State private var editingFontStyle: TextFontStyle = .modern
    @State private var editingAlignment: TextAlignment = .center
    @State private var editingFontSize: CGFloat = 32
    @State private var isColorPickerVisible = false
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
                    startEditing()
                }
            }

            // Overlaid Canvas Elements (Stickers & Texts)
            ZStack {
                // Photo PIP Stickers
                ForEach($stickers) { $sticker in
                    PhotoPIPStickerView(item: $sticker) {
                        stickers.removeAll { $0.id == sticker.id }
                    }
                }

                // Typography Items with tap-to-edit
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

            // Idle Mode UI (Hidden while editing text)
            if !isEditingText {
                idleOverlayUI
            }

            // Active Inline Text Editor Overlay (Typing Mode)
            if isEditingText {
                inlineTextEditorOverlay
            }
        }
        .statusBarHidden()
    }

    // MARK: - Idle Mode UI

    private var idleOverlayUI: some View {
        VStack(spacing: 0) {
            // Top Bar: Dismiss (Left)
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }

                Spacer()
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.md)

            // Right Vertical Tools Strip
            HStack {
                Spacer()
                rightVerticalToolBar
                    .padding(.trailing, DS.Spacing.md)
            }

            Spacer()

            // Bottom Action Bar: "Thêm chú thích...", "Tin của bạn", "Bạn thân", Blue Next `->`
            bottomActionBar
        }
    }

    // MARK: - Right Vertical Toolbar (Collapsed / Expanded)

    private var rightVerticalToolBar: some View {
        VStack(alignment: .trailing, spacing: 14) {
            if !isRightMenuExpanded {
                // Collapsed State: Pure Circular Glyphs (matching media_1792048572245.png)
                rightCircleButton(icon: "textformat") {
                    startEditing()
                }

                PhotosPicker(selection: $selectedStickerItem, matching: .images) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
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

                rightCircleButton(icon: "music.note") {
                    // Audio selection placeholder / feedback
                }

                rightCircleButton(icon: "bookmark") {
                    // Saved presets
                }

                // Gradient Theme Cycler Bubble
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeThemeIndex = (activeThemeIndex + 1) % themes.count
                    }
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: themes[(activeThemeIndex + 1) % themes.count].colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }

                // Expand button (chevron.down)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isRightMenuExpanded = true
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }
            } else {
                // Expanded State: Text Labels + Circular Glyphs (matching media_1792048591370.png)
                expandedToolRow(label: "Văn bản", icon: "textformat") {
                    startEditing()
                }

                PhotosPicker(selection: $selectedStickerItem, matching: .images) {
                    HStack(spacing: 12) {
                        Text("Nhãn dán")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)

                        Image(systemName: "face.smiling")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.35), in: Circle())
                    }
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

                expandedToolRow(label: "Âm thanh", icon: "music.note") {
                    // Audio selection
                }

                expandedToolRow(label: "Đã lưu", icon: "bookmark") {
                    // Saved
                }

                // Background gradient cycler with label
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        activeThemeIndex = (activeThemeIndex + 1) % themes.count
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("Phông nền")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: themes[(activeThemeIndex + 1) % themes.count].colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.35), in: Circle())
                    }
                }

                expandedToolRow(label: "Nhắc đến", icon: "at") {
                    startEditing()
                    editingText = "@"
                }

                expandedToolRow(label: "Vẽ", icon: "scribble") {
                    // Drawing canvas
                }

                expandedToolRow(label: "Tải xuống", icon: "arrow.down.to.line") {
                    finishAndExport()
                }

                expandedToolRow(label: "Khác", icon: "ellipsis") {
                    // More options
                }

                // Collapse button (chevron.up)
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isRightMenuExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }
            }
        }
    }

    @ViewBuilder
    private func rightCircleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.35), in: Circle())
        }
    }

    @ViewBuilder
    private func expandedToolRow(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.35), in: Circle())
            }
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            // "Thêm chú thích..." prompt button
            Button {
                startEditing()
            } label: {
                Text("Thêm chú thích...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, DS.Spacing.sm)
            }

            // Bottom 3 Action Buttons
            HStack(spacing: DS.Spacing.sm) {
                // Button 1: Your Story (Tin của bạn)
                Button {
                    finishAndExport()
                } label: {
                    HStack(spacing: 8) {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                            Image(systemName: "f.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.blue)
                                .background(Circle().fill(Color.white).padding(-1))
                        }

                        Text("Tin của bạn")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.55), in: Capsule())
                }

                // Button 2: Close Friends (Bạn thân)
                Button {
                    finishAndExport()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.green)

                        Text("Bạn thân")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.55), in: Capsule())
                }

                Spacer()

                // Button 3: Blue Next ->
                Button {
                    finishAndExport()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(ColorTokens.accentPrimary, in: Circle())
                }
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.xl)
    }

    // MARK: - Inline Text Editor Overlay (Typing Mode, matching media_1792048619719.png)

    private var inlineTextEditorOverlay: some View {
        ZStack {
            // Subtle dark blur over current gradient (NOT opaque black!)
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Action Toolbar: "Xong" (Done) button on top right
                HStack {
                    Spacer()

                    Button("Xong") {
                        finishEditingText()
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.md)
                }

                Spacer()

                // Main Live Typing Field with Left Vertical Slider
                HStack(alignment: .center, spacing: 0) {
                    // Left Vertical Font Size Slider
                    verticalFontSizeSlider
                        .frame(width: 36)

                    Spacer()

                    // Center Live Editable Text
                    TextField("", text: $editingText, axis: .vertical)
                        .focused($isFieldFocused)
                        .font(.system(size: editingFontSize, weight: .bold))
                        .multilineTextAlignment(editingAlignment)
                        .foregroundStyle(editingColor)
                        .padding(.horizontal, editingHasBackground ? 16 : 8)
                        .padding(.vertical, editingHasBackground ? 10 : 4)
                        .background(
                            editingHasBackground ? editingColor.smartBadgeBackgroundColor : Color.clear,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                        .shadow(color: .black.opacity(editingHasBackground ? 0.35 : 0.7), radius: 6, x: 0, y: 2)
                        .frame(maxWidth: .infinity)

                    Spacer()

                    // Balance spacer for left slider
                    Spacer().frame(width: 36)
                }
                .padding(.horizontal, DS.Spacing.sm)

                Spacer()

                // Keyboard Accessory Formatting Bar (Retains keyboard focus on tap)
                keyboardFormattingToolbar
            }
        }
        .onAppear {
            isFieldFocused = true
        }
    }

    // MARK: - Vertical Font Size Slider

    private var verticalFontSizeSlider: some View {
        GeometryReader { sliderGeo in
            let sliderHeight: CGFloat = 160
            let normalized = max(0.0, min(1.0, (editingFontSize - 18) / (56 - 18)))
            let thumbY = sliderHeight * (1.0 - normalized)

            ZStack(alignment: .topLeading) {
                // Subtle Track
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 3, height: sliderHeight)
                    .offset(x: 2, y: (sliderGeo.size.height - sliderHeight) / 2)

                // Draggable White Half-Circle Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .offset(x: -8, y: (sliderGeo.size.height - sliderHeight) / 2 + thumbY - 11)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let trackTop = (sliderGeo.size.height - sliderHeight) / 2
                                let relativeY = val.location.y - trackTop
                                let clampedY = max(0, min(sliderHeight, relativeY))
                                let fraction = 1.0 - (clampedY / sliderHeight)
                                editingFontSize = 18 + fraction * (56 - 18)
                                isFieldFocused = true
                            }
                    )
            }
        }
    }

    // MARK: - Keyboard Formatting Toolbar (Pinned above keyboard)

    private var keyboardFormattingToolbar: some View {
        VStack(spacing: 12) {
            // Row 1: Font Style Carousel Pills (Modern, Classic, Signature, Neon, Typewriter, Strong)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TextFontStyle.allCases) { style in
                        Button {
                            editingFontStyle = style
                            isFieldFocused = true
                        } label: {
                            Text(style.rawValue)
                                .font(.system(size: 14, weight: editingFontStyle == style ? .bold : .medium))
                                .foregroundStyle(editingFontStyle == style ? Color.black : Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    editingFontStyle == style ? Color.white : Color.black.opacity(0.45),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
            }

            // Row 2: Typography Tools Toolbar
            HStack(spacing: 16) {
                // 1. Aa font icon
                Button {
                    isFieldFocused = true
                } label: {
                    Text("Aa")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 2. Rainbow Color Picker Circle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isColorPickerVisible.toggle()
                    }
                    isFieldFocused = true
                } label: {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.red, .yellow, .green, .blue, .purple, .red],
                                center: .center
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
                .buttonStyle(.plain)

                // 3. //A Italic Slant Toggle
                Button {
                    isFieldFocused = true
                } label: {
                    Text("//A")
                        .font(.system(size: 14, weight: .bold))
                        .italic()
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 4. Alignment Toggle
                Button {
                    switch editingAlignment {
                    case .leading: editingAlignment = .center
                    case .center: editingAlignment = .trailing
                    case .trailing: editingAlignment = .leading
                    }
                    isFieldFocused = true
                } label: {
                    Image(systemName: alignmentIconName)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 5. Background Highlight Fill Toggle [A]
                Button {
                    editingHasBackground.toggle()
                    isFieldFocused = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        Text("A")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 36, height: 36)
                    .background(editingHasBackground ? Color.white.opacity(0.35) : Color.white.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)

                // 6. A✨ Animation / Sparkles Effect Toggle
                Button {
                    isFieldFocused = true
                } label: {
                    HStack(spacing: 2) {
                        Text("A")
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Optional Color Swatches Palette (Appears when rainbow circle is tapped)
            if isColorPickerVisible {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                editingColor = color
                                isFieldFocused = true
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: editingColor == color ? 3 : 1)
                                    )
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.vertical, 2)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Row 3: Quick Tagging Row (@ Nhắc đến | 📍 Vị trí)
            HStack(spacing: 24) {
                Button {
                    editingText += " @"
                    isFieldFocused = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "at")
                        Text("Nhắc đến")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 1, height: 14)

                Button {
                    isFieldFocused = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Vị trí")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(.bottom, DS.Spacing.md)
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
            editingHasBackground = false
            editingFontStyle = .modern
            editingAlignment = .center
        }
        isEditingText = true
        isColorPickerVisible = false
        isFieldFocused = true
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

    // MARK: - Export

    private func finishAndExport() {
        let renderSize = CGSize(width: 1080, height: 1920)
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

        let validTexts = texts.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

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
