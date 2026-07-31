# Auth - Xác thực người dùng

## Mô tả

Module xử lý toàn bộ luồng xác thực (đăng nhập/đăng ký) của ứng dụng. Hỗ trợ chuyển đổi giữa 2 chế độ Login và Register trên cùng một màn hình.

## Danh sách file

| File | Vai trò |
|------|---------|
| `AuthViewModel.swift` | ViewModel quản lý state và business logic cho xác thực |
| `LoginView.swift` | Giao diện màn hình đăng nhập/đăng ký |

## Tính năng chính

- **Đăng nhập** bằng email + password (validate email hợp lệ, password >= 6 ký tự)
- **Đăng ký** với full name, email, phone, password, confirm password
- **Chuyển đổi** giữa mode Login và Register bằng nút toggle
- **Hiển thị lỗi** với banner cảnh báo (icon + message)
- **Loading state** với ProgressView khi đang xử lý
- **Auto-fill credentials** trong chế độ DEBUG/Mock để tiện test
- **Validation realtime**: nút submit disable khi form chưa hợp lệ
- **Forgot Password** placeholder (chưa implement)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `LoginUseCaseProtocol`, `RegisterUseCaseProtocol`, `AppRouter`
- Sau khi xác thực thành công: lưu session qua `SessionStore`, set `router.isAuthenticated = true`

## UI Components sử dụng

- `FloatingTextField` (custom text field với floating label)
- Design System tokens: `DS.Font`, `DS.Spacing`, `DS.Radius`, `ColorTokens`
- Localization: `L10n.Auth.*`
