# Notifications - Thông báo

## Mô tả

Module hiển thị danh sách thông báo hoạt động (activity notifications) của user: likes, comments, follows, mentions, tags, và live video.

## Danh sách file

| File | Vai trò |
|------|---------|
| `NotificationsView.swift` | Giao diện danh sách thông báo với format theo loại |
| `NotificationsViewModel.swift` | ViewModel quản lý load notifications, mark all as read |

## Tính năng chính

- **Danh sách thông báo**: avatar actor + formatted text + timestamp
- **Notification types** (8 loại):
  - `like`: "[user] liked your post" + post thumbnail
  - `comment`: "[user] commented: [text]" + post thumbnail
  - `follow`: "[user] started following you" + Follow button
  - `followRequest`: "[user] requested to follow you" + Follow button
  - `mention`: "[user] mentioned you in a post"
  - `taggedInPost`: "[user] tagged you in a post"
  - `storyMention`: "[user] mentioned you in their story"
  - `liveVideo`: "[user] started a live video"
- **Unread highlight**: nền accentPrimary opacity nhẹ cho notification chưa đọc
- **Post thumbnail**: hiển thị ở bên phải cho notification liên quan đến post
- **Follow button**: cho follow/followRequest notifications
- **Navigation**: tap avatar → userProfile, tap thumbnail → postDetail
- **Skeleton loading**: placeholder khi đang tải
- **Mark all as read**: function available (chưa connect button)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchNotificationsUseCaseProtocol`, `NotificationRepositoryProtocol`
- Data model: `AppNotification` (actor, type, postId, postThumbnailURL, commentText, isRead, createdAt)
- Pagination: load 50 items (single page)

## Formatted Text Logic

```swift
// Username bold + action text
let text = Text(actor.username).fontWeight(.semibold) + Text(" liked your post")
```
