# Call - Gọi điện / Video call

## Mô tả

Module xử lý giao diện và logic cho cuộc gọi thoại (audio) và video call giữa 2 người dùng. Hỗ trợ nhận cuộc gọi đến, gọi đi, và các thao tác điều khiển trong cuộc gọi.

## Danh sách file

| File | Vai trò |
|------|---------|
| `CallView.swift` | Giao diện full-screen cho cuộc gọi (audio/video) |
| `CallViewModel.swift` | ViewModel quản lý trạng thái cuộc gọi và kết nối với CallService |

## Tính năng chính

- **Gọi đi** (audio/video): hiển thị trạng thái Calling → Ringing → Connecting → Connected
- **Nhận cuộc gọi**: hiển thị nút Accept/Reject
- **Trong cuộc gọi**: Mute/Unmute, Speaker on/off, Flip camera (video), Hangup
- **Video call**: hiển thị remote video full-screen + local video picture-in-picture
- **Audio call**: gradient background + avatar người gọi
- **Đồng hồ thời gian**: đếm thời gian cuộc gọi (mm:ss) khi connected
- **Xử lý kết thúc**: hiển thị lý do (Call Ended, Declined, Busy, No Answer, Failed, Cancelled)
- **Reconnecting state**: hiển thị khi mất kết nối tạm thời

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `CallService` (singleton, quản lý WebRTC/VoIP)
- State management: subscribe `callStatePublisher` từ CallService qua Combine
- Timer: sử dụng `Task` async để cập nhật thời gian cuộc gọi mỗi giây

## CallState Enum

```
idle → initiating → ringing → connecting → connected → ending → ended(reason)
                  → incomingRinging (cuộc gọi đến)
                  → reconnecting (mất kết nối tạm)
```

## Custom UI Components

- `CallButton`: nút tròn với icon + color (Accept/Reject/Hangup)
- `CallToggleButton`: nút toggle với label (Mute/Speaker/Flip)
