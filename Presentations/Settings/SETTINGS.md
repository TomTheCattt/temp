# Settings - Cài đặt ứng dụng

## Mô tả

Module quản lý toàn bộ cài đặt ứng dụng: tài khoản, giao diện, thông báo, quyền riêng tư, bảo mật, dữ liệu, thông tin, và đăng xuất. Bao gồm nhiều sub-screens.

## Danh sách file

| File | Vai trò |
|------|---------|
| `SettingsView.swift` | Màn hình Settings chính với các sections (List/Form) |
| `SettingsViewModel.swift` | ViewModel quản lý preferences, load settings, logout |
| `BlockedAccountsView.swift` | Sub-screen: danh sách tài khoản đã chặn |
| `ChangePasswordView.swift` | Sub-screen: form đổi mật khẩu |
| `CloseFriendsView.swift` | Sub-screen: quản lý Close Friends |
| `OpenSourceLicensesView.swift` | Sub-screen: giấy phép mã nguồn mở |
| `PrivacyPolicyView.swift` | Sub-screen: chính sách bảo mật |
| `SavedPostsView.swift` | Sub-screen: grid bài viết đã lưu |
| `TermsOfServiceView.swift` | Sub-screen: điều khoản dịch vụ |
| `TwoFactorAuthView.swift` | Sub-screen: cài đặt xác thực 2 yếu tố |

## SettingsView - Sections chi tiết

### Account
- Edit Profile → present sheet `.editProfile`
- Saved → push `.savedPosts`
- Close Friends → push `.closeFriends`
- Blocked Accounts → push `.blockedAccounts`

### Appearance
- Theme picker: System / Light / Dark (qua `ThemeManager.shared`)

### Notifications
- Push Notifications (master toggle)
- Likes, Comments, New Followers, Direct Messages (sub-toggles, ẩn khi master off)

### Privacy
- Private Account toggle (gọi API khi thay đổi)
- Activity Status toggle

### Security
- Face ID/Touch ID toggle
- Password → push `.changePassword`
- Two-Factor Auth → push `.twoFactorAuth`

### Data & Storage
- High Quality Uploads toggle
- Use Cellular Data toggle
- Clear Cache button

### About
- App Version: "1.0.0"
- Terms of Service → push
- Privacy Policy → push
- Open Source Licenses → push

### Logout
- Confirmation dialog trước khi logout
- Logout: clear session + reset router + set `isAuthenticated = false`
- Force local logout ngay cả khi API fail

## Sub-screens Chi tiết

### BlockedAccountsView
- Explanation text + ContentUnavailableView (empty state)
- TODO: populate với actual blocked accounts

### ChangePasswordView
- Form: Current Password + New Password + Confirm Password
- Validation: current not empty, new >= 6 chars, confirm matches
- Success/Error alerts

### CloseFriendsView
- Explanation text + Searchable + ContentUnavailableView (empty state)
- TODO: populate với actual close friends data

### SavedPostsView
- 3-column grid (placeholder rectangles)
- ContentUnavailableView overlay (empty state)

### TwoFactorAuthView
- Master toggle on/off
- Authentication Method picker: SMS / Authenticator App
- Conditional section (hiện khi enabled)

### OpenSourceLicensesView, PrivacyPolicyView, TermsOfServiceView
- Static content views (placeholder/legal text)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `AuthRepositoryProtocol`, `UserRepositoryProtocol`
- Settings state: local `@State` variables (chưa persist, trừ private account)
- Logout flow: API call → clear `SessionStore` → reset `AppRouter` → set auth = false
