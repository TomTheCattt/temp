# EditProfile - Chỉnh sửa hồ sơ

## Mô tả

Module cho phép user chỉnh sửa thông tin cá nhân: avatar, tên, bio, website. Hiển thị dạng Form với các section rõ ràng.

## Danh sách file

| File | Vai trò |
|------|---------|
| `EditProfileView.swift` | Giao diện Form chỉnh sửa profile (avatar + fields + bio) |
| `EditProfileViewModel.swift` | ViewModel quản lý load profile hiện tại, validate, save changes |

## Tính năng chính

- **Đổi avatar**: PhotosPicker cho phép chọn ảnh mới, hiển thị preview ngay lập tức
- **Chỉnh sửa tên** (name): TextField
- **Username**: hiển thị nhưng disabled (không cho đổi)
- **Website**: TextField với keyboard URL
- **Bio**: TextField multi-line (3-5 dòng) + character counter (max 150)
- **Validation**: bio length check, disable nút Done khi invalid
- **Loading state**: ProgressView overlay khi đang load profile
- **Error handling**: Alert hiển thị lỗi
- **Auto dismiss**: đóng sheet khi save thành công

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `UpdateProfileUseCaseProtocol`, `UserRepositoryProtocol`
- Flow: `loadProfile()` → populate fields → user edits → `save()` → update profile + avatar → dismiss

## Validation Rules

| Field | Rule |
|-------|------|
| Bio | <= 150 ký tự (hiển thị counter, đỏ khi quá) |
| Name | Không bắt buộc |
| Website | Không bắt buộc, keyboard URL |
| Username | Read-only |
