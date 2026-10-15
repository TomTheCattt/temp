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

### Bước 2: Modern Studio Editor (Immersive Dark Studio)
- **Top Header**: Nút tròn đóng `(X)` trở về chọn ảnh + **Audio Selector Pill** (`MCK · Cảm Ơn 🅴 RP` / "Âm thanh gợi ý" + nút `+` đổi nhạc nền).
- **Central Media Card**: Khung media bo góc cong (`16pt`) với TabView vuốt ngang mượt mà, nút xóa ảnh nhanh `(X)` ở góc trên phải, và Page Indicator Dots (`• •`) đồng bộ thời gian thực.
- **Middle Quick Toolbar (6 công cụ)**:
  1. `Âm thanh` (`music.note`): Mở sheet chọn danh sách nhạc gợi ý / thịnh hành.
  2. `Văn bản` (`Aa`): Công cụ chèn chữ nghệ thuật.
  3. `Lớp phủ` (`square.2.layers.3d`): Chèn ảnh PIP hoặc nhãn dán.
  4. `Bộ lọc` (`camera.filters`): Mở drawer 12 bộ lọc màu với thanh trượt intensity.
  5. `Chỉnh sửa` (`slider.horizontal.3`): Mở drawer tinh chỉnh độ sáng, độ tương phản, độ bão hòa, độ ấm.
  6. `Tỷ lệ` (`aspectratio`): Chuyển đổi khung hình 1:1, 4:5, 9:16 với animation lò xo.
- **Bottom Action Bar**: Strip thumbnail các ảnh đã chọn (viền trắng active) + nút `+` (PhotosPicker) thêm ảnh mới + nút `Tiếp ➔` màu xanh dương nổi bật.
- **Hiệu năng & An toàn bộ nhớ**:
  - Tự động downsample thumbnail nhỏ (120px) cho strip để triệt tiêu tràn RAM.
  - Vòng lặp nén và bake filter được bọc hoàn toàn trong `@autoreleasepool { ... }` giải phóng bộ nhớ ngay tức thì.
  - Sử dụng `HapticFeedbackSafe` tránh crash/warning trên Simulator.

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
