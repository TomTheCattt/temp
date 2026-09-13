# Chat - Nhắn tin 1-1

## Mô tả

Module xử lý giao diện và logic chat trực tiếp giữa 2 người dùng trong một conversation. Hỗ trợ nhiều loại tin nhắn và tương tác giống iMessage.

## Danh sách file

| File | Vai trò |
|------|---------|
| `ChatView.swift` | Giao diện màn hình chat với danh sách tin nhắn và thanh nhập liệu |
| `ChatViewModel.swift` | ViewModel quản lý messages, gửi/nhận tin nhắn, phân trang |

## Tính năng chính

- **Hiển thị tin nhắn** dạng bubble (phân biệt tin gửi/nhận bằng màu sắc)
- **Nhiều loại nội dung**: text, image, video (thumbnail + play), audio (waveform + duration), like (❤️), shared content (post/story/reel)
- **iMessage-style timestamp reveal**: kéo ngang để hiện thời gian gửi. Dùng `.simultaneousGesture` lọc theo hướng ngang (`abs(width) > abs(height)`) để KHÔNG xung đột cuộn dọc; chỉ animate khi thả tay.
- **Read receipt**: hiển thị "Đã xem" dưới tin cuối của mình. Ở mock, tin gửi đi tự chuyển `.sent → .read` sau `DS.Duration.chatReadReceipt` để mô phỏng.
- **Avatar grouping**: avatar tin nhận chỉ hiện ở tin cuối của một chuỗi liên tiếp cùng người gửi (giữ khoảng trống để bubble thẳng hàng).
- **Gửi tin nhắn**: text qua TextField + nút Send; khôi phục nội dung đã gõ nếu gửi lỗi.
- **Quick like**: gửi reaction ❤️ khi text rỗng.
- **Phân trang**: load tin cũ khi scroll lên; de-dup theo id, gate spinner theo `hasMorePages`, `isLoadingMore` riêng (không loop).
- **Mark as read**: tự đánh dấu đã đọc khi mở conversation.
- **Media buttons**: Photo (đã wire qua PhotosPicker → `sendImageMessage`); Camera/Microphone để TODO (chưa có capture flow). Tất cả nút disable khi đang gửi.
- **Xử lý lỗi**: `error.userMessage`; lỗi load thêm khi đã có tin → toast.

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchMessagesUseCaseProtocol`, `SendMessageUseCaseProtocol`, `MessageRepositoryProtocol`
- Messages sorted theo `createdAt` (mới nhất đầu array, hiển thị đảo ngược → mới nhất ở dưới); merge/de-dup theo `id` khi phân trang
- `currentUserId` fallback về `SessionStore.shared.currentUserId` khi giá trị inject rỗng (tránh render sai phía bubble)
- `ScrollView` với `.defaultScrollAnchor(.bottom)` để auto-scroll xuống tin mới
- `hasMorePages` so với `perPage` (`DS.Layout.messagesPageSize`), không hardcode

## MessageContent Types

| Type | Hiển thị |
|------|----------|
| `.text(String)` | Bubble text có màu |
| `.image(URL)` | Ảnh 200x200 rounded |
| `.video(URL, thumbnailURL)` | Thumbnail + play icon |
| `.audio(URL, duration)` | Play button + waveform bar + thời lượng |
| `.like` | Emoji ❤️ lớn |
| `.post` / `.story` / `.reel` | Shared content indicator |

## Gesture

- **Drag left** (horizontal): reveal timestamp cho tất cả tin nhắn
- Rubber-band effect khi kéo quá giới hạn
- Spring animation khi thả tay
