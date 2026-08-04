# PostDetail - Chi tiết bài viết

## Mô tả

Module hiển thị chi tiết đầy đủ một bài post: media, thông tin tác giả, actions, caption, comments, và input bar để thêm bình luận.

## Danh sách file

| File | Vai trò |
|------|---------|
| `PostDetailView.swift` | Giao diện chi tiết post + danh sách comments + input bar |
| `PostDetailViewModel.swift` | ViewModel quản lý load post detail, comments, like, add comment |

## Tính năng chính

- **Post content**: header (avatar + username + location) → media → actions → likes → caption → timestamp
- **Comments section**: danh sách comments ngay dưới post
- **Comment input bar**: TextField + nút Post ở dưới cùng
- **Toggle like**: optimistic update (heart fill + likes count)
- **Bookmark**: nút save (placeholder)
- **Share**: nút paperplane (placeholder)
- **Pull-to-refresh**: reload post + comments
- **Loading overlay**: ProgressView khi post chưa load

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchPostDetailUseCaseProtocol`, `FetchCommentsUseCaseProtocol`, `ToggleLikePostUseCaseProtocol`, `AddCommentUseCaseProtocol`
- Load sequence: `loadPost()` + `loadComments()` song song khi view appear
- Add comment: insert đầu array + tăng `commentsCount`
- Like: optimistic update + revert on failure

## Sub-components

### CommentRowView
- Avatar (32pt) + username bold + text + meta row
- Meta: relative time + likes count + Reply button
- Like button (heart) ở bên phải

## Layout

```
┌─────────────────────────────┐
│ [avatar] username  location │  ← Header
│ [.......MEDIA.......]       │  ← Image/Video
│ ♡ 💬 ✈️        🔖          │  ← Actions
│ 123 likes                   │
│ username Caption text...    │
│ Nov 5                       │
├─────────────────────────────┤
│ [Comment 1]                 │
│ [Comment 2]                 │  ← Comments list
│ [Comment 3]                 │
├─────────────────────────────┤
│ [TextField] [Post]          │  ← Input bar
└─────────────────────────────┘
```
