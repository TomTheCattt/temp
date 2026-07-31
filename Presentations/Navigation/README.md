# Navigation - Điều hướng ứng dụng

## Mô tả

Module quản lý toàn bộ navigation (điều hướng) trong ứng dụng: định nghĩa routes, quản lý navigation state tập trung, và tab bar chính. Đây là trung tâm kết nối tất cả các module Presentation.

## Danh sách file

| File | Vai trò |
|------|---------|
| `AppRoute.swift` | Định nghĩa tất cả routes (push, sheet, fullscreen) và tabs |
| `AppRouter.swift` | Singleton quản lý navigation state tập trung (NavigationPath) |
| `MainTabView.swift` | TabView chính với 5 tabs + routing logic cho mỗi destination |

## Chi tiết từng file

### AppRoute.swift

**AppTab** (5 tabs):
| Tab | Icon | Selected Icon |
|-----|------|---------------|
| Feed | house | house.fill |
| Explore | magnifyingglass | magnifyingglass |
| Reels | play.square | play.square.fill |
| Notifications | heart | heart.fill |
| Profile | person.circle | person.circle.fill |

**AppRoute** (push navigation - Hashable):
- Profile: `userProfile`, `followers`, `following`, `settings`
- Settings sub-screens: `savedPosts`, `closeFriends`, `blockedAccounts`, `changePassword`, `twoFactorAuth`, `termsOfService`, `privacyPolicy`, `openSourceLicenses`
- Feed/Post: `postDetail`, `comments`, `likes`
- Messages: `directMessages`, `conversation`
- Explore: `searchResults`, `hashtag`, `location`

**AppSheet** (modal sheets - Identifiable):
- `createPost`, `createStory`, `createReel`, `editProfile`, `sharePost`, `reportPost`, `editPost`

**AppFullScreen** (full-screen covers - Identifiable):
- `camera`, `mediaViewer`, `storyCamera`, `storyViewer`, `myStory`

### AppRouter.swift

- **Singleton** (`AppRouter.shared`), `@MainActor @Observable`
- **Mỗi tab có NavigationPath riêng**: `feedPath`, `explorePath`, `reelsPath`, `notificationsPath`, `profilePath`
- **API chính**:
  - `push(_ route:)` → thêm route vào stack tab hiện tại
  - `push(_ route:, in tab:)` → push vào tab cụ thể
  - `pop()` → remove route cuối
  - `popToRoot()` → reset path về rỗng
  - `present(sheet:)` / `present(fullScreen:)` → hiển thị modal
  - `dismiss()` → đóng sheet/fullscreen
  - `switchTab(_ tab:, route:)` → đổi tab + optional navigate
  - `reset()` → clear toàn bộ (dùng khi logout)
- `isAuthenticated`: flag kiểm tra trạng thái auth

### MainTabView.swift

- `TabView` với 5 tabs, mỗi tab wrap trong `NavigationStack(path:)`
- **Route destination**: switch trên `AppRoute` → khởi tạo View + ViewModel từ `DIContainer`
- **Sheet content**: switch trên `AppSheet` → khởi tạo modal views
- **FullScreen content**: switch trên `AppFullScreen` → khởi tạo fullscreen views
- **Tab label**: icon thay đổi khi selected (fill variant)

## Architecture

- Centralized navigation: tất cả navigation đi qua `AppRouter.shared`
- Type-safe routing: enum `AppRoute` + `Hashable` cho `NavigationPath`
- DI tại routing layer: `MainTabView` resolve dependencies từ `DIContainer.shared`
- Separation of concerns: Views không biết cách tạo ViewModels → routing layer handle

## Navigation Flow

```
User tap → View gọi AppRouter.shared.push(.route)
→ NavigationPath append → NavigationStack render destination
→ MainTabView.routeDestination() resolve View + ViewModel
```
