# CreatePost - Tạo bài viết mới

## Mô tả

Module xử lý flow tạo bài post mới với 3 bước: chọn media → áp dụng filter → viết caption và đăng. Hỗ trợ chọn nhiều ảnh/video từ thư viện.

## Danh sách file

| File | Vai trò |
|------|---------|
| `CreatePostView.swift` | Giao diện 3 bước tạo post (media → filter → caption) |
| `CreatePostViewModel.swift` | ViewModel quản lý state qua các bước, load media, bake filter, publish |
| `FilterSelectionView.swift` | Component chọn filter ảnh (Instagram-style strip + preview + intensity slider) |
| `LocationPickerSheet.swift` | Sheet tìm kiếm và chọn địa điểm gắn vào bài viết |

## Tính năng chính

### Bước 1: Select Media
- **PhotosPicker** (SwiftUI native) cho phép chọn tối đa N ảnh/video
- Hiển thị preview ảnh đầu tiên + badge số lượng đã chọn
- Auto-advance sang bước Filter khi có media

### Bước 2: Apply Filter & Carousel
- Preview ảnh lớn ở trên được render theo thời gian thực qua `FilterEngine`
- Strip cuộn thumbnail các bộ lọc Instagram-style
- Hỗ trợ đổi ảnh xem trước khi chọn nhiều ảnh (carousel strip)
- 12 filter màu phong phú từ `FilterRegistry`
- **Intensity slider**: điều chỉnh cường độ filter (0-100%)
- Double-tap filter: toggle slider hiện/ẩn
- Tự động bake filter vào ảnh gốc thành JPEG Data khi publish

### Bước 3: Caption & Share
- Preview thumbnail nhỏ + text field viết caption (multi-line)
- **Add Location**: Tích hợp `LocationPickerSheet` cho phép tìm kiếm hoặc chọn địa điểm gợi ý, có nút gỡ địa điểm
- Tag People (placeholder)
- Share to Facebook/Twitter toggles
- Nút Share ở toolbar
- Phát sự kiện `Notification.Name.didCreatePost` khi đăng thành công để Feed cập nhật ngay lập tức

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `CreatePostUseCaseProtocol`
- Step navigation: enum `CreatePostStep` (.selectMedia → .applyFilter → .captionAndShare)
- Filter engine: `FilterEngine.shared`, `FilterThumbnailGenerator.shared`, `FilterRegistry`
- Event sync: `NotificationCenter.default.post(name: .didCreatePost, object: post)`

## Flow

```
PhotosPicker → loadSelectedMedia() → auto advance to Filter
→ FilterSelectionView (intensity & filter selection)
→ goToNextStep() → Caption & LocationPickerSheet
→ publish() → bakeFilteredImages() → createPostUseCase.execute()
→ NotificationCenter.post(.didCreatePost) → dismiss on success
```

## Validation

- `canProceedFromMedia`: có ít nhất 1 ảnh
- `canPublish`: có media + không đang publishing
