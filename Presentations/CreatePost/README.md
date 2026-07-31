# CreatePost - Tạo bài viết mới

## Mô tả

Module xử lý flow tạo bài post mới với 3 bước: chọn media → áp dụng filter → viết caption và đăng. Hỗ trợ chọn nhiều ảnh/video từ thư viện.

## Danh sách file

| File | Vai trò |
|------|---------|
| `CreatePostView.swift` | Giao diện 3 bước tạo post (media → filter → caption) |
| `CreatePostViewModel.swift` | ViewModel quản lý state qua các bước, load media, publish |
| `FilterSelectionView.swift` | Component chọn filter ảnh (Instagram-style strip + preview + intensity slider) |

## Tính năng chính

### Bước 1: Select Media
- **PhotosPicker** (SwiftUI native) cho phép chọn tối đa N ảnh/video
- Hiển thị preview ảnh đầu tiên + badge số lượng đã chọn
- Auto-advance sang bước Filter khi có media

### Bước 2: Apply Filter
- Preview ảnh lớn ở trên
- Horizontal scroll strip các filter thumbnails phía dưới
- 12 filter: Normal, Clarendon, Gingham, Moon, Lark, Reyes, Juno, Slumber, Crema, Ludwig, Aden, Perpetua
- **Intensity slider**: điều chỉnh cường độ filter (0-100%)
- Double-tap filter: toggle slider hiện/ẩn
- Real-time preview qua `FilterEngine` + `CIImage`

### Bước 3: Caption & Share
- Preview thumbnail nhỏ + text field viết caption (multi-line)
- Add Location (placeholder)
- Tag People (placeholder)
- Share to Facebook/Twitter toggles
- Nút Share ở toolbar

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `CreatePostUseCaseProtocol`
- Step navigation: enum `CreatePostStep` (.selectMedia → .applyFilter → .captionAndShare)
- Filter engine: `FilterEngine.shared`, `FilterThumbnailGenerator.shared`, `FilterRegistry`

## Flow

```
PhotosPicker → loadSelectedMedia() → auto advance to Filter
→ goToNextStep() → Caption
→ publish() → dismiss on success
```

## Validation

- `canProceedFromMedia`: có ít nhất 1 ảnh
- `canPublish`: có media + không đang publishing
