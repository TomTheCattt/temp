# StoryCamera - Camera tạo Story

## Mô tả

Module xử lý flow tạo story mới: camera capture (chụp ảnh/quay video) → preview/edit → publish. Hỗ trợ nhiều chế độ chụp và các công cụ chỉnh sửa.

## Danh sách file

| File | Vai trò |
|------|---------|
| `StoryCameraView.swift` | Giao diện 2 màn hình: camera capture + preview/edit/publish |
| `StoryCameraViewModel.swift` | ViewModel quản lý permissions, capture, publish story |

## Tính năng chính

### Camera Screen
- **Camera preview** (placeholder) full-screen rounded
- **Top bar**: Close (X) + Flash toggle + Settings
- **Mode selector** (horizontal scroll): Normal, Boomerang, Layout, Multi-Capture, Hands-Free
- **Capture button**: trắng cho photo, đỏ cho recording (shape thay đổi)
- **Gallery button** (trái): chọn media từ thư viện
- **Flip camera** (phải): chuyển front/back camera
- **Permission handling**: kiểm tra camera + microphone permission
- **Permission denied view**: thông báo + nút "Open Settings"

### Preview/Edit Screen
- **Preview content**: hiển thị ảnh/video đã capture (placeholder)
- **Top bar**: Back (retake) + Edit tools (Text, Sticker, Draw, Music)
- **Bottom buttons**:
  - "Your Story" (xanh): publish lên story
  - "Close Friends" (xám): publish cho close friends
- **Loading overlay**: ProgressView khi đang publishing
- **Auto-dismiss**: khi publish thành công

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `StoryRepositoryProtocol`
- Permissions: `AVCaptureDevice.requestAccess(for:)` cho camera + microphone
- Capture: placeholder (thực tế sẽ dùng `AVCapturePhotoOutput` / `AVCaptureMovieFileOutput`)
- Publish: gọi `storyRepository.createStory(mediaData:, type:, duration:)`

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
