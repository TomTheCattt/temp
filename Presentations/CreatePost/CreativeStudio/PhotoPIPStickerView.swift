//
//  PhotoPIPStickerView.swift
//  Instagram
//
//  Created by Kiro on 14/10/26.
//

import SwiftUI

// MARK: - StickerShape

public enum StickerShape: String, CaseIterable, Identifiable {
    case roundedRect
    case circle
    case heart
    case star
    case square

    public var id: String { rawValue }
}

// MARK: - PIPStickerItem

public struct PIPStickerItem: Identifiable {
    public let id: UUID
    public let imageData: Data
    public var offset: CGSize
    public var scale: CGFloat
    public var rotation: Angle
    public var shape: StickerShape

    public init(
        id: UUID = UUID(),
        imageData: Data,
        offset: CGSize = .zero,
        scale: CGFloat = 1.0,
        rotation: Angle = .zero,
        shape: StickerShape = .roundedRect
    ) {
        self.id = id
        self.imageData = imageData
        self.offset = offset
        self.scale = scale
        self.rotation = rotation
        self.shape = shape
    }
}

// MARK: - Custom Shapes

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let side = min(rect.width, rect.height)
        let xOffset = (rect.width - side) / 2
        let yOffset = (rect.height - side) / 2
        
        path.move(to: CGPoint(x: xOffset + side * 0.5, y: yOffset + side * 0.8))
        path.addCurve(
            to: CGPoint(x: xOffset, y: yOffset + side * 0.3),
            control1: CGPoint(x: xOffset + side * 0.1, y: yOffset + side * 0.6),
            control2: CGPoint(x: xOffset, y: yOffset + side * 0.45)
        )
        path.addArc(
            center: CGPoint(x: xOffset + side * 0.25, y: yOffset + side * 0.25),
            radius: side * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: xOffset + side * 0.75, y: yOffset + side * 0.25),
            radius: side * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: xOffset + side * 0.5, y: yOffset + side * 0.8),
            control1: CGPoint(x: xOffset + side, y: yOffset + side * 0.45),
            control2: CGPoint(x: xOffset + side * 0.9, y: yOffset + side * 0.6)
        )
        path.closeSubpath()
        return path
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let points = 5
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.42
        var angle = -CGFloat.pi / 2

        let step = CGFloat.pi / CGFloat(points)
        for i in 0..<(points * 2) {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += step
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - PhotoPIPStickerView

struct PhotoPIPStickerView: View {

    @Binding var item: PIPStickerItem
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 1.0
    @State private var currentRotation: Angle = .zero
    @State private var isSelected: Bool = false

    var body: some View {
        if let uiImage = UIImage(data: item.imageData) {
            ZStack(alignment: .topTrailing) {
                // Sticker Image with dynamic Shape
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(shapeView(item.shape))
                    .overlay(
                        shapeView(item.shape)
                            .stroke(Color.white, lineWidth: isSelected ? 2.5 : 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        cycleShape()
                        isSelected.toggle()
                    }

                // Delete Button (shown when active)
                if isSelected {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white, ColorTokens.destructive)
                            .background(Circle().fill(Color.white).padding(2))
                    }
                    .offset(x: 10, y: -10)
                }
            }
            .scaleEffect(item.scale * currentScale)
            .rotationEffect(item.rotation + currentRotation)
            .offset(x: item.offset.width + dragOffset.width, y: item.offset.height + dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        item.offset.width += value.translation.width
                        item.offset.height += value.translation.height
                        dragOffset = .zero
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        currentScale = scale
                    }
                    .onEnded { scale in
                        item.scale = max(0.4, min(3.0, item.scale * scale))
                        currentScale = 1.0
                    }
            )
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { angle in
                        currentRotation = angle
                    }
                    .onEnded { angle in
                        item.rotation += angle
                        currentRotation = .zero
                    }
            )
        }
    }

    // MARK: - Shape Helper

    private func cycleShape() {
        let allCases = StickerShape.allCases
        if let idx = allCases.firstIndex(of: item.shape) {
            let nextIdx = (idx + 1) % allCases.count
            item.shape = allCases[nextIdx]
        }
    }

    @ViewBuilder
    private func shapeView(_ shape: StickerShape) -> some Shape {
        switch shape {
        case .roundedRect:
            RoundedRectangle(cornerRadius: 16)
        case .circle:
            Circle()
        case .heart:
            HeartShape()
        case .star:
            StarShape()
        case .square:
            Rectangle()
        }
    }
}
