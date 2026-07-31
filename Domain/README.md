# Domain

Business logic layer — trung tâm của kiến trúc Clean Architecture. Layer này hoàn toàn độc lập, không phụ thuộc vào bất kỳ framework, UI, hay infrastructure nào.

## Cấu trúc

```
Domain/
├── Entities/           # Business models (value types)
├── Repositories/       # Repository protocol contracts
└── UseCases/           # Business actions (single responsibility)
    ├── Auth/
    ├── Comment/
    ├── Feed/
    ├── Message/
    ├── Notification/
    ├── Profile/
    ├── Reel/
    ├── Search/
    └── Story/
```

---

## Entities/

Các domain model — pure Swift structs, không phụ thuộc framework. Tất cả conform `Identifiable`, `Hashable`, `Sendable`.

### User.swift

```swift
struct User: Identifiable, Hashable, Sendable
```

| Property | Type | Mô tả |
|----------|------|--------|
| `id` | String | Unique identifier |
| `username` | String | Handle (@username) |
| `fullName` | String | Tên hiển thị |
| `email` | String? | Email (nil nếu không public) |
| `phone` | String? | Số điện thoại |
| `avatarURL` | URL? | Avatar image URL |
| `bio` | String? | Bio/tiểu sử |
| `website` | String? | Website cá nhân |
| `isVerified` | Bool | Tích xanh |
| `isPrivate` | Bool | Tài khoản riêng tư |
| `followersCount` | Int | Số người theo dõi |
| `followingCount` | Int | Số đang theo dõi |
| `postsCount` | Int | Số bài đăng |
| `createdAt` | Date | Ngày tạo tài khoản |
| `isFollowing` | Bool | Mình có đang follow user này không |
| `isFollowedBy` | Bool | User này có follow mình không |
| `isBlocked` | Bool | Đã block chưa |

Có static `User.empty` cho default/placeholder.

### Post.swift

```swift
struct Post: Identifiable, Hashable, Sendable
```

| Property | Type | Mô tả |
|----------|------|--------|
| `author` | User | Người đăng |
| `caption` | String? | Nội dung caption |
| `mediaItems` | [MediaItem] | Danh sách ảnh/video (carousel) |
| `location` | PostLocation? | Vị trí đăng bài |
| `likesCount` / `commentsCount` | Int | Engagement stats |
| `isLiked` / `isSaved` / `isSponsored` | Bool | Trạng thái tương tác |

**MediaItem:** id, url, thumbnailURL, type (.image/.video), width, height, duration

**PostLocation:** name, latitude?, longitude?

### Message.swift

**Conversation:** participants, lastMessage, unreadCount, isGroup, groupName, isMuted

**Message:** sender, content, status, replyToId, createdAt

**MessageContent (enum):**
| Case | Mô tả |
|------|--------|
| `.text(String)` | Tin nhắn văn bản |
| `.image(URL)` | Ảnh |
| `.video(URL, thumbnailURL:)` | Video |
| `.audio(URL, duration:)` | Voice message |
| `.post(postId:)` | Shared post |
| `.story(storyId:)` | Shared story |
| `.reel(reelId:)` | Shared reel |
| `.like` | Reaction "thả tim" |

**MessageStatus:** sending → sent → delivered → read | failed

### Comment.swift

Nested comment tree: `replies: [Comment]`, `parentId: String?` (nil = top-level).

### Notification.swift

`AppNotification` (tên tránh collision với Foundation.Notification).

**NotificationType:** like, comment, follow, followRequest, mention, taggedInPost, storyMention, liveVideo

### Reel.swift

Short-form video: videoURL, audioTrack (AudioTrack: name, artist, isOriginal), engagement stats (likes, comments, shares, views), duration.

### Story.swift

Ephemeral content (24h): items (StoryItem: mediaURL, type, duration, sticker), expiresAt.

**StoryStickerInfo.StickerType:** mention, hashtag, location, poll, question, link, music

---

## Repositories/ (Protocols)

Interface contracts mà Data layer phải implement. Tất cả methods đều `async throws` và protocols conform `Sendable`.

| Protocol | Methods chính |
|----------|--------------|
| `AuthRepositoryProtocol` | login, register, refreshToken, logout, forgotPassword, resetPassword, verifyEmail, changePassword |
| `PostRepositoryProtocol` | fetchFeed, fetchUserPosts, fetchPost, createPost, deletePost, likePost, unlikePost, savePost, unsavePost, fetchSavedPosts, fetchExplorePosts |
| `UserRepositoryProtocol` | fetchCurrentUser, fetchUser, searchUsers, updateProfile, updateAvatar, follow, unfollow, block, unblock, fetchFollowers, fetchFollowing, fetchSuggested |
| `MessageRepositoryProtocol` | fetchConversations, fetchMessages, sendMessage, deleteMessage |
| `CommentRepositoryProtocol` | fetchComments, addComment, likeComment, unlikeComment |
| `StoryRepositoryProtocol` | fetchStories, createStory |
| `NotificationRepositoryProtocol` | fetchNotifications, markAsRead |
| `ReelRepositoryProtocol` | fetchReels, likeReel, unlikeReel |

**AuthSession** struct cũng định nghĩa tại đây: `accessToken`, `refreshToken`, `user: User`, `expiresAt: Date?`

---

## UseCases/

Mỗi UseCase đại diện cho **một business action duy nhất** (Single Responsibility). Tuân theo protocol base:

```swift
protocol UseCase {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    func execute(_ input: Input) async throws -> Output
}
```

**Utility types:**
- `NoInput` — khi UseCase không cần input
- `PaginationInput` — page + perPage (default: page=1, perPage=20)

### Auth/

| UseCase | Input | Output | Mô tả |
|---------|-------|--------|--------|
| `LoginUseCase` | email, password | AuthSession | Đăng nhập |
| `RegisterUseCase` | name, email, password, phone | AuthSession | Đăng ký tài khoản mới |

### Feed/

| UseCase | Input | Output | Mô tả |
|---------|-------|--------|--------|
| `FetchFeedUseCase` | page, perPage | [Post] | Lấy feed trang chủ |
| `FetchPostDetailUseCase` | postId | Post | Chi tiết 1 post |
| `CreatePostUseCase` | caption, mediaData, location | Post | Tạo bài đăng mới |
| `ToggleLikePostUseCase` | postId, isLiked | Void | Like/unlike post |

### Profile/

| UseCase | Input | Output | Mô tả |
|---------|-------|--------|--------|
| `FetchProfileUseCase` | userId | User | Lấy profile user |
| `UpdateProfileUseCase` | name, bio, website | User | Cập nhật profile |
| `ToggleFollowUseCase` | userId, isFollowing | Void | Follow/unfollow |
| `FetchFollowersUseCase` | userId, page, perPage | [User] | Danh sách followers |

### Story/

| UseCase | Mô tả |
|---------|--------|
| `FetchStoriesUseCase` | Lấy stories feed |

### Search/

| UseCase | Mô tả |
|---------|--------|
| `SearchUsersUseCase` | Tìm kiếm users |

### Notification/

| UseCase | Mô tả |
|---------|--------|
| `FetchNotificationsUseCase` | Lấy danh sách notifications |

### Comment/

| UseCase | Mô tả |
|---------|--------|
| `FetchCommentsUseCase` | Lấy comments của post |
| `AddCommentUseCase` | Thêm comment mới |

### Reel/

| UseCase | Mô tả |
|---------|--------|
| `FetchReelsUseCase` | Lấy reels feed |
| `ToggleLikeReelUseCase` | Like/unlike reel |

### Message/

| UseCase | Mô tả |
|---------|--------|
| `FetchMessagesUseCase` | Lấy tin nhắn trong conversation |
| `SendMessageUseCase` | Gửi tin nhắn |

---

## Nguyên tắc thiết kế

1. **Không import UIKit/SwiftUI** — Domain layer là pure Swift
2. **Không biết về network/database** — chỉ define protocol, Data layer implement
3. **Sendable everywhere** — an toàn với Swift Concurrency
4. **Value types** — tất cả entities là struct (immutable by default)
5. **UseCase = 1 action** — dễ test, dễ compose, dễ thay thế
