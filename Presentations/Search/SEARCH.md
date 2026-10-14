# Search - Kết quả tìm kiếm

## Mô tả

Module hiển thị kết quả tìm kiếm chi tiết với thanh tìm kiếm tương tác và 4 tab: Hàng đầu (Top), Tài khoản (Accounts), Thẻ (Tags/Hashtags), Địa điểm (Places).

## Danh sách file

| File | Vai trò |
|------|---------|
| `SearchResultsView.swift` | Giao diện kết quả tìm kiếm với active search header, tab chips song ngữ, Nuke LazyImage cache, empty states |
| `SearchResultsViewModel.swift` | ViewModel quản lý load và lọc kết quả (users, posts, tags, places) theo từ khoá tìm kiếm |

## Tính năng chính

### Active Search Header
- TextField tương tác cho phép chỉnh sửa hoặc đổi từ khoá tìm kiếm ngay trên màn hình kết quả
- Nút xoá nhanh (`xmark.circle.fill`)
- Kích hoạt tìm kiếm mới qua `.onSubmit` hoặc kéo làm mới (`.refreshable`)

### Tab Picker
- Horizontal scroll chips: Hàng đầu (Top) / Tài khoản (Accounts) / Thẻ (Tags) / Địa điểm (Places)
- Selected state: filled capsule, chữ đậm tương phản
- Chạm để chuyển đổi nội dung mượt mà

### Tab: Top (Hàng đầu)
- Hiển thị tối đa 3 tài khoản hàng đầu khớp từ khoá (avatar + username + verified badge + full name)
- Grid bài viết (3 cột) liên quan đến từ khoá bên dưới

### Tab: Accounts (Tài khoản)
- Danh sách đầy đủ người dùng khớp với từ khoá tìm kiếm

### Tab: Tags (Thẻ hashtag)
- Danh sách hashtags khớp từ khoá kèm số lượng bài viết xác định
- Chạm → điều hướng `.hashtag(name:)`

### Tab: Places (Địa điểm)
- Danh sách địa điểm khớp từ khoá
- Chạm → điều hướng `.location(name:)`

### Empty State & Cache
- Empty state trực quan cho từng tab khi không có kết quả phù hợp
- Sử dụng `LazyImage` (NukeUI) tối ưu hoá bộ nhớ đệm cache ảnh

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `SearchUsersUseCaseProtocol`, `PostRepositoryProtocol`
- Concurrent loading: `async let` cho users và posts song song
- Data: `SearchTab` enum, `SearchTagItem`, `SearchPlaceItem`
