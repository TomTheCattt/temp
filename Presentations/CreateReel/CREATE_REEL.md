# CreateReel - Tạo Reel mới

## Mô tả

Module xử lý flow tạo reel (video ngắn) mới với 2 màn hình: capture (quay video/chọn từ gallery) và editor (xem lại + thêm caption + đăng).

## Danh sách file

| File | Vai trò |
|------|---------|
| `CreateReelView.swift` | Giao diện 2 màn hình: camera capture + video editor |
| `CreateReelViewModel.swift` | ViewModel quản lý state capture, load video, publish |

## Tính năng chính

### Capture Screen
- **Camera preview** (placeholder) full-screen với rounded corners
- **Record button**: nhấn để bắt đầu/dừng quay, đổi shape khi recording
- **Duration selector**: 15s / 30s / 60s / 90s chips
- **Tool buttons** bên phải: Flip camera, Flash, Timer, Effects, Layout
- **Gallery picker** (PhotosPicker matching `.videos`): chọn video từ thư viện
- **Audio picker** (placeholder): thêm nhạc nền
- **Top bar**: nút Close + Add Audio + Settings

### Editor Screen
- **Video preview** (placeholder) lớn
- **Caption field**: TextField multi-line (3-5 dòng)
- **Toolbar**: Back (quay lại capture) + Share (publish)
- **Auto dismiss** khi publish thành công

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `ReelRepositoryProtocol`
- State flow: capture → `isShowingEditor = true` → editor → `publish()` → `isPublished = true` → dismiss

## Helpers

- `AnyShape`: type-erased Shape để hỗ trợ conditional `clipShape()` (Circle vs RoundedRectangle cho record button)
