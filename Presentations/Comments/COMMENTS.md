# Comments - Bình luận bài viết

## Mô tả

Module xử lý giao diện và logic cho danh sách bình luận của một bài post. Hỗ trợ bình luận cấp 1 và reply (nested 1 level).

## Danh sách file

| File | Vai trò |
|------|---------|
| `CommentsView.swift` | Giao diện danh sách bình luận với input bar |
| `CommentsViewModel.swift` | ViewModel quản lý load/add/reply comments, phân trang |

## Tính năng chính

- **Danh sách bình luận**: hiển thị avatar, username, nội dung, thời gian, số likes
- **Reply (trả lời)**: chọn comment để reply → hiển thị indicator "Replying to @username"
- **Nested replies**: hiển thị replies con (1 level) ngay dưới comment cha
- **Like comment**: nút heart cho mỗi comment (toggle liked state)
- **Thêm bình luận**: input bar ở dưới cùng với avatar user hiện tại
- **Phân trang**: infinite scroll (load more khi cuộn đến comment cuối)
- **Pull to refresh**: kéo xuống để reload toàn bộ
- **Skeleton loading**: hiển thị placeholder khi đang tải lần đầu
- **Cancel reply**: nút X để hủy trạng thái reply

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchCommentsUseCaseProtocol`, `AddCommentUseCaseProtocol`
- Pagination: page-based (20 items/page)
- New comment: insert đầu array (top-level) hoặc append (reply)

## Luồng hoạt động

1. View load → `loadComments()` (page 1)
2. Scroll đến comment cuối → `loadMore()` (page+1)
3. Tap "Reply" → set `replyingTo`, focus input
4. Nhập text + tap "Post" → `addComment(text:)` với `parentId` nếu đang reply
5. Pull-to-refresh → reset page 1, reload
