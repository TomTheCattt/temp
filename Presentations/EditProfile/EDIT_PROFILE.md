# EditProfile - Chỉnh sửa hồ sơ

## Mô tả

Module cho phép user chỉnh sửa thông tin cá nhân: avatar, tên, bio, website. Hiển thị dạng Form với các section rõ ràng, đồng bộ hai chiều với SessionStore và ProfileView qua hệ thống thông báo reactive.

## Danh sách file

| File | Vai trò |
|------|---------|
| `EditProfileView.swift` | Giao diện Form chỉnh sửa profile (avatar action sheet, preview, text fields, discard confirmation, resign keyboard) |
| `EditProfileViewModel.swift` | ViewModel quản lý load profile hiện tại, theo dõi thay đổi (`hasChanges`), nén ảnh, gỡ avatar, validate, save và đồng bộ `SessionStore` + `AppNotifications` |

## Tính năng chính

- **Đổi avatar**: 
  - Confirmation dialog: "Choose from Library", "Remove Current Photo" (nếu có ảnh), "Cancel"
  - Nén và resize ảnh (max 800x800, JPEG 0.85) tránh quá tải dung lượng
  - Hiển thị preview tức thì bằng `LazyImage` (NukeUI) kèm placeholder icon chuẩn
- **Chỉnh sửa tên** (name): TextField tự động viết hoa từ (`.words`), trim khoảng trắng
- **Username**: hiển thị dạng read-only disabled
- **Website**: TextField với keyboard URL, tắt autocorrect, tự động chuẩn hoá scheme `https://` và validate cú pháp URL
- **Bio**: TextField multi-line (3-5 dòng) + character counter (max 150)
- **Validation nút Done**: Tự động disable khi đang lưu (`isSaving`), khi chưa có thay đổi nào (`!hasChanges`) hoặc bio vượt quá độ dài (`!isBioValid`)
- **Discard changes**: Xác nhận huỷ bỏ thay đổi khi bấm Cancel nếu người dùng đã chỉnh sửa
- **Bàn phím**: Tự động ẩn bàn phím khi tap ra ngoài Form
- **Đồng bộ dữ liệu (Data Sync)**:
  - Cập nhật trực tiếp `SessionStore.shared` (Single Source of Truth)
  - Phát thông báo `Notification.Name.didUpdateProfile`
  - `ProfileView` tự động cập nhật UI tức thì khi nhận thông báo và hỗ trợ `.refreshable` kéo để làm mới
  - Hỗ trợ lưu trữ in-memory trong `MockUserStore` cho phiên chạy development

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `UpdateProfileUseCaseProtocol`, `UserRepositoryProtocol`
- Flow: `loadProfile()` → ghi nhận `initialValues` → user edits → `save()` → `updateProfileUseCase` / `updateAvatar` → `SessionStore.setSession` → `post(.didUpdateProfile)` → dismiss

## Validation Rules

| Field | Rule |
|-------|------|
| Bio | <= 150 ký tự (hiển thị counter, đỏ khi quá) |
| Name | Không bắt buộc, trim khoảng trắng |
| Website | Không bắt buộc, keyboard URL, tự động chuẩn hoá `https://` |
| Username | Read-only |
| Avatar | Tối ưu kích thước tối đa 800x800, hỗ trợ gỡ avatar |
