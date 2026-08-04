# Explore - Khám phá nội dung

## Mô tả

Module hiển thị trang Explore (Discover) với grid ảnh/video và chức năng tìm kiếm user. Kết hợp 2 chế độ: browse grid và search results.

## Danh sách file

| File | Vai trò |
|------|---------|
| `ExploreView.swift` | Giao diện grid explore + search overlay + search results |
| `ExploreViewModel.swift` | ViewModel quản lý load explore posts, search users |

## Tính năng chính

- **Explore Grid**: LazyVGrid 3 cột hiển thị thumbnails bài viết
- **Multi-image indicator**: icon overlay cho posts có nhiều ảnh
- **Search bar** (`.searchable`): luôn hiển thị ở navigation bar
- **Tìm kiếm user**: khi nhập >= 2 ký tự → hiển thị danh sách kết quả
- **Search results**: avatar + username + verified badge + full name
- **Navigation**: tap post → postDetail, tap user → userProfile
- **Loading state**: ProgressView khi đang tải

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `PostRepositoryProtocol`, `SearchUsersUseCaseProtocol`
- 2 mode hiển thị: `searchText.isEmpty` → grid, else → search results list
- Search debounce: trigger `search()` qua `.onChange(of: searchText)`

## Grid Layout

```
[  ][  ][  ]    ← 3 columns
[  ][  ][  ]    ← flexible spacing: DS.Size.gridSpacing
[  ][  ][  ]
```

## Components phụ

- `ExploreGridItem`: cell hiển thị thumbnail + multi-image badge
- `SearchResultRow`: row hiển thị user info cho search results
