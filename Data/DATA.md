# Data

Layer triển khai data access — chuyển đổi dữ liệu từ API/local storage sang domain entities. Áp dụng Repository Pattern với tách biệt rõ ràng giữa remote và mock data sources.

## Cấu trúc

```
Data/
├── DTOs/               # Data Transfer Objects (API response models)
├── DataSources/
│   ├── Mock/           # Mock data cho development/testing
│   └── Remote/         # Remote API data sources
├── Mappers/            # DTO → Entity converters
└── Repositories/       # Concrete repository implementations
```

---

## DTOs/

Data Transfer Objects — struct `Decodable` & `Sendable` đại diện cho response từ API server. Chỉ chứa data, không có business logic.

| File | Struct(s) | Mô tả |
|------|-----------|--------|
| `UserDTO.swift` | `UserDTO` | Profile user: id, username, fullName, email, avatarUrl, bio, follower/following counts, relationship states |
| `PostDTO.swift` | `PostDTO`, `MediaItemDTO`, `PostLocationDTO` | Post: author, caption, media items (image/video), location, likes/comments count, isLiked/isSaved |
| `MessageDTO.swift` | `ConversationDTO`, `MessageDTO` | Conversation (participants, lastMessage, unreadCount, isGroup) và Message (contentType: text/image/video/audio/post/story/reel/like, status) |
| `CommentDTO.swift` | `CommentDTO` | Comment: author, text, likes, replies (nested), parentId |
| `NotificationDTO.swift` | `NotificationDTO` | Notification: type (like/comment/follow/mention...), actor, related post |
| `ReelDTO.swift` | `ReelDTO`, `AudioTrackDTO` | Reel: videoUrl, audioTrack, engagement stats (likes/comments/shares/views) |
| `StoryDTO.swift` | `StoryDTO`, `StoryItemDTO`, `StoryStickerDTO` | Story: items (image/video), stickers (mention/hashtag/poll/question/link/music) |
| `PaginatedResponseDTO.swift` | `PaginatedResponseDTO<T>` | Generic paginated wrapper: items, page, perPage, total, hasMore |

**Convention:** Tất cả DTO đều là `nonisolated struct`, `Decodable`, `Sendable`.

---

## DataSources/

### Remote/

Gọi API thật qua `NetworkServiceProtocol` và map response (DTO) sang Domain Entity.

| File | Chức năng |
|------|-----------|
| `RemotePostDataSource` | Feed, user posts, post detail, create (multipart upload), like/unlike, save/unsave, explore, delete |
| `RemoteUserDataSource` | Profile (me/other), search, update profile/avatar (upload), follow/unfollow, block/unblock, followers/following list, suggested |
| `RemoteMessageDataSource` | Conversations list, messages in conversation, send message, delete |
| `RemoteCommentDataSource` | Comments for post, add comment, like/unlike comment |
| `RemoteStoryDataSource` | Stories feed, story detail, create story |
| `RemoteNotificationDataSource` | Notifications list, mark as read |
| `RemoteReelDataSource` | Reels feed, like/unlike reel |

**Pattern chung:**
```swift
func fetchFeed(page: Int, perPage: Int) async throws -> [Post] {
    let response: PaginatedResponseDTO<PostDTO> = try await networkService.request(
        PostEndpoint.feed(page: page, perPage: perPage)
    )
    return PostMapper.toEntityList(response.items)
}
```

### Mock/

Data sources trả về dữ liệu giả lập, không cần network. Dùng cho development và testing khi backend chưa sẵn sàng. Tuân thủ triệt để Clean Architecture (`Presentations` không import hay phụ thuộc trực tiếp vào `MockData`).

Đặc biệt, hệ sinh thái mock data đã được nâng cấp toàn diện để đáp ứng việc **phân trang vô tận (Infinite Pagination)** với quy mô dữ liệu mở rộng và kiểm thử nghiêm ngặt:

| File | Store nội bộ | Quy mô & Tính năng Phân trang Stateful |
|------|--------------|-----------------------------------------|
| `MockData.swift` | — | **60 users** đa dạng (35 followedBy, 30 following); **100 posts** (25 Carousel 2-4 items, 33 video posts, 8 địa điểm); **50 reels** chuẩn 9:16 có fallback 2 lớp; **50 notifications** chia 4 nhóm thời gian; **35 conversations** với rich message types; comments pool đa dạng. |
| `MockAuthDataSource` | — | Simulate login/register/logout với delay. Test credentials được định nghĩa tại `AppConstants.TestAccount`. |
| `MockPostDataSource` | `MockPostStore` | Thread-safe (`OSAllocatedUnfairLock`). Cắt lát phân trang `[start..<end]` chuẩn xác cho cả `fetchFeed` (100 bài/5 trang), `fetchUserPosts` (cắt lát theo `page` & `perPage`), và `fetchExplorePosts` (hỗ trợ phân trang bất đối xứng: trang 1 lấy 30 bài, trang 2+ lấy 20 bài, 0 duplicate IDs). |
| `MockUserDataSource` | `MockUserStore`, `MockSettingsStore` | Thread-safe (`OSAllocatedUnfairLock`). Hỗ trợ phân trang danh sách Followers/Following (trang 1 lấy 30 người -> thỏa mãn ngưỡng `hasMorePages = count >= 30` của `FollowListViewModel`, trang 2 lấy 5 người còn lại). |
| `MockMessageDataSource` | In-memory storage | Thread-safe (`OSAllocatedUnfairLock`). Phân trang hội thoại `fetchConversations(page:perPage:)` theo slice `[start..<end]` (trang 1 lấy 20 hội thoại, trang 2 lấy 15 hội thoại, trang 3 trả về `[]`). Quản lý tin nhắn thời gian thực và unread state. |
| `MockCommentDataSource` | `MockCommentStore` | Thread-safe (`OSAllocatedUnfairLock`). Sinh pool bình luận động lên đến **60–80 bình luận** có replies cho các bài viết hot, đảm bảo `result.count == 20 >= 20` kích hoạt cờ `hasMorePages = true` trong `CommentsViewModel` để test cuộn tải thêm nhiều trang. |
| `MockStoryDataSource` | `MockStoryStore` | Thread-safe (`OSAllocatedUnfairLock`). Lưu trữ stories, đánh dấu đã xem (`markViewed`), tạo story mới. |
| `MockNotificationDataSource` | `MockNotificationStore` | Thread-safe (`OSAllocatedUnfairLock`). 50 thông báo phân bố theo các nhóm thời gian ("Hôm nay", "Hôm qua", "7 ngày qua", "Trước đó"). Hỗ trợ `markAsRead`, `markAllAsRead`. |
| `MockReelDataSource` | `MockReelStore` | Thread-safe (`OSAllocatedUnfairLock`). Hỗ trợ phân trang 50 video Reels qua 5 trang (`pageSize = 10`), cắt lát `fetchUserReels` chuẩn xác, bảo toàn cơ chế fallback video 2 lớp. |

---

## Mappers/

Chuyển đổi DTO (API layer) → Entity (Domain layer). Mỗi mapper là một `enum` với static methods.

| File | Chuyển đổi |
|------|-----------|
| `UserMapper` | `UserDTO` → `User` (handle optional URL parsing, relationship states) |
| `PostMapper` | `PostDTO` → `Post` (map mediaItems, location) |
| `MessageMapper` | `ConversationDTO` → `Conversation`, `MessageDTO` → `Message` (parse contentType enum, status) |
| `CommentMapper` | `CommentDTO` → `Comment` (recursive replies) |
| `NotificationMapper` | `NotificationDTO` → `AppNotification` (parse NotificationType) |
| `ReelMapper` | `ReelDTO` → `Reel` (map audioTrack) |
| `StoryMapper` | `StoryDTO` → `Story` (map items + stickers) |
| `DateMapper` | ISO 8601 string → Date (hỗ trợ fractional seconds, fallback to Unix timestamp) |

**DateMapper đặc biệt:**
- Cached `ISO8601DateFormatter` (thread-safe)
- Fallback chain: fractional seconds → plain ISO 8601 → Unix timestamp → `.now`
- `toString(_:)` — Date → ISO 8601 string cho request payloads

---

## Repositories/

Concrete implementations của Domain repository protocols. Việc switch giữa remote và mock được thực hiện tại tầng DI (`RepositoryAssembly`) dựa trên `AppConfig.shared.isMockAPI`.

| File | Protocol | Chức năng |
|------|----------|-----------|
| `AuthRepository` | `AuthRepositoryProtocol` | Login, register, refresh token, logout, forgot/reset password, verify email |
| `PostRepository` | `PostRepositoryProtocol` | Feed, user posts, detail, create/delete, like/unlike, save/unsave, explore |
| `UserRepository` | `UserRepositoryProtocol` | Profile CRUD, search, follow/unfollow, block/unblock, followers/following, suggested |
| `MessageRepository` | `MessageRepositoryProtocol` | Conversations, messages, send/delete message |
| `CommentRepository` | `CommentRepositoryProtocol` | Fetch comments, add comment, like/unlike |
| `StoryRepository` | `StoryRepositoryProtocol` | Fetch stories, create story |
| `NotificationRepository` | `NotificationRepositoryProtocol` | Fetch notifications, mark read |
| `ReelRepository` | `ReelRepositoryProtocol` | Fetch reels, like/unlike |

### Repositories/Mock/

Mock implementations dùng cho scheme `Instagram (Mock)`. Conform trực tiếp `*RepositoryProtocol` và sử dụng `Mock*DataSource` nội bộ.

| File | Protocol |
|------|----------|
| `MockAuthRepository` | `AuthRepositoryProtocol` |
| `MockPostRepository` | `PostRepositoryProtocol` |
| `MockUserRepository` | `UserRepositoryProtocol` |
| `MockMessageRepository` | `MessageRepositoryProtocol` |
| `MockCommentRepository` | `CommentRepositoryProtocol` |
| `MockStoryRepository` | `StoryRepositoryProtocol` |
| `MockNotificationRepository` | `NotificationRepositoryProtocol` |
| `MockReelRepository` | `ReelRepositoryProtocol` |

**Pattern (DI-level switching in RepositoryAssembly):**
```swift
container.register(PostRepositoryProtocol.self) { resolver in
    if AppConfig.shared.isMockAPI {
        return MockPostRepository()
    }
    return PostRepository(
        remoteDataSource: RemotePostDataSource(
            networkService: resolver.resolve(NetworkServiceProtocol.self)!
        )
    )
}.inObjectScope(.container)
```

## Luồng dữ liệu

```
API Server
    ↓ (JSON)
NetworkService (Alamofire)
    ↓ (decode)
DTO (Decodable structs)
    ↓ (Mapper)
Domain Entity (business objects)
    ↑
Repository (switch mock/remote)
    ↑
UseCase / ViewModel
```
