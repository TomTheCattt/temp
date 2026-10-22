# Stories - Xem và hiển thị Stories

## Mô tả

Module xử lý toàn bộ tính năng Stories: thanh stories ngang ở đầu feed, viewer full-screen cho stories người khác, và viewer cho stories của bản thân (với chức năng quản lý).

## Danh sách file

| File | Vai trò |
|------|---------|
| `StoriesBarView.swift` | Thanh stories ngang (horizontal scroll) ở đầu feed, tự đồng bộ viền gradient/xám qua `.didUpdateStoryViewed` |
| `StoryViewerView.swift` | Full-screen dynamic viewer tự thích ứng Header/BottomBar theo quyền sở hữu story hiện tại |
| `StoryViewerViewModel.swift` | ViewModel quản lý navigation, progress, pause/resume, đánh dấu đã xem, xóa story |
| `MyStoryView.swift` | Wrapper delegating sang `StoryViewerView` cho story của bản thân |
| `StoryVideoPlayer.swift` | Video player chuyên dụng cho story items (progress tracking, no loop) |

## Tính năng chính

### StoriesBarView
- **Horizontal scroll**: LazyHStack các story circles
- **"Your Story" button**: avatar current user + plus badge
  - Có story → tap mở `MyStoryView`, long press context menu mở "Add to Story" hoặc "View Story"
  - Chưa có story → mở `StoryCameraView`
- **Story circles** (StoryCircleView): avatar với gradient ring (red→orange→yellow) cho unviewed, gray ring cho viewed (`Color(.systemGray4)`)
- **Username** dưới mỗi circle
- **Filter**: ẩn current user khỏi danh sách (hiển thị riêng ở "Your Story")
- **Event sync**: 
  - Tự động reload danh sách story khi nhận sự kiện `Notification.Name.didCreateStory`
  - Tự động cập nhật `isViewed = true` và đổi viền sang xám ngay lập tức khi nhận sự kiện `Notification.Name.didUpdateStoryViewed`

### StoryViewerView (Viewer Động Hóa Toàn Diện)
- **Tự thích ứng theo quyền sở hữu (`isCurrentStoryMine`)**:
  - **Khi xem story của chính mình**:
    - Header: Avatar + "Tin của bạn" (`L10n.Story.yourStory`) + relative time + Nút Camera chụp story mới + Nút Close
    - Bottom Bar: `myStoryBottomBar` (Người xem, Bạn thân, Nút Xóa story kèm confirmationDialog, Tùy chọn)
  - **Khi chuyển tiếp sang story của bạn bè**:
    - Header: Avatar đối phương (tap để xem Profile) + Username đối phương (tap để xem Profile) + relative time + Nút Close
    - Bottom Bar: `replyBar` (TextField "Send message" + Thả tim + Chia sẻ)
- **Đánh dấu đã xem (`markViewed`)**:
  - Tự động gọi `markCurrentStoryViewedIfNeeded()` khi hiển thị story mới.
  - Cập nhật tức thì $O(1)$ trên RAM và phát sự kiện `didUpdateStoryViewed`.
  - Bắn tác vụ background `Task` gọi `MarkStoryViewedUseCase` đẩy lên backend Firestore.
- **Progress bars**: HStack capsules ở trên cùng, fill theo progress
- **Tap navigation**: tap trái (50%) = previous, tap phải (50%) = next (cân bằng 50/50 mỗi bên)
- **Swipe down to dismiss**: vuốt xuống tương tác thời gian thực để đóng (co nhỏ card, tăng bo góc, nền đen mờ dần để lộ màn hình phía dưới; tự động pause khi kéo và resume khi thả nảy về)
- **Long press**: pause/resume playback
- **Image stories**: timer-based progress (default 5s/item, tick 0.05s)
- **Video stories**: progress từ `StoryVideoPlayer` callback
- **Stickers**: location, mention, music, poll (overlay trên content)
- **Multi-story navigation**: tự chuyển sang story của user tiếp theo mượt mà
- **Scene phase handling**: pause khi app vào background
- **Content card**: rounded corners động (12pt → 32pt khi kéo)
- **Auto-dismiss**: khi hết story cuối cùng

### MyStoryView
- Kế thừa và delegate toàn bộ sang `StoryViewerView` để tái sử dụng 100% logic điều hướng, cử chỉ, và chuyển đổi giao diện mượt mà khi người dùng xem hết story của mình và chuyển tiếp sang story của người khác.

### StoryViewerViewModel
- **Navigation**: `goToNext()`, `goToPrevious()`, `jumpToStory(at:)`
- **Progress tracking**: `itemProgress` (0.0 → 1.0)
- **Pause/Resume**: `isPaused` flag
- **Multi-story**: `currentStoryIndex` + `currentItemIndex`
- **Load stories**: fetch từ API, sắp xếp `myStories + otherStories` chuẩn Single Source of Truth, jump đến `targetUserId` nếu specified
- **Viewed Tracking**: `markCurrentStoryViewedIfNeeded()` với `MarkStoryViewedUseCaseProtocol`
- **Delete Story**: `deleteCurrentStory()` với `DeleteStoryUseCaseProtocol` và phát `.didCreateStory` reload Feed

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
