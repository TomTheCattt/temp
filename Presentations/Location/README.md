# Location - Trang Location

## Mô tả

Module hiển thị trang chi tiết của một địa điểm (location): bản đồ placeholder, action buttons, và grid các bài post tại địa điểm đó.

## Danh sách file

| File | Vai trò |
|------|---------|
| `LocationView.swift` | Giao diện trang location: map + actions + grid posts |
| `LocationViewModel.swift` | ViewModel quản lý load posts theo location, phân trang |

## Tính năng chính

- **Map placeholder**: RoundedRectangle với icon map + tên location (chưa tích hợp MapKit)
- **Action buttons**: "Directions" (chỉ đường) + "Save" (lưu địa điểm)
- **Posts grid**: LazyVGrid 3 cột hiển thị thumbnails tại location
- **Navigation title**: tên location (large display mode)
- **Loading state**: ProgressView khi đang tải
- **Navigation**: tap post → push `.postDetail(postId:)`
- **Phân trang**: load more (30 items/page)

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `PostRepositoryProtocol`
- Mock: dùng `fetchExplorePosts` làm data giả cho posts tại location
- Future: tích hợp MapKit với coordinate thực + filter posts theo geo

## Layout

```
┌─────────────────────────────┐
│      [Map Placeholder]      │  ← 150pt height
│       📍 Location Name      │
├─────────────────────────────┤
│ [Directions] [Save]         │  ← Action buttons
├─────────────────────────────┤
│ [img] [img] [img]           │
│ [img] [img] [img]           │  ← 3-column grid
└─────────────────────────────┘
```
