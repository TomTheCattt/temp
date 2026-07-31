# Search - Kết quả tìm kiếm

## Mô tả

Module hiển thị kết quả tìm kiếm chi tiết với 4 tab: Top (tổng hợp), Accounts (users), Tags (hashtags), Places (địa điểm).

## Danh sách file

| File | Vai trò |
|------|---------|
| `SearchResultsView.swift` | Giao diện kết quả tìm kiếm với 4 tab categories |
| `SearchResultsViewModel.swift` | ViewModel quản lý load kết quả (users + posts) |

## Tính năng chính

### Tab Picker
- Horizontal scroll chips: Top / Accounts / Tags / Places
- Selected state: filled background, bold font, inverted colors
- Tap to switch tab content

### Tab: Top
- Top 3 users (avatar + username + verified + name)
- Posts grid (3 cột) bên dưới

### Tab: Accounts
- Full danh sách users matching query

### Tab: Tags
- Danh sách hashtags: icon "#" + `#{query}` + random post count
- Tap → navigate `.hashtag(name:)`

### Tab: Places
- Danh sách locations: icon mappin + "Location X" + "City, Country"
- Tap → navigate `.location(name:)`

### General
- **Loading state**: ProgressView center
- **Navigation**: tap user → `.userProfile`, tap post → `.postDetail`, tap tag → `.hashtag`, tap place → `.location`

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `SearchUsersUseCaseProtocol`, `PostRepositoryProtocol`
- Concurrent loading: `async let` cho users và posts song song
- Data: `SearchTab` enum (Top, Accounts, Tags, Places)
- Tags/Places: mock data (placeholder, chưa có real API)

## SearchTab Enum

```swift
enum SearchTab: String, CaseIterable {
    case top = "Top"
    case accounts = "Accounts"
    case tags = "Tags"
    case places = "Places"
}
```
