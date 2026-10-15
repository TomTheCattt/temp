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
- **Infinite scroll**: prefetch trang kế khi còn cách cuối `loadMoreThreshold` (3) posts (không đợi tới item cuối cùng)
- **Pull-to-refresh**: kéo xuống để reload feed
- **Visibility tracking**: theo dõi posts nào đang visible (cho video auto-play)
- **Custom Navigation Bar**: Bố cục chuẩn Instagram iOS hiện tại: Nút Tạo `+` bên trái (24pt, hitbox 44x44pt mở Creation Hub), Logo `Instagram` căn giữa không dropdown, và Nút Thông báo Trái tim `heart` bên phải (24pt, hitbox 44x44pt mở Notifications). Tự động trượt ẩn khi cuộn xuống và trượt hiện lại khi cuộn lên (`.onScrollGeometryChange`), mở rộng Safe Area Top và nền gradient blur nhẹ khi cuộn.

### FeedViewModel
- **Phân trang**: page-based (20 items/page), auto load more; **de-dup theo `id`** khi append (chống trùng ở ranh giới trang → tránh "Duplicate ID" trong `ForEach`). Cờ `isLoadingMore` riêng.
- **Toggle like/save**: optimistic update đọc **trạng thái hiện tại** từ `posts[index]` (không dùng bản chụp `post` đã stale) cho cả API call lẫn revert; **guard chống spam** per-post qua `pendingLikeIds`/`pendingSaveIds` (bỏ qua toggle chồng khi request đang chạy); revert + toast khi fail.
- **Refresh**: reset về page 1, reload toàn bộ; nếu fail mà đã có nội dung → giữ nội dung + toast, chỉ set errorMessage khi rỗng.

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
- Double-tap heart dùng một `Task` có hủy (không stack timer khi tap nhanh)
- Toàn bộ số/màu/chuỗi qua `DS.*` / `ColorTokens.*` / `L10n.*` (vd `L10n.Common.likesCount`, `DS.Font.navBrand`)

> Ghi chú: MockData feed có 25 posts để test được phân trang (trang 1 đầy 20 → loadMore lấy 5 còn lại → dừng).
