# Explore - Khám phá nội dung

## Mô tả

Module hiển thị trang Explore (Khám phá) với grid ảnh/video, bộ lọc chủ đề đề xuất, và chế độ tìm kiếm tài khoản/bài viết tích hợp.

## Danh sách file

| File | Vai trò |
|------|---------|
| `ExploreView.swift` | Giao diện grid explore + search bar active mode + category pills + search overlay |
| `ExploreViewModel.swift` | ViewModel quản lý load explore posts, lọc bài viết theo chủ đề, tìm kiếm người dùng với debounce 300ms và phân trang |

## Tính năng chính

- **Explore Grid**: LazyVGrid 3 cột hiển thị thumbnails bài viết, hỗ trợ pull-to-refresh (`.refreshable`) và infinite scrolling (`loadMoreExplore`)
- **Lọc bài viết theo chủ đề (Category Pills)**:
  - ScrollView ngang bên dưới header chứa các danh mục: "Dành cho bạn", "Nhiếp ảnh", "Du lịch", "Thời trang", "Ẩm thực", "Âm nhạc", "Thể thao", "Kiến trúc", "Công nghệ", "Nghệ thuật"
  - Chạm vào chủ đề sẽ lọc bài viết Explore theo chủ đề tương ứng (không nhầm lẫn với tìm kiếm tài khoản)
- **Search Active Mode & Nút Cancel**:
  - Khi người dùng chạm vào ô tìm kiếm hoặc nhập văn bản, thanh header chuyển sang Search Active Mode với nút "Cancel" bên phải
  - Chạm "Cancel" lập tức xoá từ khoá, ẩn bàn phím và quay lại Explore Grid với animation mượt mà
- **Debounced Search**:
  - Gõ phím kích hoạt tìm kiếm với khoảng trễ 300ms, tự động huỷ task cũ (`searchTask?.cancel()`) tránh race condition
- **Điều hướng kết quả đầy đủ**:
  - Nhấn Enter/Search trên bàn phím (`.onSubmit`) sẽ điều hướng sang màn hình kết quả chuyên sâu `SearchResultsView(query:)` (Top, Accounts, Tags, Places)
- **Empty & Hint States**:
  - Trạng thái gợi ý khi vừa mở tìm kiếm
  - Hướng dẫn nhập ít nhất 2 ký tự
  - Thông báo rõ ràng khi không tìm thấy kết quả nào

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `PostRepositoryProtocol`, `SearchUsersUseCaseProtocol`
- Chế độ hiển thị: `isSearchActive` → Search Results Overlay, `!isSearchActive` → Explore Grid + Category Pills
