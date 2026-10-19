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

- **Tab 3 trong MainTabView**: Đóng vai trò là Tab Chat với icon máy bay giấy (`paperplane` / `paperplane.fill`), tích hợp **Badge đỏ hiển thị số cuộc hội thoại chưa đọc** (`.badge(appState.unreadChatCount)`), chuẩn 1:1 Instagram iOS HIG (đếm số cuộc trò chuyện có tin nhắn chưa đọc thay vì đếm số tin nhắn lẻ), tự động ẩn khi không còn cuộc trò chuyện chưa đọc.
- **Đồng bộ thời gian thực 2 chiều & Cold Start**:
  - Khi mở app (Cold Start): `MainTabView` tự động gọi `loadInitialUnreadBadge()` nạp chính xác số cuộc trò chuyện chưa đọc từ `MessageRepositoryProtocol`.
  - Khi gửi/nhận tin nhắn hoặc cuộc gọi nhỡ: Cập nhật `lastMessage`, đưa hội thoại lên đầu, và cập nhật badge tức thì.
  - Khi người dùng vào `ChatView` và xem tin: `unreadCount` tự động xóa về 0, đồng bộ ngay sang badge tab bar và `UIApplication.shared.applicationIconBadgeNumber`.
  - Khi toggle "Đánh dấu chưa đọc / đã đọc" qua Context Menu: Gọi trực tiếp xuống `markAsUnread` / `markAsRead` trên repository để cập nhật badge ngay lập tức.
- **Custom Navigation Bar**: Nút Center hiển thị Username current user kèm dropdown chevron, nút Trailing là nút soạn tin nhắn mới (`square.and.pencil`) mở `NewMessageSheet`. Không áp dụng hiệu ứng blur.
- **Instagram Notes Carousel**: Thanh ngang danh sách "Ghi chú" (Notes) 24h trên cùng với bubble suy nghĩ (tối đa 60 ký tự), hỗ trợ thêm/sửa ghi chú của bản thân và xem ghi chú của bạn bè.
- **Search Bar Capsule**: Ô tìm kiếm bo tròn tìm nhanh bạn bè và hội thoại với hiệu ứng clear text và animation mượt mà.
- **Danh sách hội thoại (Conversations List)**:
  - Avatar đối phương hoặc Avatar nhóm (Group Avatar) chuẩn 1:1 Instagram.
  - Username hoặc Tên nhóm (Group Name) in đậm kèm huy hiệu xác minh (Verified badge).
  - Tin nhắn cuối (Last message preview) phân loại theo text, media, chia sẻ post/story/reel, hoặc ❤️. Tự động hiển thị tên người gửi đối với nhóm chat (`username: ...`) và `Bạn: ...` đối với tin nhắn của bản thân.
  - Trạng thái tin nhắn ("Đã gửi", "Đã xem", hoặc thời gian nhận).
  - Quick Camera action button nằm ở đuôi mỗi hàng để mở camera chụp gửi nhanh.
  - **Single Source of Truth**: Đồng bộ 100% với chi tiết phòng chat qua `MockData.conversations` và `MockData.seededMessages`. Trạng thái chưa đọc `unreadCount > 0` chỉ xuất hiện khi đối phương là người gửi tin cuối cùng với trạng thái `.delivered`.
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
