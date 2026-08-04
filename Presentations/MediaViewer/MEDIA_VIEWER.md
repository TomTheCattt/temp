# MediaViewer - Xem media toàn màn hình

## Mô tả

Module hiển thị ảnh hoặc video ở chế độ full-screen với gestures tương tác: pinch-to-zoom, drag to pan, swipe down to dismiss.

## Danh sách file

| File | Vai trò |
|------|---------|
| `MediaViewerView.swift` | Full-screen viewer cho ảnh/video với zoom + pan + dismiss gestures |

## Tính năng chính

- **Full-screen hiển thị** trên nền đen
- **Pinch-to-zoom** (MagnifyGesture): phóng to/thu nhỏ ảnh
- **Pan gesture** (DragGesture): kéo ảnh khi đã zoom in
- **Swipe down to dismiss**: kéo xuống > 100pt khi scale <= 1.0 → đóng
- **Auto-reset zoom**: khi scale < 1.0 → spring animation về 1.0
- **Close button**: nút X ở góc trên phải
- **Status bar hidden**: ẩn status bar
- **Media type detection**: phân biệt video (.mp4, .mov, .m4v) và image theo URL extension
- **Image loading**: AsyncImage với loading state + error state
- **Video placeholder**: play icon + "Video Player" text (chưa tích hợp player)

## Architecture

- Đây là View đơn lẻ, không có ViewModel riêng
- Input: `URL` (media url)
- Dismiss: `@Environment(\.dismiss)`
- State: `scale`, `lastScale`, `offset`, `lastOffset`

## Gesture Logic

```
MagnifyGesture:
  onChange → scale = lastScale * magnification
  onEnded  → if scale < 1.0: spring reset to 1.0

DragGesture (simultaneous):
  onChange → offset += translation
  onEnded  → if scale <= 1.0 && translation.height > 100: dismiss()
```

## Sử dụng

```swift
// Presented as fullScreenCover
AppRouter.shared.present(fullScreen: .mediaViewer(url: imageURL))
```
