# EditPost - Chỉnh sửa bài viết

## Mô tả

Module cho phép user chỉnh sửa thông tin của một bài post đã đăng — mô phỏng màn hình "Edit info" của Instagram. Chỉ cho sửa **caption** và **location**; media là bất biến (immutable) sau khi đăng, đúng như Instagram. Hiển thị dạng sheet với `NavigationStack` riêng (Cancel/Save).

## Danh sách file

| File | Vai trò |
|------|---------|
| `EditPostView.swift` | Giao diện "Edit info": header (thumbnail + username read-only) + caption editor + location field |
| `EditPostViewModel.swift` | ViewModel: load post, theo dõi thay đổi, validate, save |

## Tính năng chính

- **Nav bar**: title "Edit info", Cancel (leading), Save (trailing, bold, disable khi đang lưu hoặc chưa có thay đổi)
- **Header**: thumbnail media đầu tiên (bo góc nhỏ) + username tác giả (read-only) qua `LazyImage` (Nuke)
- **Caption editor**: `TextField` multi-line (4-10 dòng) prefilled + character counter (max `DS.Layout.maxCaptionLength` = 2200, đỏ khi vượt)
- **Location**: `TextField` single-line prefilled với `location?.name`; để trống → gửi `nil`
- **Loading state**: `ProgressView` khi đang fetch post lần đầu
- **Error state**: `ErrorStateView` + retry khi fetch thất bại
- **Save flow**: HUD loading → success → dismiss sheet; thất bại → HUD/Toast error, giữ nguyên màn hình
- **Discard confirmation**: `confirmationDialog` "Discard changes?" khi Cancel lúc có thay đổi chưa lưu

## Architecture

- Pattern: MVVM với `@MainActor @Observable`
- Dependencies: `FetchPostDetailUseCaseProtocol`, `UpdatePostUseCaseProtocol`
- Navigation: presented qua `AppSheet.editPost(postId:)`; dismiss qua `AppRouter.shared.dismiss()`
- Flow: `loadPost()` → populate caption/location → user edits → `save()` → `UpdatePostUseCase` → `didSave` → dismiss

## Change Tracking & Validation

| Mục | Quy tắc |
|-----|---------|
| Caption | <= 2200 ký tự (counter, đỏ khi quá) |
| Location | Không bắt buộc; xóa hết → gửi `nil` |
| Save enabled | `post != nil && hasChanges && isCaptionValid && !isSaving` |
