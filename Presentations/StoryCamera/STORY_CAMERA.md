# StoryCamera - Camera tạo Story

## Mô tả

Module xử lý flow tạo story mới: camera capture (chụp ảnh/quay video) → preview/edit → publish. Hỗ trợ nhiều chế độ chụp và các công cụ chỉnh sửa.

## Danh sách file

| File | Vai trò |
|------|---------|
| `StoryCameraView.swift` | Giao diện 2 màn hình: camera capture + preview/edit/publish |
| `StoryCameraViewModel.swift` | ViewModel quản lý permissions, capture, switch camera, gallery load, publish story |
| `CameraPreviewView.swift` | Component UIViewRepresentable bọc AVCaptureVideoPreviewLayer |
| `Core/Camera/CameraService.swift` | Service AVFoundation quản lý capture session, inputs, outputs, photo capture và movie recording |

## Tính năng chính

### Camera Screen
- **Camera preview**: Full-screen rounded bọc `AVCaptureVideoPreviewLayer` theo thời gian thực (tự động fallback sang Simulator mode khi chạy trên máy ảo)
- **Top bar**: Close (X) + Flash / Torch toggle + Settings
- **Mode selector** (horizontal scroll): Normal, Boomerang, Layout, Multi-Capture, Hands-Free
- **Capture button**: trắng cho photo, đỏ cho recording (shape thay đổi)
- **Gallery button** (trái): Tích hợp `PhotosPicker` chọn ảnh/video trực tiếp từ thư viện máy
- **Flip camera** (phải): chuyển front/back camera phần cứng qua `CameraService`
- **Permission handling**: kiểm tra camera + microphone permission
- **Permission denied view**: thông báo + nút "Open Settings"

### Preview/Edit Screen
- **Preview content**: hiển thị ảnh thật (`Image(uiImage:)`) hoặc video phát lại (`VideoPlayer(player:)`)
- **Top bar**: Back (retake) + Edit tools (Text, Sticker, Draw, Music)
- **Bottom buttons**:
  - "Your Story" (xanh): publish lên story
  - "Close Friends" (xám): publish cho close friends
- **Loading overlay**: ProgressView khi đang publishing
- **Auto-dismiss**: khi publish thành công kèm phát thông báo `Notification.Name.didCreateStory` để Stories bar cập nhật ngay lập tức

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `StoryRepositoryProtocol`, `CameraService.shared`
- Permissions: `AVCaptureDevice.requestAccess(for:)` cho camera + microphone
- Capture: `AVCapturePhotoOutput` / `AVCaptureMovieFileOutput` qua `CameraService`
- Gallery: `PhotosPicker` (iOS 16+ native PhotosUI)
- Publish: gọi `storyRepository.createStory(mediaData:, type:, duration:)` và dispatch `.didCreateStory`

## StoryCameraMode Enum

```swift
enum StoryCameraMode: String, CaseIterable {
    case normal = "Normal"
    case boomerang = "Boomerang"
    case layout = "Layout"
    case multiCapture = "Multi-Capture"
    case hands_free = "Hands-Free"
}
```

## Flow

```
checkPermissions() → Camera Screen
→ capturePhoto() / startRecording() + stopRecording()
→ isShowingPreview = true → Preview Screen
→ publishStory() → isPublished = true → dismiss
   or retake() → back to Camera
```

## State Machine

```
Camera (idle)
  ├── capturePhoto() → Preview (image)
  ├── startRecording() → Recording
  │     └── stopRecording() → Preview (video)
  └── gallery (placeholder)

Preview
  ├── retake() → Camera
  └── publishStory() → Publishing → Published → Dismiss
```
