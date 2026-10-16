//
//  CreateCanvasView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI
import UIKit
import PhotosUI
import PencilKit

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

enum CanvasCompletionDestination {
    case editor
    case yourStory
    case closeFriends
}

// MARK: - StoryDrawingToolType

enum StoryDrawingToolType: String, CaseIterable, Identifiable {
    case pen = "Bút nét"
    case arrow = "Mũi tên"
    case marker = "Dạ quang"
    case neon = "Phát sáng"
    case eraser = "Tẩy"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .pen: return "pencil.tip"
        case .arrow: return "arrow.up"
        case .marker: return "highlighter"
        case .neon: return "sparkles"
        case .eraser: return "eraser.line.dashed"
        }
    }
}

// MARK: - StoryPKCanvasRepresentable

struct StoryPKCanvasRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let toolType: StoryDrawingToolType
    let color: UIColor
    let strokeWidth: CGFloat
    let isInteractionEnabled: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.isUserInteractionEnabled = isInteractionEnabled
        updateTool(canvasView)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.isUserInteractionEnabled = isInteractionEnabled
        updateTool(uiView)
    }

    private func updateTool(_ view: PKCanvasView) {
        switch toolType {
        case .pen:
            view.tool = PKInkingTool(.pen, color: color, width: strokeWidth)
        case .arrow:
            view.tool = PKInkingTool(.pen, color: color, width: strokeWidth)
        case .marker:
            view.tool = PKInkingTool(.marker, color: color, width: strokeWidth * 2.2)
        case .neon:
            view.tool = PKInkingTool(.marker, color: color.withAlphaComponent(0.9), width: strokeWidth * 1.5)
        case .eraser:
            view.tool = PKEraserTool(.vector)
        }
    }
}

// MARK: - TaperedVerticalTrackShape

/// Wedge-shaped track for the font size & brush size sliders matching Instagram iOS:
/// Tapered from wider at the top (16pt) to narrower at the bottom (4pt).
struct TaperedVerticalTrackShape: Shape {
    var topWidth: CGFloat = 16.0
    var bottomWidth: CGFloat = 4.0

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
/// color swatches, or dragging sliders never dismisses or flickers the keyboard,
/// while allowing smooth resignation when tapping Done or the background canvas.
final class UnyieldingTextView: UITextView {
    static weak var currentActiveInstance: UnyieldingTextView?

    var isEditingLocked: Bool = true
    var shouldAllowResign: Bool = false
    var maxLayoutWidth: CGFloat = 300

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            UnyieldingTextView.currentActiveInstance = self
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        if shouldAllowResign || !isEditingLocked {
            if UnyieldingTextView.currentActiveInstance === self {
                UnyieldingTextView.currentActiveInstance = nil
            }
            return super.resignFirstResponder()
        }
        return false
    }

    override var canResignFirstResponder: Bool {
        if shouldAllowResign || !isEditingLocked {
            return true
        }
        return false
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            shouldAllowResign = true
            isEditingLocked = false
            _ = super.resignFirstResponder()
            if UnyieldingTextView.currentActiveInstance === self {
                UnyieldingTextView.currentActiveInstance = nil
            }
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            shouldAllowResign = true
            isEditingLocked = false
            _ = super.resignFirstResponder()
            if UnyieldingTextView.currentActiveInstance === self {
                UnyieldingTextView.currentActiveInstance = nil
            }
        }
    }

    static func dismissKeyboard() {
        if let active = currentActiveInstance {
            active.shouldAllowResign = true
            active.isEditingLocked = false
            _ = active.resignFirstResponder()
            currentActiveInstance = nil
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        textView.shouldAllowResign = !isEditingLocked
        textView.maxLayoutWidth = maxLayoutWidth
        textView.setContentHuggingPriority(.required, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        if isEditingLocked {
            DispatchQueue.main.async {
                let _ = textView.becomeFirstResponder()
            }
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

        if isEditingLocked {
            uiView.shouldAllowResign = false
            if !uiView.isFirstResponder {
                DispatchQueue.main.async {
                    let _ = uiView.becomeFirstResponder()
                }
            }
        } else {
            uiView.shouldAllowResign = true
            if uiView.isFirstResponder {
                let _ = uiView.resignFirstResponder()
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
///   and text-hugging background highlight. Dismisses keyboard on canvas background tap or "Xong".
/// - Drawing: In-place PencilKit Metal drawing layer directly over canvas gradient, top bar with "Hoàn tác",
///   5 brush tools, "Xong", left 16pt vertical tapered stroke slider, and bottom color palette with page dots.
struct CreateCanvasView: View {

    @Binding var isPresented: Bool
    let onCanvasCompleted: (Data, Bool, CanvasCompletionDestination) -> Void

    // MARK: - Constants
    private enum Constants {
        // Sliders (Font Size & Drawing Stroke Width)
        static let sliderTrackTopWidth: CGFloat = 16.0
        static let sliderTrackBottomWidth: CGFloat = 4.0
        static let sliderHeight: CGFloat = 190.0
        static let sliderThumbSize: CGFloat = 28.0
        static let sliderHitboxWidth: CGFloat = 48.0
        static let sliderTrackWidth: CGFloat = 20.0
        static let sliderThumbShadowRadius: CGFloat = 4.0

        // Font Size Range
        static let minFontSize: CGFloat = 18.0
        static let maxFontSize: CGFloat = 56.0
        static let defaultFontSize: CGFloat = 32.0

        // Drawing Stroke Width Range
        static let minStrokeWidth: CGFloat = 3.0
        static let maxStrokeWidth: CGFloat = 36.0
        static let defaultStrokeWidth: CGFloat = 8.0

        // Buttons & Palette Constants
        static let circularButtonSize: CGFloat = 44.0
        static let toolIconSize: CGFloat = 20.0
        static let drawingPaletteColorSize: CGFloat = 28.0
        static let drawingToolButtonSize: CGFloat = 38.0
    }

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
    @State private var isShowingMusicPicker = false
    @State private var selectedAudioTrack: PostAudioTrackItem? = nil

    // In-place Drawing Mode State (Apple PencilKit)
    @State private var canvasView = PKCanvasView()
    @State private var isDrawingMode = false
    @State private var activeDrawingTool: StoryDrawingToolType = .pen
    @State private var drawingColor: Color = .white
    @State private var drawingStrokeWidth: CGFloat = Constants.defaultStrokeWidth

    // Inline Text Editor State
    @State private var isEditingText = false
    @State private var editingItemId: UUID?
    @State private var editingText = ""
    @State private var editingColor: Color = .white
    @State private var editingHasBackground = false
    @State private var editingFontStyle: TextFontStyle = .modern
    @State private var editingAlignment: TextAlignment = .center
    @State private var editingFontSize: CGFloat = Constants.defaultFontSize
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

    // Official Instagram 9-color drawing palette (matching media_1792055892992.png)
    private let drawingPaletteColors: [Color] = [
        .white,
        .black,
        Color(red: 0.1, green: 0.6, blue: 1.0),   // Light Blue
        Color(red: 0.3, green: 0.85, blue: 0.35), // Green
        Color(red: 1.0, green: 0.82, blue: 0.2),  // Yellow
        Color(red: 1.0, green: 0.55, blue: 0.15), // Orange
        Color(red: 0.95, green: 0.25, blue: 0.35),// Red / Coral
        Color(red: 0.85, green: 0.1, blue: 0.55), // Deep Pink
        Color(red: 0.65, green: 0.15, blue: 0.85) // Purple
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
                if !isEditingText && !isDrawingMode {
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
                            if !isDrawingMode {
                                startEditing(item: textItem)
                            }
                        }
                    )
                }
            }
            .allowsHitTesting(!isDrawingMode && !isEditingText)

            // Overlaid PencilKit Drawing Canvas (in-place Metal GPU layer)
            StoryPKCanvasRepresentable(
                canvasView: $canvasView,
                toolType: activeDrawingTool,
                color: UIColor(drawingColor),
                strokeWidth: drawingStrokeWidth,
                isInteractionEnabled: isDrawingMode
            )
            .ignoresSafeArea()
            .allowsHitTesting(isDrawingMode)

            // Dynamic Contextual Overlays based on active mode
            if isDrawingMode {
                inlineDrawingOverlayUI
            } else if isEditingText {
                inlineTextEditorOverlay
            } else {
                idleOverlayUI
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
        .sheet(isPresented: $isShowingMusicPicker) {
            StudioAudioPickerSheet(selectedTrack: $selectedAudioTrack)
        }
        .onDisappear {
            UnyieldingTextView.dismissKeyboard()
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
                    InstagramIcon(.close, size: 18, color: .white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }

                if let track = selectedAudioTrack {
                    Spacer()
                    HStack(spacing: 6) {
                        InstagramIcon(.system(name: "music.note"), size: 12, color: .white)
                        Text(track.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, DS.Spacing.sm)
                    .padding(.vertical, DS.Spacing.iconGap)
                    .background(Color.black.opacity(0.45), in: Capsule())
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
                    InstagramIcon(.stickers, size: 20, color: .white)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.35), in: Circle())
                }

                rightCircleButton(icon: "music.note") {
                    HapticFeedbackSafe.impact(.light)
                    isShowingMusicPicker = true
                }

                rightCircleButton(icon: "scribble") {
                    HapticFeedbackSafe.impact(.light)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isDrawingMode = true
                    }
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
                    InstagramIcon(.chevronDown, size: 16, color: .white)
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

                        InstagramIcon(.stickers, size: 20, color: .white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.35), in: Circle())
                    }
                }

                expandedToolRow(label: "Âm thanh", icon: "music.note") {
                    HapticFeedbackSafe.impact(.light)
                    isShowingMusicPicker = true
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
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isDrawingMode = true
                    }
                }

                expandedToolRow(label: "Tải xuống", icon: "arrow.down.to.line") {
                    downloadCanvas()
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
                    InstagramIcon(.chevronUp, size: 16, color: .white)
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
            InstagramIcon(canvasToolAppIcon(for: icon), size: 20, color: .white)
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

                InstagramIcon(canvasToolAppIcon(for: icon), size: 20, color: .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.35), in: Circle())
            }
        }
    }

    private func canvasToolAppIcon(for iconName: String) -> AppIcon {
        switch iconName {
        case "textformat": return .text
        case "bookmark": return .save(selected: false)
        case "at": return .threads
        case "arrow.down.to.line": return .download
        case "ellipsis": return .options
        default: return .system(name: iconName)
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
                    finishAndExport(destination: .yourStory)
                } label: {
                    HStack(spacing: 8) {
                        ZStack(alignment: .bottomTrailing) {
                            InstagramIcon(.system(name: "person.crop.circle.fill"), size: 24, color: .white)
                            InstagramIcon(.system(name: "f.circle.fill"), size: 11, color: .blue)
                                .background(Circle().fill(Color.white).padding(-1))
                        }

                        Text("Tin của bạn")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, DS.Spacing.formGap)
                    .padding(.vertical, DS.Spacing.inputVertical)
                    .background(Color.black.opacity(0.55), in: Capsule())
                }

                // Button 2: Close Friends (Bạn thân)
                Button {
                    HapticFeedbackSafe.impact(.medium)
                    finishAndExport(destination: .closeFriends)
                } label: {
                    HStack(spacing: 8) {
                        InstagramIcon(.system(name: "star.circle.fill"), size: 22, color: .green)

                        Text("Bạn thân")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, DS.Spacing.formGap)
                    .padding(.vertical, DS.Spacing.inputVertical)
                    .background(Color.black.opacity(0.55), in: Capsule())
                }

                Spacer()

                // Button 3: Blue Next ->
                Button {
                    HapticFeedbackSafe.impact(.medium)
                    finishAndExport(destination: .editor)
                } label: {
                    InstagramIcon(.system(name: "arrow.right"), size: 18, color: .white)
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
            // Subtle dark blur over current gradient (dismisses keyboard on tap outside)
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedbackSafe.impact(.light)
                    finishEditingText()
                }

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
                    // Left Vertical Tapered Font Size Slider (16pt track, 28pt thumb, 48pt hitbox)
                    verticalFontSizeSlider
                        .frame(width: Constants.sliderHitboxWidth)

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
                        maxLayoutWidth: max(180, UIScreen.main.bounds.width - 116)
                    )
                    .shadow(
                        color: editingEffect == .neon ? editingColor.opacity(0.8) : (editingEffect == .sparkle ? Color.white.opacity(0.9) : .black.opacity(editingHasBackground ? 0.35 : 0.7)),
                        radius: (editingEffect == .neon || editingEffect == .sparkle) ? 10 : 4,
                        x: 0,
                        y: 2
                    )

                    Spacer()

                    // Balance spacer for left slider
                    Spacer().frame(width: Constants.sliderHitboxWidth)
                }
                .padding(.horizontal, DS.Spacing.xs)

                Spacer()

                // Keyboard Accessory Formatting Bar (Retains keyboard focus on tap)
                keyboardFormattingToolbar
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Prevent background tap from dismissing keyboard when tapping between buttons
                    }
            }
        }
    }

    // MARK: - Tapered Vertical Font Size Slider (Matching media_1792051226454.png & 16pt track)

    private var verticalFontSizeSlider: some View {
        GeometryReader { sliderGeo in
            let sliderHeight = Constants.sliderHeight
            let topPadding = max(0, (sliderGeo.size.height - sliderHeight) / 2)
            let normalized = max(0.0, min(1.0, (editingFontSize - Constants.minFontSize) / (Constants.maxFontSize - Constants.minFontSize)))
            let thumbY = sliderHeight * (1.0 - normalized)

            ZStack(alignment: .topLeading) {
                // Tapered vertical track (16pt top, 4pt bottom)
                TaperedVerticalTrackShape(
                    topWidth: Constants.sliderTrackTopWidth,
                    bottomWidth: Constants.sliderTrackBottomWidth
                )
                .fill(Color.white.opacity(0.35))
                .frame(width: Constants.sliderTrackWidth, height: sliderHeight)
                .offset(x: 12, y: topPadding)

                // Draggable White Circular Thumb (28pt)
                Circle()
                    .fill(Color.white)
                    .frame(width: Constants.sliderThumbSize, height: Constants.sliderThumbSize)
                    .shadow(color: .black.opacity(0.35), radius: Constants.sliderThumbShadowRadius, x: 0, y: 2)
                    .offset(
                        x: 12 + (Constants.sliderTrackWidth - Constants.sliderThumbSize) / 2,
                        y: topPadding + thumbY - Constants.sliderThumbSize / 2
                    )
            }
            .frame(width: Constants.sliderHitboxWidth, height: sliderGeo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let relativeY = val.location.y - topPadding
                        let clampedY = max(0, min(sliderHeight, relativeY))
                        let fraction = 1.0 - (clampedY / sliderHeight)
                        editingFontSize = Constants.minFontSize + fraction * (Constants.maxFontSize - Constants.minFontSize)
                    }
            )
        }
    }

    // MARK: - Inline Drawing Overlay UI (In-place Drawing Mode, matching media_1792055892992.png)

    private var inlineDrawingOverlayUI: some View {
        VStack(spacing: 0) {
            // Top Toolbar: "Hoàn tác" (Left) | 5 Brush Tools (Center) | "Xong" (Right)
            HStack(spacing: 0) {
                // Undo Button
                Button {
                    HapticFeedbackSafe.impact(.light)
                    canvasView.undoManager?.undo()
                } label: {
                    Text("Hoàn tác")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
                .frame(minWidth: 70, alignment: .leading)

                Spacer()

                // 5 Brush Tools (Bút nét, Mũi tên, Dạ quang, Phát sáng, Tẩy)
                HStack(spacing: 12) {
                    ForEach(StoryDrawingToolType.allCases) { tool in
                        Button {
                            HapticFeedbackSafe.selection()
                            activeDrawingTool = tool
                        } label: {
                            ZStack {
                                if activeDrawingTool == tool {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: Constants.drawingToolButtonSize, height: Constants.drawingToolButtonSize)
                                    InstagramIcon(.system(name: tool.iconName), size: 17, color: Color.black)
                                } else {
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(width: Constants.drawingToolButtonSize, height: Constants.drawingToolButtonSize)
                                    InstagramIcon(.system(name: tool.iconName), size: 17, color: Color.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                // Done Button ("Xong")
                Button {
                    HapticFeedbackSafe.impact(.light)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isDrawingMode = false
                    }
                } label: {
                    Text("Xong")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 2)
                }
                .frame(minWidth: 70, alignment: .trailing)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.md)

            // Middle area: Left Vertical Stroke Width Slider + Transparent Canvas Area
            HStack(alignment: .center, spacing: 0) {
                verticalDrawingStrokeWidthSlider
                    .frame(width: Constants.sliderHitboxWidth)
                    .padding(.leading, DS.Spacing.xxxs)

                Spacer()
            }
            .frame(maxHeight: .infinity)

            // Bottom Palette Bar: Eyedropper + 9 Color Circles + 3 Page Dots
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    // Eyedropper Button
                    Button {
                        HapticFeedbackSafe.impact(.light)
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: Constants.drawingPaletteColorSize + 6, height: Constants.drawingPaletteColorSize + 6)
                            .overlay(
                                InstagramIcon(.system(name: "eyedropper.halffull"), size: 14, color: Color.black)
                            )
                            .shadow(radius: 2)
                    }
                    .buttonStyle(.plain)

                    // 9 Color Swatches
                    ForEach(drawingPaletteColors, id: \.self) { color in
                        Button {
                            HapticFeedbackSafe.selection()
                            drawingColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: Constants.drawingPaletteColorSize, height: Constants.drawingPaletteColorSize)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            Color.white,
                                            lineWidth: drawingColor == color ? 3.0 : (color == .black ? 1.0 : 0.0)
                                        )
                                )
                                .scaleEffect(drawingColor == color ? 1.15 : 1.0)
                                .shadow(radius: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.Spacing.sm)

                // 3 Page Dots Indicator (Matching media_1792055892992.png: • • •)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 5, height: 5)
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 5, height: 5)
                }
                .padding(.top, 2)
            }
            .padding(.bottom, DS.Spacing.xl)
        }
    }

    // MARK: - Vertical Drawing Stroke Width Slider (16pt track, 28pt thumb, 48pt hitbox)

    private var verticalDrawingStrokeWidthSlider: some View {
        GeometryReader { sliderGeo in
            let sliderHeight = Constants.sliderHeight
            let topPadding = max(0, (sliderGeo.size.height - sliderHeight) / 2)
            let normalized = max(0.0, min(1.0, (drawingStrokeWidth - Constants.minStrokeWidth) / (Constants.maxStrokeWidth - Constants.minStrokeWidth)))
            let thumbY = sliderHeight * (1.0 - normalized)

            ZStack(alignment: .topLeading) {
                // Tapered vertical track (16pt top, 4pt bottom)
                TaperedVerticalTrackShape(
                    topWidth: Constants.sliderTrackTopWidth,
                    bottomWidth: Constants.sliderTrackBottomWidth
                )
                .fill(Color.white.opacity(0.35))
                .frame(width: Constants.sliderTrackWidth, height: sliderHeight)
                .offset(x: 12, y: topPadding)

                // Draggable White Circular Thumb (28pt)
                Circle()
                    .fill(Color.white)
                    .frame(width: Constants.sliderThumbSize, height: Constants.sliderThumbSize)
                    .shadow(color: .black.opacity(0.35), radius: Constants.sliderThumbShadowRadius, x: 0, y: 2)
                    .offset(
                        x: 12 + (Constants.sliderTrackWidth - Constants.sliderThumbSize) / 2,
                        y: topPadding + thumbY - Constants.sliderThumbSize / 2
                    )
            }
            .frame(width: Constants.sliderHitboxWidth, height: sliderGeo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let relativeY = val.location.y - topPadding
                        let clampedY = max(0, min(sliderHeight, relativeY))
                        let fraction = 1.0 - (clampedY / sliderHeight)
                        drawingStrokeWidth = Constants.minStrokeWidth + fraction * (Constants.maxStrokeWidth - Constants.minStrokeWidth)
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
                    InstagramIcon(.system(name: alignmentIconName), size: 15, color: .white)
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
                        InstagramIcon(.system(name: "sparkles"), size: 10, color: (activeToolTab == .effect || editingEffect != .none) ? Color.black : Color.white)
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
                        InstagramIcon(.threads, size: 13, color: .white.opacity(0.9))
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
                        InstagramIcon(.system(name: "mappin.and.ellipse"), size: 13, color: .white.opacity(0.9))
                        Text("Vị trí")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, DS.Spacing.xxxs)
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
                            .padding(.horizontal, DS.Spacing.formGap)
                            .padding(.vertical, DS.Spacing.xs)
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
                            InstagramIcon(.system(name: anim.iconName), size: 13, color: editingAnimation == anim ? Color.black : Color.white)
                            Text(anim.rawValue)
                                .font(.system(size: 13, weight: editingAnimation == anim ? .bold : .medium))
                        }
                        .foregroundStyle(editingAnimation == anim ? Color.black : Color.white)
                        .padding(.horizontal, DS.Spacing.formGap)
                        .padding(.vertical, DS.Spacing.xs)
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
                            InstagramIcon(.system(name: effect.iconName), size: 13, color: editingEffect == effect ? Color.black : Color.white)
                            Text(effect.rawValue)
                                .font(.system(size: 13, weight: editingEffect == effect ? .bold : .medium))
                        }
                        .foregroundStyle(editingEffect == effect ? Color.black : Color.white)
                        .padding(.horizontal, DS.Spacing.formGap)
                        .padding(.vertical, DS.Spacing.xs)
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
            .padding(.vertical, DS.Spacing.xxxs)
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
            editingFontSize = item.fontSize
        } else {
            editingItemId = nil
            editingText = ""
            editingColor = .white
            editingHasBackground = false
            editingFontStyle = .modern
            editingAlignment = .center
            editingAnimation = .none
            editingEffect = .none
            editingFontSize = Constants.defaultFontSize
        }
        isEditingText = true
        isColorPickerVisible = false
        activeToolTab = .font
    }

    private func finishEditingText() {
        // Unlock and dismiss keyboard before transitioning SwiftUI view hierarchy
        UnyieldingTextView.dismissKeyboard()

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
                texts[index].fontSize = editingFontSize
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
                    effect: editingEffect,
                    fontSize: editingFontSize
                )
            )
        }
        isEditingText = false
    }

    // MARK: - Export

    private func renderPencilKitDrawing(targetSize: CGSize) -> UIImage? {
        guard !canvasView.drawing.bounds.isEmpty else { return nil }
        return autoreleasepool {
            let canvasBounds = canvasView.bounds.width > 0 ? canvasView.bounds : UIScreen.main.bounds
            let scale = canvasBounds.width > 0 ? (targetSize.width / canvasBounds.width) : 1.0
            return canvasView.drawing.image(from: canvasBounds, scale: scale)
        }
    }

    private func finishAndExport(destination: CanvasCompletionDestination = .editor) {
        let validTexts = texts.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        let hasAnimation = validTexts.contains { $0.animation != .none }

        // Audio tracks in StudioAudioPickerSheet are catalogue metadata only; no
        // licensed/local audio asset exists to mix into AVAssetWriter yet. Do not
        // silently manufacture a muted MP4 just because a track was selected.
        if selectedAudioTrack != nil {
            HUDManager.shared.showInfo("Âm thanh chưa thể xuất trong bản này")
        }

        // Animated text requires a video. Static canvases remain images until an
        // actual audio-mixing pipeline is available.
        if hasAnimation {
            HUDManager.shared.showLoading("Đang xử lý video...")
            Task {
                do {
                    let renderedDrawing = renderPencilKitDrawing(targetSize: CGSize(width: 1080, height: 1920))
                    let (_, videoData) = try await CanvasVideoRenderer.shared.renderVideo(
                        gradientColors: themes[activeThemeIndex].colors,
                        drawings: renderedDrawing,
                        stickers: stickers,
                        texts: validTexts,
                        duration: 5.0,
                        fps: 30
                    )
                    await MainActor.run {
                        HUDManager.shared.dismiss()
                        onCanvasCompleted(videoData, true, destination)
                        isPresented = false
                    }
                } catch {
                    await MainActor.run {
                        HUDManager.shared.dismiss()
                        exportStaticImage(validTexts: validTexts, destination: destination)
                    }
                }
            }
        } else {
            exportStaticImage(validTexts: validTexts, destination: destination)
        }
    }

    private func exportStaticImage(
        validTexts: [TextOverlayItem],
        destination: CanvasCompletionDestination
    ) {
        guard let composite = makeStaticComposite(validTexts: validTexts),
              let jpeg = composite.jpegData(compressionQuality: 0.88) else {
            HUDManager.shared.showError("Không thể xuất ảnh")
            return
        }
        onCanvasCompleted(jpeg, false, destination)
        isPresented = false
    }

    private func makeStaticComposite(validTexts: [TextOverlayItem]) -> UIImage? {
        let renderSize = CGSize(width: 1080, height: 1920)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let bgRenderer = UIGraphicsImageRenderer(size: renderSize, format: format)
        let renderedDrawing = renderPencilKitDrawing(targetSize: renderSize)

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

            // Draw PencilKit drawing if any
            if let renderedDrawing {
                renderedDrawing.draw(in: CGRect(origin: .zero, size: renderSize))
            }
        }

        let composite = CompositeImageRenderer.shared.render(
            baseImage: bgImage,
            stickers: stickers,
            texts: validTexts,
            renderSize: renderSize
        )

        return composite
    }

    private func downloadCanvas() {
        let validTexts = texts.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let hasAnimation = validTexts.contains { $0.animation != .none }

        HUDManager.shared.showLoading("Đang lưu vào thư viện...")
        Task {
            do {
                if hasAnimation {
                    let drawing = renderPencilKitDrawing(targetSize: CGSize(width: 1080, height: 1920))
                    let (url, _) = try await CanvasVideoRenderer.shared.renderVideo(
                        gradientColors: themes[activeThemeIndex].colors,
                        drawings: drawing,
                        stickers: stickers,
                        texts: validTexts,
                        duration: 5.0,
                        fps: 30
                    )
                    try await PhotoLibraryService.shared.saveVideo(at: url)
                } else if let image = makeStaticComposite(validTexts: validTexts),
                          let data = image.jpegData(compressionQuality: 0.88) {
                    try await PhotoLibraryService.shared.saveImageData(data)
                } else {
                    throw PhotoLibrarySaveError.invalidImage
                }
                await MainActor.run {
                    HUDManager.shared.dismiss()
                    HUDManager.shared.showInfo("Đã lưu vào thư viện ảnh")
                }
            } catch {
                await MainActor.run {
                    HUDManager.shared.dismiss()
                    HUDManager.shared.showError("Không thể lưu: \(error.localizedDescription)")
                }
            }
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
