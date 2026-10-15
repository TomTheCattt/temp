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
- **3 tabs**: Posts / Reels / Tagged (với animated underline indicator), nội dung đổi theo `selectedGrid`
- **Posts grid**: 3 cột, aspect ratio 1:1, tap → postDetail
- **Reels grid**: load lazy qua `reelRepository.fetchUserReels()` (`GET /v1/reels/user/:userId`) khi chọn tab, overlay play icon
- **Tagged grid**: empty state (BE chưa có endpoint tagged)
- Mỗi tab có empty state riêng; **LazyImage** (Nuke) cho hiệu suất tốt
- **Share Profile**: `ShareLink` chia sẻ link profile (`universalLinkHost/username`)

### Custom Navigation Bar
- **MyProfileNavigationBar (Current User)**:
  - **Leading**: Nút `+` (nếu là root tab Profile) để mở `creationHub(initialMode: .post)` hoặc nút back `chevron.left` (nếu được push vào stack), kích thước icon 24pt, touch target 44x44pt.
  - **Center**: Username + icon khóa riêng tư (`lock.fill`) nếu tài khoản là private.
  - **Trailing**: Nút Threads (`@`, 24pt, 44x44pt) và nút Menu cài đặt 3 gạch (`line.3.horizontal`, 24pt, 44x44pt, điều hướng `.settings`).
- **UserProfileNavigationBar (Other User)**:
  - **Leading**: Nút back (`chevron.left`, 24pt, 44x44pt) và Username.
  - **Trailing**: Nút thông báo (`bell`, 24pt, 44x44pt) và nút tùy chọn (`ellipsis`, 24pt, 44x44pt).
- **Quy chuẩn đồng bộ**: Tất cả icon thanh điều hướng đạt chuẩn 24pt, touch target 44x44pt và hỗ trợ phản hồi xúc giác an toàn qua `HapticFeedbackSafe`.
- **Blur**: Không sử dụng blur (nền trong suốt khi ở đỉnh trang, nền phẳng `systemBackground` khi cuộn).

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchProfileUseCaseProtocol`, `ToggleFollowUseCaseProtocol`, `PostRepositoryProtocol`, `ReelRepositoryProtocol`
- `isCurrentUser`: đồng bộ giữa ViewModel và View (`userId == nil || userId == SessionStore.shared.currentUserId || userId == "user_current"`), pre-populate tức thì từ `SessionStore`/`MockUserStore`
- Load sequence: `loadProfile()` → fetch user + fetch user posts (stale-while-revalidate); `loadReelsIfNeeded()` → fetch user reels (lazy, lần đầu mở tab Reels)
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
