# ReportPost - Báo cáo bài viết

## Mô tả

Module xử lý flow báo cáo (report) một bài post vi phạm. Gồm 2 màn hình: chọn lý do → xác nhận đã gửi.

## Danh sách file

| File | Vai trò |
|------|---------|
| `ReportPostView.swift` | Giao diện chọn lý do report + màn hình xác nhận thành công |

## Tính năng chính

- **10 lý do report** (theo Instagram):
  - It's spam
  - Nudity or sexual activity
  - Hate speech or symbols
  - Violence or dangerous organizations
  - Bullying or harassment
  - False information
  - Scam or fraud
  - Intellectual property violation
  - Suicide or self-injury
  - Something else
- **Icon cho mỗi lý do**: SF Symbol tương ứng
- **Submit flow**: tap lý do → loading overlay → hiển thị success
- **Success screen**: checkmark icon + "Thanks for letting us know" + explanation + Done button
- **Simulated API call**: `Task.sleep(1s)` giả lập network request
- **Navigation**: presented dạng sheet, Cancel để đóng

## Architecture

- Đây là View đơn lẻ, không có ViewModel (logic đơn giản, self-contained)
- Input: `postId: String`
- State: `selectedReason`, `isSubmitted`, `isSubmitting`
- Enum: `ReportReason` (CaseIterable, Identifiable)

## ReportReason Enum

| Case | Icon |
|------|------|
| spam | xmark.circle |
| nudity | eye.slash |
| hateSpeech | exclamationmark.bubble |
| violence | flame |
| bullying | person.2.slash |
| falseInfo | info.circle |
| scam | creditcard.trianglebadge.exclamationmark |
| selfHarm | heart.slash |
| intellectualProperty | doc.badge.ellipsis |
| other | ellipsis.circle |
