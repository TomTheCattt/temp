# LikesList - Danh sách người đã like

## Mô tả

Module hiển thị danh sách tất cả users đã like một bài post cụ thể. Hỗ trợ tìm kiếm và follow/unfollow trực tiếp.

## Danh sách file

| File | Vai trò |
|------|---------|
| `LikesListView.swift` | Giao diện danh sách users đã like với nút follow |
| `LikesListViewModel.swift` | ViewModel quản lý load likes, search filter, toggle follow |

## Tính năng chính

- **Danh sách users**: avatar + username + verified badge + full name
- **Follow/Unfollow button**: optimistic update, ẩn cho current user
- **Tìm kiếm** (`.searchable`): filter local theo username/fullName
- **Loading indicator**: ProgressView khi đang tải
- **Navigation**: tap user → push `.userProfile(userId:)`
- **Title**: "Likes" (inline display mode)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `UserRepositoryProtocol`, `ToggleFollowUseCaseProtocol`
- Data: sử dụng `fetchSuggested` làm mock data (thực tế sẽ gọi `POST /posts/{id}/likes`)
- Filter: computed property `filteredUsers` filter theo `searchQuery`
- Toggle follow: optimistic update + revert on failure

## So sánh với FollowList

| Feature | LikesList | FollowList |
|---------|-----------|------------|
| Data source | Post likes | User followers/following |
| Pagination | Không (load 1 lần, max 50) | Có (30/page) |
| Pull-to-refresh | Không | Có |
| Mode | Single mode | Followers/Following |
