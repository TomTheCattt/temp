# Tài Liệu Bảng Đối Soát & Phân Loại Asset: Missing Assets & Fallback Catalog

Tài liệu này ghi nhận kết quả rà soát toàn bộ các biểu tượng được sử dụng trong mã nguồn ứng dụng Instagram iOS (`Presentations/`), phân loại giữa tài nguyên đồ họa gốc của Instagram và các biểu tượng tiện ích hệ thống iOS cần cơ chế fallback.

---

## 1. Tổng Quan Rà Soát

- **Tổng số SF Symbols duy nhất trong app**: 84 symbols (tổng cộng 246 vị trí gọi).
- **Số symbols đã có asset tương ứng 1:1 trong `Instagram Icon/`**: 54 symbols.
- **Số symbols bị thiếu trong `Instagram Icon/` (Cần cơ chế Fallback qua `AppIcon.system`)**: 30 symbols.
- **Nguyên tắc xử lý**: 
  - Toàn bộ View **không được gọi trực tiếp `Image(systemName:)`**.
  - Tất cả phải thông qua component thống nhất: `InstagramIcon(_ icon: AppIcon)`.
  - Nếu asset tồn tại trong Asset Catalog: nạp file PNG đồ họa chuẩn Instagram.
  - Nếu asset nằm trong danh sách thiếu dưới đây: `InstagramIcon` tự động kích hoạt fallback an toàn qua `case .system(name: String)`.

---

## 2. Bảng Danh Mục Các Asset Bị Thiếu & Cơ Chế Fallback

| STT | SF Symbol Bị Thiếu | Tệp Nguồn & Dòng Lệnh Gọi Điển Hình | Ngữ Cảnh Chức Năng (Feature Context) | Phương Án Fallback Qua `AppIcon` |
|---|---|---|---|---|
| 1 | `arrow.down.circle.fill` | `Presentations/System/ForceUpdateView.swift:30` | Nút cập nhật ứng dụng bắt buộc khi phiên bản quá cũ | `AppIcon.system(name: "arrow.down.circle.fill")` |
| 2 | `arrow.right` | `Presentations/CreatePost/CreatePostView.swift:858` | Nút mũi tên tiếp tục chuyển bước tạo bài đăng | `AppIcon.system(name: "arrow.right")` |
| 3 | `arrow.triangle.2.circlepath` | `Presentations/CreatePost/CreativeModes/StoryCameraView.swift:432` | Đổi camera trước / sau trong Story Camera | `AppIcon.system(name: "arrow.triangle.2.circlepath")` |
| 4 | `arrow.triangle.2.circlepath.camera` | `Presentations/DirectMessages/CallView.swift:111` | Lật camera trong màn hình cuộc gọi Video Call | `AppIcon.system(name: "arrow.triangle.2.circlepath.camera")` |
| 5 | `arrow.uturn.backward` | `Presentations/CreatePost/CreativeStudio/StoryDrawingCanvasView.swift:135` | Nút Hoàn tác nét vẽ (Undo) trên canvas | `AppIcon.system(name: "arrow.uturn.backward")` |
| 6 | `arrow.uturn.forward` | `Presentations/CreatePost/CreativeStudio/StoryDrawingCanvasView.swift:147` | Nút Làm lại nét vẽ (Redo) trên canvas | `AppIcon.system(name: "arrow.uturn.forward")` |
| 7 | `arrowshape.turn.up.left.fill` | `Presentations/DirectMessages/ChatView.swift:650` | Chỉ báo đang trả lời tin nhắn (Reply preview bar) | `AppIcon.system(name: "arrowshape.turn.up.left.fill")` |
| 8 | `aspectratio` | `Presentations/CreatePost/CreatePostView.swift:245` | Nút chuyển đổi tỷ lệ khung hình ảnh (1:1, 4:5, 16:9) | `AppIcon.system(name: "aspectratio")` |
| 9 | `circle.hexagongrid` | `Presentations/CreatePost/CreativeModes/StoryCameraView.swift:203` | Nút chế độ quay Boomerang trong camera | `AppIcon.system(name: "circle.hexagongrid")` |
| 10 | `circle.inset.filled` | `Presentations/CreatePost/CreativeModes/StoryCameraView.swift:293` | Nút chụp ảnh / quay video trung tâm | `AppIcon.system(name: "circle.inset.filled")` |
| 11 | `circle.lefthalf.filled` | `Presentations/CreatePost/FilterSelectionView.swift:86` | Nút xem so sánh ảnh trước / sau khi áp bộ lọc | `AppIcon.system(name: "circle.lefthalf.filled")` |
| 12 | `exclamationmark.circle.fill` | `Presentations/DirectMessages/ChatView.swift:328` | Chỉ báo tin nhắn gửi thất bại (failed delivery) | `AppIcon.system(name: "exclamationmark.circle.fill")` |
| 13 | `exclamationmark.triangle` | `Presentations/Feed/MediaViewerView.swift:108` | Cảnh báo lỗi tải tệp media độ phân giải cao | `AppIcon.system(name: "exclamationmark.triangle")` |
| 14 | `exclamationmark.triangle.fill` | `Presentations/Auth/LoginView.swift:138` | Cảnh báo lỗi xác thực đăng nhập tài khoản | `AppIcon.system(name: "exclamationmark.triangle.fill")` |
| 15 | `eyedropper.halffull` | `Presentations/CreatePost/CreativeModes/CreateCanvasView.swift:1078` | Công cụ trích xuất màu vẽ (Color Eyedropper) | `AppIcon.system(name: "eyedropper.halffull")` |
| 16 | `f.circle.fill` | `Presentations/CreatePost/CreativeModes/CreateCanvasView.swift:817` | Nút chuyển đổi font chữ trên Story canvas | `AppIcon.system(name: "f.circle.fill")` |
| 17 | `gearshape` | `Presentations/CreatePost/CreativeModes/StoryCameraView.swift:349` | Nút cài đặt camera Story (Flash, Grid, Timer) | `AppIcon.system(name: "gearshape")` |
| 18 | `infinity` | `Presentations/Auth/LoginView.swift:200` | Biểu tượng thương hiệu Meta / Boomerang vô cực | `AppIcon.system(name: "infinity")` |
| 19 | `info.circle` | `Presentations/Explore/ExploreView.swift:253` | Nút xem thông tin chi tiết bài viết Explore | `AppIcon.system(name: "info.circle")` |
| 20 | `map` / `map.fill` | `Presentations/Feed/LocationView.swift:54` | Bản đồ vị trí gắn kèm bài viết | `AppIcon.system(name: "map.fill")` |
| 21 | `mic.fill` | `Presentations/DirectMessages/ChatView.swift:726` | Nút giữ để ghi âm tin nhắn thoại trong Chat | `AppIcon.system(name: "mic.fill")` |
| 22 | `pencil.circle.fill` | `Presentations/CreatePost/CreativeStudio/TypographyOverlayView.swift:207` | Nút chỉnh sửa văn bản lớp phủ nghệ thuật | `AppIcon.system(name: "pencil.circle.fill")` |
| 23 | `phone` | `Presentations/DirectMessages/ConversationDetailsView.swift:142` | Nút gọi điện thoại thông thường trong nhóm chat | `AppIcon.system(name: "phone")` |
| 24 | `photo.badge.plus` | `Presentations/CreatePost/CreativeStudio/UniversalCreativeStudioView.swift:121` | Nút thêm ảnh từ thư viện vào Story đa phương tiện | `AppIcon.system(name: "photo.badge.plus")` |
| 25 | `play.circle.fill` / `play.fill` | `Presentations/DirectMessages/ChatView.swift:528, 558` | Nút phát / tạm dừng tin nhắn âm thanh hoặc video | `AppIcon.system(name: "play.fill")` |
| 26 | `plus.circle` | `Presentations/CreatePost/CreativeModes/LayoutCollageView.swift:163` | Nút thêm khung ghép layout ảnh mới | `AppIcon.system(name: "plus.circle")` |
| 27 | `rectangle.split.2x1` | `Presentations/CreatePost/CreativeModes/StoryCameraView.swift:193` | Nút chế độ chia đôi màn hình chụp ảnh | `AppIcon.system(name: "rectangle.split.2x1")` |
| 28 | `sparkles` | `Presentations/CreatePost/CreativeModes/CreateCanvasView.swift:1288` | Nút hiệu ứng lấp lánh AI / Magic Filter | `AppIcon.system(name: "sparkles")` |
| 29 | `square.2.layers.3d` | `Presentations/CreatePost/CreatePostView.swift:781` | Nút sắp xếp thứ tự các layer nhãn dán / chữ | `AppIcon.system(name: "square.2.layers.3d")` |
| 30 | `trash` | `Presentations/CreatePost/CreativeStudio/StoryDrawingCanvasView.swift:159` | Nút xóa toàn bộ nét vẽ hiện tại trên canvas | `AppIcon.system(name: "trash")` |

---

## 3. Hướng Dẫn Sử Dụng Trong Mã Nguồn

Khi gọi bất kỳ biểu tượng nào trong danh sách trên:

```swift
// ✅ Chuẩn Design System: Tự động fallback an toàn, đồng bộ kích thước và màu sắc theme
InstagramIcon(.system(name: "arrow.down.circle.fill"), size: DS.Size.iconDefault, color: ColorTokens.textPrimary)

// ❌ Nghiêm cấm: Gọi trực tiếp Image(systemName:) tại tầng View
Image(systemName: "arrow.down.circle.fill")
```
