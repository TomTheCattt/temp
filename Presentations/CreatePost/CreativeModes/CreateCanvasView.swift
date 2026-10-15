//
//  CreateCanvasView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import UIKit
import PhotosUI

// MARK: - CanvasTheme

struct CanvasTheme: Identifiable {
    let id: UUID = UUID()
    let name: String
    let colors: [Color]
}

// MARK: - TypographyToolTab

enum TypographyToolTab: Equatable {
    case font        // Aa: Font Family Carousel
    case animation   // //A: Text Animation Carousel (Chữ đánh máy, Hiện ra, Nhảy)
    case effect      // A✨: Text Effect Carousel (Lấp lánh, Neon, Lung linh, Pixel)
}

// MARK: - TaperedVerticalTrackShape

/// Wedge-shaped track for the font size slider matching Instagram iOS:
/// Tapered from wider at the top (~6pt) to narrower at the bottom (~2pt).
struct TaperedVerticalTrackShape: Shape {
    var topWidth: CGFloat = 6.0
    var bottomWidth: CGFloat = 2.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let topHalf = topWidth / 2.0
        let bottomHalf = bottomWidth / 2.0

        // Top arc / rounded cap
        path.move(to: CGPoint(x: midX - topHalf, y: rect.minY + topHalf))
        path.addArc(
            center: CGPoint(x: midX, y: rect.minY + topHalf),
            radius: topHalf,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        // Down to bottom right
        path.addLine(to: CGPoint(x: midX + bottomHalf, y: rect.maxY - bottomHalf))
        // Bottom arc / rounded cap
        path.addArc(
            center: CGPoint(x: midX, y: rect.maxY - bottomHalf),
            radius: bottomHalf,
            startAngle: .degrees(0),
            endAngle: .degrees(180),
            clockwise: false
        )
        // Back up to top left
        path.closeSubpath()
        return path
    }
}

// MARK: - UnyieldingTextView & PersistentStoryTextView

/// A UITextView subclass that locks responder status so tapping toolbar buttons,
/// color swatches, or dragging sliders never dismisses or flickers the keyboard.
final class UnyieldingTextView: UITextView {
    var isEditingLocked: Bool = true
    var maxLayoutWidth: CGFloat = 300

    override var canResignFirstResponder: Bool {
        if isEditingLocked {
            return false
        }
        return super.canResignFirstResponder
    }

    override var intrinsicContentSize: CGSize {
        let fitSize = sizeThatFits(CGSize(width: maxLayoutWidth, height: .greatestFiniteMagnitude))
        let width = max(44, min(maxLayoutWidth, fitSize.width))
        let height = max(38, fitSize.height)
        return CGSize(width: width, height: height)
    }
}

/// UIViewRepresentable hosting UnyieldingTextView with intrinsic text hugging and keyboard retention.
struct PersistentStoryTextView: UIViewRepresentable {
    @Binding var text: String
    let font: UIFont
    let textColor: UIColor
    let textAlignment: NSTextAlignment
    let hasBackground: Bool
    let badgeBackgroundColor: UIColor
    let isEditingLocked: Bool
    let maxLayoutWidth: CGFloat

    func makeUIView(context: Context) -> UnyieldingTextView {
        let textView = UnyieldingTextView()
        textView.backgroundColor = hasBackground ? badgeBackgroundColor : .clear
        textView.layer.cornerRadius = 8
        textView.layer.masksToBounds = true
        textView.textColor = textColor
        textView.font = font
        textView.textAlignment = textAlignment
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        textView.delegate = context.coordinator
        textView.tintColor = .systemBlue
        textView.keyboardAppearance = .dark
        textView.isEditingLocked = isEditingLocked
        textView.maxLayoutWidth = maxLayoutWidth
        textView.setContentHuggingPriority(.required, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        DispatchQueue.main.async {
            textView.becomeFirstResponder()
        }
        return textView
    }

    func updateUIView(_ uiView: UnyieldingTextView, context: Context) {
        uiView.isEditingLocked = isEditingLocked
        uiView.maxLayoutWidth = maxLayoutWidth

        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
        uiView.textColor = textColor
        uiView.textAlignment = textAlignment

        let newBg = hasBackground ? badgeBackgroundColor : .clear
        if uiView.backgroundColor != newBg {
            uiView.backgroundColor = newBg
        }
        uiView.invalidateIntrinsicContentSize()

        if isEditingLocked && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: PersistentStoryTextView

        init(_ parent: PersistentStoryTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            textView.invalidateIntrinsicContentSize()
        }
    }
}

// MARK: - TextFontStyle UIFont Mapping

extension TextFontStyle {
    func uiFont(size: CGFloat, isItalic: Bool = false) -> UIFont {
        var descriptor: UIFontDescriptor
        switch self {
        case .modern:
            descriptor = UIFont.systemFont(ofSize: size, weight: .bold).fontDescriptor
        case .classic:
            let systemFont = UIFont.systemFont(ofSize: size, weight: .regular)
            descriptor = systemFont.fontDescriptor.withDesign(.serif) ?? systemFont.fontDescriptor
        case .signature:
            let systemFont = UIFont.systemFont(ofSize: size, weight: .medium)
            descriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        case .neon:
            let systemFont = UIFont.systemFont(ofSize: size, weight: .semibold)
            descriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        case .typewriter:
            let systemFont = UIFont.systemFont(ofSize: size, weight: .medium)
            descriptor = systemFont.fontDescriptor.withDesign(.monospaced) ?? systemFont.fontDescriptor
        case .strong:
            let systemFont = UIFont.systemFont(ofSize: size, weight: .heavy)
            descriptor = systemFont.fontDescriptor.withDesign(.serif) ?? systemFont.fontDescriptor
        }

        if isItalic {
            if let italicDescriptor = descriptor.withSymbolicTraits(.traitItalic) {
                descriptor = italicDescriptor
            }
        }

        return UIFont(descriptor: descriptor, size: size)
    }
}

// MARK: - CreateCanvasView

/// Instagram "Create" (Aa) Mode matching official iOS Instagram 1:1:
/// - Idle: Fullscreen gradient canvas, tap anywhere to begin typing, right vertical tools (collapsed/expanded),
///   and bottom "Thêm chú thích...", "Tin của bạn", "Bạn thân", blue next `->` button.
/// - Typing: Softly dimmed blurred gradient background, top-right "Xong", left vertical tapered font size slider,
///   font styles carousel, dynamic animation/effect carousels, persistent keyboard focus,
///   and text-hugging background highlight.
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
    @State private var isRightMenuExpanded = false
    @State private var isShowingStickerDrawer = false

    // Inline Text Editor State
    @State private var isEditingText = false
    @State private var editingItemId: UUID?
    @State private var editingText = ""
    @State private var editingColor: Color = .white
    @State private var editingHasBackground = false
    @State private var editingFontStyle: TextFontStyle = .modern
    @State private var editingAlignment: TextAlignment = .center
    @State private var editingFontSize: CGFloat = 32
    @State private var editingAnimation: TextAnimationType = .none
    @State private var editingEffect: TextEffectType = .none
    @State private var activeToolTab: TypographyToolTab = .font
    @State private var isColorPickerVisible = false

    private let availableColors: [Color] = [
        .white,
        .black,
        Color(red: 1.0, green: 0.85, blue: 0.0), // Yellow
        Color.orange,
        Color.red,
        Color.pink,
        Color.purple,
        Color.blue,
        Color.cyan,
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
        .sheet(isPresented: $isShowingStickerDrawer) {
            StoryStickerDrawer(
                isPresented: $isShowingStickerDrawer,
                onAddPhotoSticker: { stickerData in
                    stickers.append(PIPStickerItem(imageData: stickerData))
                },
                onAddTextSticker: { textItem in
                    texts.append(textItem)
                }
            )
        }
    }

    // MARK: - Idle Mode UI

    private var idleOverlayUI: some View {
        VStack(spacing: 0) {
            // Top Bar: Dismiss (Left)
            HStack {
                Button {
                    HapticFeedbackSafe.impact(.light)
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

                Button {
                    HapticFeedbackSafe.impact(.light)
                    isShowingStickerDrawer = true
                } label: {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }

                rightCircleButton(icon: "music.note") {
                    HapticFeedbackSafe.impact(.light)
                }

                rightCircleButton(icon: "bookmark") {
                    HapticFeedbackSafe.impact(.light)
                }

                // Gradient Theme Cycler Bubble
                Button {
                    HapticFeedbackSafe.selection()
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
                    HapticFeedbackSafe.impact(.light)
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

                Button {
                    HapticFeedbackSafe.impact(.light)
                    isShowingStickerDrawer = true
                } label: {
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

                expandedToolRow(label: "Âm thanh", icon: "music.note") {
                    HapticFeedbackSafe.impact(.light)
                }

                expandedToolRow(label: "Đã lưu", icon: "bookmark") {
                    HapticFeedbackSafe.impact(.light)
                }

                // Background gradient cycler with label
                Button {
                    HapticFeedbackSafe.selection()
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
                    HapticFeedbackSafe.impact(.light)
                }

                expandedToolRow(label: "Tải xuống", icon: "arrow.down.to.line") {
                    finishAndExport()
                }

                expandedToolRow(label: "Khác", icon: "ellipsis") {
                    HapticFeedbackSafe.impact(.light)
                }

                // Collapse button (chevron.up)
                Button {
                    HapticFeedbackSafe.impact(.light)
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
        Button {
            HapticFeedbackSafe.impact(.light)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.35), in: Circle())
        }
    }

    @ViewBuilder
    private func expandedToolRow(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticFeedbackSafe.impact(.light)
            action()
        } label: {
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
                    HapticFeedbackSafe.impact(.medium)
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
                    HapticFeedbackSafe.impact(.medium)
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
                    HapticFeedbackSafe.impact(.medium)
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
                        HapticFeedbackSafe.impact(.light)
                        finishEditingText()
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.md)
                }

                Spacer()

                // Main Live Typing Field with Left Vertical Tapered Slider
                HStack(alignment: .center, spacing: 0) {
                    // Left Vertical Tapered Font Size Slider
                    verticalFontSizeSlider
                        .frame(width: 36)

                    Spacer()

                    // Center Live Editable Text wrapped with exact text hugging
                    PersistentStoryTextView(
                        text: $editingText,
                        font: editingFontStyle.uiFont(size: editingFontSize, isItalic: false),
                        textColor: UIColor(editingColor),
                        textAlignment: editingAlignment.nsTextAlignment,
                        hasBackground: editingHasBackground,
                        badgeBackgroundColor: UIColor(editingColor.smartBadgeBackgroundColor),
                        isEditingLocked: isEditingText,
                        maxLayoutWidth: max(180, UIScreen.main.bounds.width - 92)
                    )
                    .shadow(
                        color: editingEffect == .neon ? editingColor.opacity(0.8) : (editingEffect == .sparkle ? Color.white.opacity(0.9) : .black.opacity(editingHasBackground ? 0.35 : 0.7)),
                        radius: (editingEffect == .neon || editingEffect == .sparkle) ? 10 : 4,
                        x: 0,
                        y: 2
                    )

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
    }

    // MARK: - Tapered Vertical Font Size Slider (Matching media_1792051226454.png)

    private var verticalFontSizeSlider: some View {
        GeometryReader { sliderGeo in
            let sliderHeight: CGFloat = 170
            let topPadding = max(0, (sliderGeo.size.height - sliderHeight) / 2)
            let normalized = max(0.0, min(1.0, (editingFontSize - 18) / (56 - 18)))
            let thumbY = sliderHeight * (1.0 - normalized)

            ZStack(alignment: .topLeading) {
                // Tapered vertical track (wider at top, narrower at bottom)
                TaperedVerticalTrackShape(topWidth: 6.0, bottomWidth: 2.0)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 8, height: sliderHeight)
                    .offset(x: 10, y: topPadding)

                // Draggable White Circular Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
                    .offset(x: 3, y: topPadding + thumbY - 11)
            }
            .frame(width: 36, height: sliderGeo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let relativeY = val.location.y - topPadding
                        let clampedY = max(0, min(sliderHeight, relativeY))
                        let fraction = 1.0 - (clampedY / sliderHeight)
                        editingFontSize = 18 + fraction * (56 - 18)
                    }
            )
        }
    }

    // MARK: - Keyboard Formatting Toolbar (Pinned above keyboard)

    private var keyboardFormattingToolbar: some View {
        VStack(spacing: 10) {
            // Row 1: Dynamic Carousel based on active tool tab
            switch activeToolTab {
            case .font:
                fontFamilyCarousel
            case .animation:
                textAnimationCarousel
            case .effect:
                textEffectCarousel
            }

            // Optional Color Swatches Palette (Appears when rainbow circle is tapped)
            if isColorPickerVisible {
                colorSwatchesBar
            }

            // Row 2: Typography Tools Toolbar (Aa | Rainbow | //A | Align | [A] | A✨)
            HStack(spacing: 16) {
                // 1. Aa font icon (Switches to font carousel)
                Button {
                    HapticFeedbackSafe.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeToolTab = .font
                    }
                } label: {
                    Text("Aa")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(activeToolTab == .font ? Color.black : Color.white)
                        .frame(width: 36, height: 36)
                        .background(activeToolTab == .font ? Color.white : Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 2. Rainbow Color Picker Circle
                Button {
                    HapticFeedbackSafe.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isColorPickerVisible.toggle()
                    }
                } label: {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.red, .yellow, .green, .blue, .purple, .red],
                                center: .center
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: isColorPickerVisible ? 3 : 2))
                        .shadow(radius: 2)
                }
                .buttonStyle(.plain)

                // 3. //A Text Animation Carousel Toggle (matching media_1792051539805.png)
                Button {
                    HapticFeedbackSafe.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeToolTab = (activeToolTab == .animation ? .font : .animation)
                    }
                } label: {
                    Text("//A")
                        .font(.system(size: 14, weight: .bold))
                        .italic()
                        .foregroundStyle((activeToolTab == .animation || editingAnimation != .none) ? Color.black : Color.white)
                        .frame(width: 36, height: 36)
                        .background((activeToolTab == .animation || editingAnimation != .none) ? Color.white : Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 4. Alignment Toggle
                Button {
                    HapticFeedbackSafe.selection()
                    switch editingAlignment {
                    case .leading: editingAlignment = .center
                    case .center: editingAlignment = .trailing
                    case .trailing: editingAlignment = .leading
                    }
                } label: {
                    Image(systemName: alignmentIconName)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 5. Background Highlight Fill Toggle [A] (Hugs text tightly)
                Button {
                    HapticFeedbackSafe.selection()
                    editingHasBackground.toggle()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(editingHasBackground ? Color.black : Color.white, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        Text("A")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(editingHasBackground ? Color.black : Color.white)
                    }
                    .frame(width: 36, height: 36)
                    .background(editingHasBackground ? Color.white : Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)

                // 6. A✨ Text Effect Carousel Toggle (matching media_1792051566892.png)
                Button {
                    HapticFeedbackSafe.selection()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        activeToolTab = (activeToolTab == .effect ? .font : .effect)
                    }
                } label: {
                    HStack(spacing: 2) {
                        Text("A")
                            .font(.system(size: 13, weight: .bold))
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle((activeToolTab == .effect || editingEffect != .none) ? Color.black : Color.white)
                    .frame(width: 36, height: 36)
                    .background((activeToolTab == .effect || editingEffect != .none) ? Color.white : Color.white.opacity(0.2), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Row 3: Quick Tagging Row (@ Nhắc đến | 📍 Vị trí)
            HStack(spacing: 24) {
                Button {
                    HapticFeedbackSafe.selection()
                    editingText += " @"
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
                    HapticFeedbackSafe.selection()
                    editingText += " 📍"
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

    // MARK: - Carousel Views

    private var fontFamilyCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TextFontStyle.allCases) { style in
                    Button {
                        HapticFeedbackSafe.selection()
                        editingFontStyle = style
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
    }

    private var textAnimationCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TextAnimationType.allCases) { anim in
                    Button {
                        HapticFeedbackSafe.selection()
                        editingAnimation = anim
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: anim.iconName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(anim.rawValue)
                                .font(.system(size: 13, weight: editingAnimation == anim ? .bold : .medium))
                        }
                        .foregroundStyle(editingAnimation == anim ? Color.black : Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            editingAnimation == anim ? Color.white : Color.black.opacity(0.45),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
        }
    }

    private var textEffectCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TextEffectType.allCases) { effect in
                    Button {
                        HapticFeedbackSafe.selection()
                        editingEffect = effect
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: effect.iconName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(effect.rawValue)
                                .font(.system(size: 13, weight: editingEffect == effect ? .bold : .medium))
                        }
                        .foregroundStyle(editingEffect == effect ? Color.black : Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            editingEffect == effect ? Color.white : Color.black.opacity(0.45),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
        }
    }

    private var colorSwatchesBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableColors, id: \.self) { color in
                    Button {
                        HapticFeedbackSafe.selection()
                        editingColor = color
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

    private var alignmentIconName: String {
        switch editingAlignment {
        case .leading: return "text.alignleft"
        case .center: return "text.aligncenter"
        case .trailing: return "text.alignright"
        }
    }

    // MARK: - Editing Helpers

    private func startEditing(item: TextOverlayItem? = nil) {
        HapticFeedbackSafe.impact(.light)
        if let item {
            editingItemId = item.id
            editingText = item.text
            editingColor = item.color
            editingHasBackground = item.hasBackground
            editingFontStyle = item.fontStyle
            editingAlignment = item.alignment
            editingAnimation = item.animation
            editingEffect = item.effect
        } else {
            editingItemId = nil
            editingText = ""
            editingColor = .white
            editingHasBackground = false
            editingFontStyle = .modern
            editingAlignment = .center
            editingAnimation = .none
            editingEffect = .none
        }
        isEditingText = true
        isColorPickerVisible = false
        activeToolTab = .font
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
                texts[index].animation = editingAnimation
                texts[index].effect = editingEffect
            }
        } else if !trimmed.isEmpty {
            texts.append(
                TextOverlayItem(
                    text: trimmed,
                    color: editingColor,
                    hasBackground: editingHasBackground,
                    fontStyle: editingFontStyle,
                    alignment: editingAlignment,
                    animation: editingAnimation,
                    effect: editingEffect
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

// MARK: - TextAlignment Extension

extension TextAlignment {
    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .leading: return .left
        case .center: return .center
        case .trailing: return .right
        }
    }
}
