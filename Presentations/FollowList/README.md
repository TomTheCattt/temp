# FollowList - Danh sách Followers/Following

## Mô tả

Module hiển thị danh sách followers hoặc following của một user. Hỗ trợ tìm kiếm, phân trang, và follow/unfollow trực tiếp từ danh sách.

## Danh sách file

| File | Vai trò |
|------|---------|
| `FollowListView.swift` | Giao diện danh sách users với avatar, username, nút follow |
| `FollowListViewModel.swift` | ViewModel quản lý load users, search filter, toggle follow, phân trang |

## Tính năng chính

- **Hai chế độ**: Followers hoặc Following (qua `FollowListMode` enum)
- **Danh sách user**: avatar + username + verified badge + full name
- **Follow/Unfollow button**: optimistic update, không hiển thị cho current user
- **Tìm kiếm** (`.searchable`): filter local theo username hoặc fullName
- **Phân trang**: infinite scroll (30 items/page)
- **Pull-to-refresh**: reload từ đầu
- **Navigation**: tap user → push `.userProfile(userId:)`
- **Dynamic title**: "Followers" hoặc "Following" tùy mode

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchFollowersUseCaseProtocol`, `FetchFollowingUseCaseProtocol`, `ToggleFollowUseCaseProtocol`
- Filter: computed property `filteredUsers` filter local (không gọi API)
- Toggle follow: optimistic update + revert on error

## Luồng hoạt động

```
init(userId, mode) → task { loadUsers() }
↓
Display list → tap Follow → toggleFollow(for:) [optimistic]
↓
Scroll to end → loadMore() [page+1]
↓
Search input → filteredUsers (local filter)
```
