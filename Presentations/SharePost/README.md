# SharePost - Chia sẻ bài viết

## Mô tả

Module xử lý giao diện chia sẻ (share) bài post cho người dùng khác qua tin nhắn, hoặc qua các kênh bên ngoài (Message, Email, Copy Link).

## Danh sách file

| File | Vai trò |
|------|---------|
| `SharePostView.swift` | Giao diện share sheet: search + quick share + user list + external options |
| `SharePostViewModel.swift` | ViewModel quản lý load users, toggle selection, send, copy link |

## Tính năng chính

### Quick Share Section
- **Add to Story**: chia sẻ lên story (placeholder)
- **Close Friends**: chia sẻ cho close friends (placeholder)
- **Copy Link**: copy URL post vào clipboard (`UIPasteboard`)

### User Selection
- **Search bar**: filter users theo username/fullName
- **Danh sách users**: avatar + username + fullName + checkbox selection
- **Multi-select**: cho phép chọn nhiều người cùng lúc
- **Toggle selection**: tap row hoặc tap checkbox

### Send
- **Send button**: hiện khi có >= 1 user được chọn, thay thế external bar
- **Send logic**: tạo conversation + gửi message với content `.post(postId:)` cho mỗi user

### External Share Bar
- Message, Email, More (hiện khi chưa chọn user nào)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `UserRepositoryProtocol`, `MessageRepositoryProtocol`
- Input: `postId: String`
- Users: load từ `fetchSuggested` (recent/suggested users)
- Filter: local filter qua `filteredUsers(query:)`
- Selection: `Set<String>` (selectedUserIds)
- Copy link format: `https://instagram.com/p/{postId}`

## Luồng hoạt động

```
Present sheet → loadUsers()
→ User search/scroll → select users (multi)
→ Tap "Send" → sendToSelected() [create conversation + send for each]
→ dismiss
```
