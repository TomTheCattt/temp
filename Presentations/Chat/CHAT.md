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
- **iMessage-style timestamp reveal**: kéo ngang (drag gesture) để hiện thời gian gửi mỗi tin nhắn
- **Read receipt**: hiển thị "Đã xem" cho tin nhắn cuối cùng của mình khi đã read
- **Gửi tin nhắn**: text message qua TextField + nút Send
- **Quick like**: gửi reaction ❤️ khi text rỗng
- **Phân trang**: load thêm tin nhắn cũ khi scroll lên (infinite scroll)
- **Mark as read**: tự động đánh dấu đã đọc khi mở conversation
- **Media buttons**: Camera, Microphone, Photo picker (placeholder)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchMessagesUseCaseProtocol`, `SendMessageUseCaseProtocol`, `MessageRepositoryProtocol`
- Messages sorted theo `createdAt` (mới nhất đầu array, hiển thị đảo ngược → mới nhất ở dưới)
- `ScrollView` với `.defaultScrollAnchor(.bottom)` để auto-scroll xuống tin mới

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
