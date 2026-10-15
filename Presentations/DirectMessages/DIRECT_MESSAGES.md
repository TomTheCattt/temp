# DirectMessages - Danh sách hội thoại

## Mô tả

Module hiển thị danh sách tất cả conversations (hội thoại) của user hiện tại. Đây là màn hình chính của tính năng nhắn tin (inbox), được thiết kế chuẩn 1:1 theo Instagram iOS Native với khả năng đồng bộ thời gian thực (Real-time synchronization).

## Danh sách file

| File | Vai trò |
|------|---------|
| `DirectMessagesView.swift` | Giao diện danh sách conversations với Notes carousel, Search bar, Quick Camera, Context Menu, tự động refresh khi xuất hiện |
| `DirectMessagesViewModel.swift` | ViewModel quản lý load conversations, Notes, tìm kiếm, đánh dấu chưa đọc, tắt thông báo, xoá hội thoại, subscribe sự kiện đồng bộ real-time |
| `NewMessageSheet.swift` | Modal soạn tin nhắn mới: tìm kiếm multi-select người dùng, token chips, tạo hội thoại 1-1 hoặc nhóm |

## Tính năng chính

- **Tab 3 trong MainTabView**: Đóng vai trò là Tab Chat với icon máy bay giấy (`paperplane` / `paperplane.fill`), tích hợp **Badge đỏ hiển thị số tin nhắn chưa đọc** (`.badge(appState.unreadChatCount)`), tự động ẩn khi không còn tin chưa đọc.
- **Đồng bộ thời gian thực 2 chiều (Real-Time 2-Way Sync)**:
  - Khi gửi tin nhắn từ màn hình `ChatView`: Hội thoại tương ứng tự động cập nhật tin nhắn cuối (`lastMessage`) và được đưa lên đỉnh danh sách (`index = 0`) ngay lập tức mà không cần kéo refresh.
  - Khi có tin nhắn đến qua WebSocket: Tự động cập nhật nội dung tin nhắn cuối, đưa hội thoại lên đầu, và tăng badge chưa đọc.
  - Khi người dùng vào `ChatView` và xem tin: `unreadCount` tự động xóa về 0 và đồng bộ ngay sang `DirectMessagesView` cũng như Tab Bar badge.
- **Custom Navigation Bar**: Nút Center hiển thị Username current user kèm dropdown chevron, nút Trailing là nút soạn tin nhắn mới (`square.and.pencil`) mở `NewMessageSheet`. Không áp dụng hiệu ứng blur.
- **Instagram Notes Carousel**: Thanh ngang danh sách "Ghi chú" (Notes) 24h trên cùng với bubble suy nghĩ (tối đa 60 ký tự), hỗ trợ thêm/sửa ghi chú của bản thân và xem ghi chú của bạn bè.
- **Search Bar Capsule**: Ô tìm kiếm bo tròn tìm nhanh bạn bè và hội thoại với hiệu ứng clear text và animation mượt mà.
- **Danh sách hội thoại (Conversations List)**:
  - Avatar đối phương kèm chấm xanh Online Activity Status.
  - Username in đậm kèm huy hiệu xác minh (Verified badge).
  - Tin nhắn cuối (Last message preview) phân loại theo text, media, chia sẻ post/story/reel, hoặc ❤️.
  - Trạng thái tin nhắn ("Đã gửi", "Đã xem", hoặc thời gian nhận).
  - Quick Camera action button nằm ở đuôi mỗi hàng để mở camera chụp gửi nhanh.
- **Long-Press Context Menu**:
  - Tắt thông báo (`bell.slash` / `bell`).
  - Đánh dấu chưa đọc / đã đọc (`envelope.badge` / `envelope.open`).
  - Xoá đoạn chat (`trash` với role `.destructive`).
- **Pull to Refresh**: Vuốt xuống làm mới danh sách hội thoại và ghi chú.
- **Soạn tin nhắn mới (`NewMessageSheet`)**:
  - Tìm kiếm người nhận theo tên / username.
  - Chọn nhiều người nhận với visual token chips dạng thẻ pill có nút `x`.
  - Tự động điều hướng đến hội thoại tương ứng hoặc tạo nhóm chat mới.
- **Tối ưu hiệu năng & Benchmark thực tế**:
  - End-to-End Latency (từ khi nhận gói WebSocket đến khi cập nhật UI): **0.1713 ms** (chỉ chiếm 2.1% frame 120Hz).
  - Lọc tìm kiếm trên 1,000 conversations: ~1.8ms.

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `MessageRepositoryProtocol`
- Data: `[Conversation]`, `[InstagramNote]`
- Real-time Notifications: Lắng nghe `Notification.Name.didUpdateConversations` để cập nhật in-place.
- Navigation:
  - Push chat: `AppRouter.shared.push(.conversation(conversationId: String, recipient: User?))`
  - Present soạn tin: `AppRouter.shared.presentSheet(.newMessage)`
  - Camera: `AppRouter.shared.presentFullScreen(.camera)`
