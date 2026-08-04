# Feed - Bảng tin chính

## Mô tả

Module hiển thị bảng tin (home feed) của ứng dụng — màn hình chính sau khi đăng nhập. Bao gồm stories bar, danh sách posts với media (ảnh/video), và các tương tác (like, comment, share, save).

## Danh sách file

| File | Vai trò |
|------|---------|
| `FeedView.swift` | Giao diện màn hình feed chính: stories bar + danh sách posts |
| `FeedViewModel.swift` | ViewModel quản lý load feed, phân trang, toggle like |
| `FeedVideoPlayer.swift` | Video player tối ưu cho video posts trong feed (auto-play, loop, mute) |
| `PostCardView.swift` | UI component hiển thị 1 bài post hoàn chỉnh (header → media → actions → caption) |

## Tính năng chính

### FeedView
- **Stories bar** hiển thị ở đầu feed (component `StoriesBarView`)
- **Skeleton loading** (`FeedSkeletonView`) khi đang tải lần đầu
- **Infinite scroll**: load thêm posts khi cuộn đến cuối
- **Pull-to-refresh**: kéo xuống để reload feed
- **Visibility tracking**: theo dõi posts nào đang visible (cho video auto-play)
- **Toolbar**: logo Instagram (serif font) + nút tạo post + nút DM (paperplane)

### FeedViewModel
- **Phân trang**: page-based (20 items/page), auto load more
- **Toggle like**: optimistic update (cập nhật UI ngay, revert nếu API fail)
- **Refresh**: reset về page 1, reload toàn bộ

### FeedVideoPlayer
- **Auto-play**: tự phát khi scroll vào viewport
- **Auto-pause**: dừng khi scroll ra khỏi viewport hoặc app vào background
- **Looping**: video tự lặp lại khi hết
- **Muted by default**: tiết kiệm resource audio decoding
- **Mute/Unmute button**: nút toggle ở góc dưới phải
- **Lazy initialization**: không tạo/buffer video cho đến khi visible
- **Resource cleanup**: giải phóng player item khi scroll đi
- **Integration**: `VideoPlayerManager.shared` quản lý playback toàn cục

### PostCardView
- **Header**: avatar + username + verified badge + location + sponsored tag + more button
- **Media section**: ảnh (LazyImage/Nuke) hoặc video (FeedVideoPlayer) + thumbnail fallback
- **Double-tap to like**: animation trái tim trắng lớn (scale + opacity)
- **Action bar**: Like (heart), Comment, Share (paperplane), Bookmark
- **Likes count**: hiển thị số likes
- **Caption**: username bold + text (2 dòng max)
- **Comments link**: "View all X comments" → navigate
- **Timestamp**: `timeAgoDisplay()` (Just now, Xm, Xh, Xd, MMM d)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchFeedUseCaseProtocol`, `ToggleLikePostUseCaseProtocol`
- Navigation: `AppRouter.shared` (.comments, .directMessages, .createPost)
- Video management: `FeedPlayerHolder` (ObservableObject) + `VideoPlayerManager.shared`

## Performance Optimizations

- `LazyVStack` cho danh sách posts
- Video chỉ buffer khi visible (`preferredForwardBufferDuration = 3s`)
- Skeleton shimmer thay vì spinner cho UX tốt hơn
- `visiblePostIds` Set tracking tránh play nhiều video cùng lúc
