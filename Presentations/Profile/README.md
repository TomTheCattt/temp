# Profile - Trang cá nhân

## Mô tả

Module hiển thị trang profile của user (bản thân hoặc người khác). Bao gồm header thống kê, bio, action buttons, và grid posts. Xử lý cả 2 trường hợp: current user (có nút Edit/Settings) và other user (có nút Follow/Message).

## Danh sách file

| File | Vai trò |
|------|---------|
| `ProfileView.swift` | Giao diện trang profile: header stats + bio + actions + grid |
| `ProfileViewModel.swift` | ViewModel quản lý load profile, posts, toggle follow |

## Tính năng chính

### Header
- **Avatar** lớn (XLarge) với thin border
- **Stats** 3 cột: Posts / Followers / Following (tap followers/following → navigate)
- **Format count**: 10K+, 1.0M format

### Bio Section
- **Full name** + verified badge
- **Bio text** (multi-line)
- **Website link** (clickable, bỏ prefix https://)

### Action Buttons
- **Current user**: "Edit Profile" + "Share Profile"
- **Other user**: "Follow/Following" (toggle, màu thay đổi) + "Message"

### Grid
- **3 tabs**: Posts / Reels / Tagged (với animated underline indicator)
- **Posts grid**: 3 cột, aspect ratio 1:1, tap → postDetail
- **LazyImage** (Nuke) cho hiệu suất tốt

### Toolbar (current user only)
- Nút tạo post (plus.app)
- Nút Settings (hamburger menu)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchProfileUseCaseProtocol`, `ToggleFollowUseCaseProtocol`, `PostRepositoryProtocol`
- `isCurrentUser`: xác định bởi `userId == nil`
- Load sequence: `loadProfile()` → fetch user + fetch user posts
- Toggle follow: optimistic update + revert on failure

## ProfileGrid Enum

```swift
enum ProfileGrid: Int, CaseIterable {
    case posts   // squareshape.split.3x3
    case reels   // play.square
    case tagged  // person.crop.square
}
```

## Navigation

- Tap followers → `.followers(userId:)`
- Tap following → `.following(userId:)`
- Edit Profile → sheet `.editProfile`
- Settings → push `.settings`
- Tap post → `.postDetail(postId:)`
- Message → `.directMessages`
