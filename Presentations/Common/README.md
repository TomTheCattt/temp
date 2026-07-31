# Common - UI Components dùng chung

## Mô tả

Module chứa các UI components tái sử dụng trong Presentation layer, chủ yếu phục vụ loading states (skeleton/shimmer) và hiển thị media.

## Danh sách file

| File | Vai trò |
|------|---------|
| `PostSkeletonView.swift` | Skeleton placeholder mô phỏng layout PostCardView khi đang tải |
| `ReelSkeletonView.swift` | Skeleton placeholder full-screen mô phỏng layout ReelItemView |
| `ShimmerView.swift` | Hiệu ứng shimmer animation cho skeleton loading |
| `VideoThumbnailView.swift` | Component hiển thị thumbnail cho video với fallback strategy |

## Chi tiết từng component

### PostSkeletonView
- Mô phỏng layout: header (avatar + username) → image placeholder → action buttons → caption
- Kèm `FeedSkeletonView` hiển thị 3 skeleton posts liên tiếp (cho feed loading)

### ReelSkeletonView
- Full-screen dark background
- Mô phỏng: user info (avatar + name) phía dưới trái, action buttons phía dưới phải
- Shimmer overlay mờ trên nền đen

### ShimmerView
- Animated `LinearGradient` chạy từ trái→phải (lặp vô hạn)
- Kèm `SkeletonShape`: rounded rectangle với shimmer overlay, kích thước tùy chỉnh (width/height/cornerRadius)

### VideoThumbnailView
- **Priority strategy**:
  1. Remote `thumbnailURL` (qua LazyImage/Nuke cho caching)
  2. Generated thumbnail từ video URL (qua `VideoThumbnailGenerator`)
  3. Skeleton placeholder + ProgressView khi đang load
- Async generation: sử dụng `.task(id:)` modifier
- Dependencies: `NukeUI.LazyImage`, `VideoThumbnailGenerator.shared`

## Sử dụng

```swift
// Feed loading
FeedSkeletonView()

// Reel loading
ReelSkeletonView()

// Video thumbnail
VideoThumbnailView(videoURL: url, thumbnailURL: thumbURL)

// Custom skeleton shape
SkeletonShape(width: 100, height: 12, cornerRadius: 4)
```
