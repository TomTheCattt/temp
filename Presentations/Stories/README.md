# Stories - Xem và hiển thị Stories

## Mô tả

Module xử lý toàn bộ tính năng Stories: thanh stories ngang ở đầu feed, viewer full-screen cho stories người khác, và viewer cho stories của bản thân (với chức năng quản lý).

## Danh sách file

| File | Vai trò |
|------|---------|
| `StoriesBarView.swift` | Thanh stories ngang (horizontal scroll) ở đầu feed |
| `StoryViewerView.swift` | Full-screen viewer xem stories người khác (progress + navigation + reply) |
| `StoryViewerViewModel.swift` | ViewModel quản lý navigation giữa stories/items, progress, pause/resume |
| `MyStoryView.swift` | Full-screen viewer cho stories của bản thân (viewers + delete + share) |
| `StoryVideoPlayer.swift` | Video player chuyên dụng cho story items (progress tracking, no loop) |

## Tính năng chính

### StoriesBarView
- **Horizontal scroll**: LazyHStack các story circles
- **"Your Story" button**: avatar current user + plus badge
  - Có story → mở `MyStoryView`
  - Chưa có → mở `StoryCameraView`
- **Story circles** (StoryCircleView): avatar với gradient ring (red→orange→yellow) cho unviewed, gray ring cho viewed
- **Username** dưới mỗi circle
- **Filter**: ẩn current user khỏi danh sách (hiển thị riêng ở "Your Story")

### StoryViewerView (xem stories người khác)
- **Progress bars**: HStack capsules ở trên cùng, fill theo progress
- **Header**: avatar + username + relative time + close button
- **Tap navigation**: tap trái (30%) = previous, tap phải (70%) = next
- **Long press**: pause/resume playback
- **Image stories**: timer-based progress (default 5s/item, tick 0.05s)
- **Video stories**: progress từ `StoryVideoPlayer` callback
- **Reply bar**: TextField "Send message" + Heart + Paperplane
- **Stickers**: location, mention, music, poll (overlay trên content)
- **Multi-story navigation**: tự chuyển sang story của user tiếp theo
- **Scene phase handling**: pause khi app vào background
- **Content card**: rounded corners (12pt)
- **Auto-dismiss**: khi hết story cuối cùng

### MyStoryView (xem stories của mình)
- Giống StoryViewerView nhưng:
  - **Không có reply bar** (thay bằng bottom bar)
  - **Bottom bar**: Viewers (stacked avatars) + Close Friends + Delete + More
  - **Delete confirmation**: ConfirmationDialog trước khi xóa
  - **Header**: "Your Story" thay vì username

### StoryViewerViewModel
- **Navigation**: `goToNext()`, `goToPrevious()`, `jumpToStory(at:)`
- **Progress tracking**: `itemProgress` (0.0 → 1.0)
- **Pause/Resume**: `isPaused` flag
- **Multi-story**: `currentStoryIndex` + `currentItemIndex`
- **Load stories**: fetch từ API, jump đến `targetUserId` nếu specified

### StoryVideoPlayer
- **No looping** (khác ReelVideoPlayer): stories auto-advance khi hết
- **Progress callback**: `onProgressUpdate((Double) -> Void)` — sync với progress bar
- **End callback**: `onVideoEnded(() -> Void)` — trigger advance
- **Pause support**: `isPaused` binding
- **Duration loading**: async `AVAsset.load(.duration)` (iOS 16+)
- **Periodic time observer**: cập nhật progress mỗi 0.1s

## Architecture

- Pattern: MVVM với `@Observable`
- Dependencies: `FetchStoriesUseCaseProtocol`
- Data models: `Story` (author + items), `StoryItem` (type: image/video, mediaURL, duration, sticker)
- Timer: `Timer.scheduledTimer` cho image items
- Video: `StoryPlayerHolder` (ObservableObject) + `VideoPlayerManager.shared`
- Stickers: `StoryStickerInfo` (type: location/mention/music/poll/etc, data)

## Sticker Types

| Type | UI |
|------|-----|
| location | 📍 + text trong capsule material |
| mention | @text trong capsule material |
| music | 🎵 + text trong capsule material |
| poll | question + Yes/No buttons |

## Constants

- Story item duration (image): `DS.Duration.storyItem`
- Timer tick: `DS.Duration.storyTick`
- Content corner radius: 12pt
