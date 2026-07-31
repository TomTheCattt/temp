# Reels - Video ngắn

## Mô tả

Module hiển thị và phát Reels (video ngắn dạng TikTok) full-screen. Hỗ trợ paging vertical, auto-play, tương tác (like, comment, share, save), và preloading video kế tiếp.

## Danh sách file

| File | Vai trò |
|------|---------|
| `ReelsView.swift` | Container full-screen với ScrollView paging + skeleton loading |
| `ReelsViewModel.swift` | ViewModel quản lý load reels, phân trang, like, preload |
| `ReelVideoPlayer.swift` | Video player cho từng reel (loop, lazy, preload support) + UIViewRepresentable |

## Tính năng chính

### ReelsView + ReelItemView
- **Full-screen paging**: `.scrollTargetBehavior(.paging)` — mỗi reel chiếm 1 screen
- **Skeleton**: `ReelSkeletonView` khi loading
- **Video thumbnail background**: hiển thị thumbnail trước khi video sẵn sàng
- **Dim overlay + Play icon**: cho reel không active
- **Reel info** (dưới trái): avatar + username + Follow button + caption (2 dòng) + audio track
- **Action buttons** (bên phải): Like (heart) + Comment + Share + Save + Audio disc
- **Count format**: K/M format cho likes, comments, shares
- **Tab bar padding**: tính toán safe area + tab bar height

### ReelsViewModel
- **Phân trang**: 10 items/page, auto load more khi gần cuối (index >= count - 3)
- **Toggle like**: optimistic update + revert
- **Current index tracking**: `onReelAppear(at:)` cập nhật active reel
- **Preloading**: tự động preload video của reel kế tiếp qua `VideoPlayerManager`

### ReelVideoPlayer
- **Lazy activation**: chỉ buffer/play khi `isActive = true`
- **Preloaded item support**: dùng item đã preload từ `VideoPlayerManager` nếu có
- **Looping**: auto-seek về đầu khi hết video
- **Background handling**: pause khi `isPlaybackAllowed = false`, resume khi active lại
- **Resource cleanup**: `replaceCurrentItem(with: nil)` khi deactivate

### VideoContentView (UIViewRepresentable)
- Wrap `AVPlayerLayer` với `videoGravity = .resizeAspectFill`
- `PlayerUIView` tự layout `playerLayer.frame = bounds`

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchReelsUseCaseProtocol`, `ToggleLikeReelUseCaseProtocol`
- Video: `ReelPlayerHolder` (ObservableObject) + `VideoPlayerManager.shared`
- Buffer: `preferredForwardBufferDuration = 5.0` (lớn hơn feed videos)

## Performance Optimizations

- Preload next reel video trước khi user swipe
- Chỉ 1 player active tại 1 thời điểm (deactivate khi scroll đi)
- Consume preloaded item thay vì tạo mới từ URL
- Muted by default (no audio decoding overhead)
- Lazy: không tạo player cho đến khi visible
