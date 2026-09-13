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
- **Active reel tracking**: `.scrollPosition(id: $viewModel.currentReelId)` — reel active xác định theo vị trí cuộn thật (không dùng `onAppear`, tránh nhảy sớm / 2 video cùng active)
- **Custom Navigation Bar**: thanh overlay cố định ở vị trí trên cùng với 4 button (Camera / "Reels" / "Following" / Search). Tab Reels↔Following gọi `viewModel.setFeedMode(_:)`, lọc reels theo `author.isFollowing`. Phủ mặt nạ `LinearGradient` blur giảm dần.
- **Skeleton**: `ReelSkeletonView` khi loading
- **Video thumbnail background**: hiển thị thumbnail trước khi video sẵn sàng
- **Dim overlay + Play icon**: cho reel không active
- **Reel info** (dưới trái): avatar (Nuke `LazyImage`) + username + Follow button (ẩn khi đã follow) + caption (2 dòng) + audio track
- **Action buttons** (bên phải): Like + Comment + Share (`ShareLink`) + Save (bookmark) + Audio disc
- **Comment**: mở `CommentsView` dạng sheet cao ~2/3 màn hình (`AppSheet.reelComments(reelId:)`)
- **Error/Empty state**: `ErrorStateView` (retry) / `EmptyStateView` trên nền đen khi load lỗi/rỗng (kể cả tab Following không có reel)
- **Count format**: K/M format cho likes, comments, shares

### ReelsViewModel
- **Nguồn dữ liệu**: `allReels` (đầy đủ) → `reels` (đã lọc theo `feedMode`)
- **Phân trang**: 10 items/page, auto load more khi reel active gần cuối (index >= count - 3), dùng cờ `isLoadingMore` riêng để không chặn/che lần load đầu
- **Feed mode**: `.forYou` (tất cả) / `.following` (lọc `author.isFollowing`)
- **Toggle like / save**: optimistic update trên `allReels` + revert; save gọi `reelRepository.saveReel/unsaveReel`
- **Follow author**: `ToggleFollowUseCase` optimistic, đánh dấu mọi reel cùng tác giả
- **Active reel**: `currentReelId` (driven by scroll) → `currentIndex` derived; `onCurrentReelChanged(to:)` lo prefetch + preload
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
- Dependencies: `FetchReelsUseCaseProtocol`, `ToggleLikeReelUseCaseProtocol`, `ToggleFollowUseCaseProtocol`, `ReelRepositoryProtocol`
- Video: `ReelPlayerHolder` (ObservableObject) + `VideoPlayerManager.shared`
- Buffer: `preferredForwardBufferDuration = 5.0` (lớn hơn feed videos)

## Performance Optimizations

- Preload next reel video trước khi user swipe
- Chỉ 1 player active tại 1 thời điểm (deactivate khi scroll đi)
- Consume preloaded item thay vì tạo mới từ URL
- Muted by default (no audio decoding overhead)
- Lazy: không tạo player cho đến khi visible
