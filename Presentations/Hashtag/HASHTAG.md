# Hashtag - Trang Hashtag

## Mô tả

Module hiển thị trang chi tiết của một hashtag: header thông tin + grid các bài post liên quan. Tương tự trang hashtag trên Instagram.

## Danh sách file

| File | Vai trò |
|------|---------|
| `HashtagView.swift` | Giao diện trang hashtag: header + grid posts |
| `HashtagViewModel.swift` | ViewModel quản lý load posts theo hashtag, phân trang |

## Tính năng chính

- **Header**: icon "#" lớn trong circle + số posts (format K/M) + nút Follow
- **Posts grid**: LazyVGrid 3 cột hiển thị thumbnails
- **Navigation title**: `#hashtagName` (large display mode)
- **Loading state**: ProgressView khi đang tải
- **Navigation**: tap post → push `.postDetail(postId:)`
- **Phân trang**: load more (30 items/page)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `PostRepositoryProtocol`
- Mock: dùng `fetchExplorePosts` + random count (10K-500K) làm data giả
- Format count: 1000+ → "1.0K", 1000000+ → "1.0M"

## Layout

```
┌─────────────────────────────┐
│  [#]  12.5K posts  [Follow] │  ← Header
├─────────────────────────────┤
│ [img] [img] [img]           │
│ [img] [img] [img]           │  ← 3-column grid
│ [img] [img] [img]           │
└─────────────────────────────┘
```
