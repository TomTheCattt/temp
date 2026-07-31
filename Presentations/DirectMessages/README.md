# DirectMessages - Danh sách hội thoại

## Mô tả

Module hiển thị danh sách tất cả conversations (hội thoại) của user hiện tại. Đây là màn hình chính của tính năng nhắn tin (inbox).

## Danh sách file

| File | Vai trò |
|------|---------|
| `DirectMessagesView.swift` | Giao diện danh sách conversations với avatar, last message, time |
| `DirectMessagesViewModel.swift` | ViewModel quản lý load conversations, mark as read |

## Tính năng chính

- **Danh sách hội thoại**: hiển thị avatar đối phương, username, tin nhắn cuối, thời gian
- **Unread indicator**: chấm xanh cho conversation chưa đọc
- **Muted indicator**: icon bell.slash cho conversation đã tắt thông báo
- **Verified badge**: hiển thị checkmark cho user đã xác minh
- **Last message preview**: hiển thị nội dung tin cuối theo loại (text, photo, video, voice, shared post/story/reel, ❤️)
- **Delivery status**: "Đã gửi" / "Đã xem" cho tin nhắn cuối do mình gửi
- **Skeleton loading**: placeholder khi đang tải lần đầu
- **Navigation**: tap conversation → push đến ChatView
- **New message button**: toolbar button (placeholder)
- **Username display**: title bar hiển thị username của current user

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `MessageRepositoryProtocol`
- Data: `[Conversation]` - mỗi conversation chứa participants, lastMessage, unreadCount, isMuted
- Navigation: `AppRouter.shared.push(.conversation(conversationId:))`

## ConversationRow Chi tiết

- Xác định `otherUser` = participant đầu tiên khác current user
- Bold username + last message khi `unreadCount > 0`
- Time format: `timeAgoDisplay()` extension
- Content type mapping: text trực tiếp, media → localized description (e.g. "Sent a photo")
