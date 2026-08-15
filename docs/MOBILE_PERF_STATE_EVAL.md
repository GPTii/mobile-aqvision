# Đánh giá & cải thiện kiến trúc Mobile (Flutter)

Tài liệu này ghi lại đánh giá code cũ, các vấn đề hiệu năng / bảo trì, và những thay đổi đã áp dụng trên nhánh hiện tại (`feature/recording-mobile`, commit liên quan: centralize API config + state/video performance).

Phạm vi: cấu hình API, quản lý state (`ChangeNotifier`), vòng đời tab, HLS video preload.

---

## 1. Tóm tắt

| Hạng mục | Code cũ | Code mới |
| -------- | ------- | -------- |
| Base URL API | Hardcode lặp nhiều store/screen | `ApiDefaults` + `ApiConfig` |
| SSE / status online | `notifyListeners()` → rebuild cả trang + video | Per-camera / `statusEpoch` — chỉ badge/status |
| Tab Home/Camera/Report | Đổi tab dispose toàn bộ player | `IndexedStack` + pause theo tab |
| Mở camera detail | Cold start HLS + delay ~400ms | Reuse controller đã warm từ cache |
| Recording UI | Notify toàn `RecordingStore` | `listenableFor(cameraId)` |

**Kết luận ngắn:** UX đã mượt hơn về rebuild / chuyển tab / mở detail. Bottleneck còn lại chủ yếu là **số HLS decoder chạy đồng thời** (CPU/RAM), không còn là “refresh cả trang vì `notifyListeners`”.

---

## 2. Vấn đề của code cũ

### 2.1. Hardcode URL API

URL dạng `https://api.aqvision.net` (và logic localhost `:3002`) bị **copy-paste** trong nhiều file:

- `lib/data/auth_store.dart`
- `lib/data/camera_store.dart`
- `lib/data/recording_store.dart`
- `lib/data/stats_store.dart`
- `lib/data/notification_store.dart`
- `lib/data/storage_store.dart`
- `lib/screens/home/add_camera_screen.dart`

**Hệ quả**

- Đổi host/port phải sửa nhiều chỗ → dễ sót, lệch môi trường.
- Logic web localhost khác nhau nhẹ giữa các file (có/không check port) → hành vi không thống nhất.

### 2.2. State quá rộng — “refresh cả trang”

Pattern phổ biến:

```dart
return ListenableBuilder(
  listenable: CameraStore.instance,
  builder: (context, _) {
    return Scaffold( /* toàn bộ header + list + video */ );
  },
);
```

Xuất hiện ở Home / Camera / Report / Detail.

**Hệ quả**

- Mọi `notifyListeners()` (kể cả đổi 1 camera online) rebuild **Scaffold + grid + VideoPlayer**.
- SSE realtime gọi `notifyListeners()` từng event → giật liên tục khi nhiều camera đổi status.
- `RecordingStore` notify global khi 1 camera start/stop record → màn hình khác cũng rebuild.
- `record_list_screen` gọi trực tiếp `CameraStore.instance.notifyListeners()` sau khi đổi `enableMp4` → lan rộng không cần thiết.

### 2.3. Vòng đời video kém

- Đổi tab bằng `_tabs[_currentIndex]` → **destroy** tab cũ, **re-init** HLS khi quay lại.
- Thumbnail tự tạo `VideoPlayerController`, dispose khi parent rebuild / rời tab.
- Detail chờ `Future.delayed(400ms)` rồi mới `initialize()` → cảm giác lag khi bấm vào camera.
- Offline flip trên detail **đổi widget type** (player ↔ placeholder) → dispose/recreate decoder.

### 2.4. Fetch / loading gây nhấp nháy

- `StatsStore` / `StorageStore` `notifyListeners()` cả lúc bắt đầu loading dù đã có data → chart/section nháy.
- `deleteGroup` notify rồi `fetchCameras` notify lại → double rebuild.

---

## 3. Cải thiện đã áp dụng

### 3.1. Tập trung cấu hình API

| File | Vai trò |
| ---- | ------- |
| `lib/config/api_defaults.dart` | Chỉ hằng số: host, scheme, port, path |
| `lib/config/api_config.dart` | Ghép `origin`, `apiBase`, `apiV1Base`, `mediaBase`, `webOrigin` |

Stores/screens dùng `ApiConfig.*`, không còn hardcode host production trong business code.

**Cách chỉnh môi trường:** sửa `ApiDefaults.productionHost` / `localApiPort` (và path nếu cần).

### 3.2. Notify có chọn lọc

**Hạ tầng mới**

- `lib/data/debounced_notifier.dart` — `DebouncedNotify`, `IdListenables`
- `CameraStore`
  - `notifyNow()` cho thay đổi cấu trúc list (fetch/add/delete)
  - `statusEpoch` + `cameraListenable(id)` cho online / recording flag (SSE, toggle)
  - `setRecordingFlag()` thay cho poke `notifyListeners()` từ màn khác
- `RecordingStore.listenableFor(cameraId)` — UI record chỉ rebuild theo camera đó

**UI**

- Header / chrome nằm **ngoài** listener cấu trúc.
- Badge LIVE/REC lắng nghe per-camera.
- Report: từng block (status / charts / storage) listen riêng, không wrap cả trang bằng `CameraStore`.

### 3.3. Tab giữ sống + cổng phát video

- `HomeShell` dùng `IndexedStack`.
- `AppState.homeTabIndex` + `videoAllowedForTab(tab)` — chỉ tab đang chọn được play thumbnail; tab ẩn pause/detach surface.

### 3.4. Preload HLS — mở detail gần tức thì

| File | Vai trò |
| ---- | ------- |
| `lib/data/video_preload_cache.dart` | Cache tối đa N controller đã `initialize` (muted) |
| `lib/widgets/camera_navigation.dart` | `openCameraDetail` — pin stream, dispose unpinned, navigate |

Luồng:

1. Sau `fetchCameras` → warm một số camera online.
2. Thumbnail grid **dùng chung** cache (không tự dispose controller của cache).
3. Mở detail → `acquire` controller đã warm → play ngay (bỏ delay 400ms khi có cache).
4. Quay lại grid → `release` + gắn lại thumbnail.

Fullscreen: parent **detach surface** (`_obscured`) thay vì dispose, tránh hai `VideoPlayer` tranh một controller.

### 3.5. Ổn định player trên detail

- Offline chỉ **overlay**, không hủy player khi đã có `hlsUrl`.
- `ValueKey` theo camera/url; `didUpdateWidget` chỉ khi URL đổi.

### 3.6. Loading đỡ nhấp nháy

- Stats/Storage: chỉ notify loading khi chưa có data; luôn notify khi có kết quả.

---

## 4. Sơ đồ trước / sau (state + video)

### Trước

```
SSE status flip
  → CameraStore.notifyListeners()
  → Home/Camera/Report/Detail ListenableBuilder (full Scaffold)
  → Rebuild VideoPlayer widgets
  → Jank / drop frames
```

```
Tap camera
  → isVideoGridActive=false → dispose ALL grid controllers
  → Detail delay 400ms → new VideoPlayerController.initialize()
  → Cold start HLS (chậm)
```

### Sau

```
SSE status flip
  → camera.online = …
  → cameraListenable(id) + statusEpoch
  → Chỉ badge / counter listen status rebuild
  → Grid video giữ nguyên controller
```

```
Tap camera
  → pin(cameraId) + disposeUnpinned()
  → Detail acquire(warm controller)
  → Play ngay (nếu đã warm)
```

---

## 5. Hiệu năng — đánh giá thực tế

### Đã cải thiện rõ

| Kịch bản | Trước | Sau |
| -------- | ----- | --- |
| SSE đổi online/offline | Giật grid | Nhẹ |
| Đổi tab | Re-init HLS | Giữ state, pause |
| Mở camera đã LIVE trên grid | Chờ init | Gần tức thì |
| Report khi SSE chạy | Rebuild cả scroll | Block status cập nhật cục bộ |

### Bottleneck còn lại

1. **Số decoder HLS đồng thời** — `VideoPreloadCache.maxWarm` (hiện 6) + warm song song vẫn tốn RAM/CPU trên máy yếu.
2. Thumbnail off-screen vẫn có thể warm nếu nằm trong cây widget (chưa có “chỉ play khi visible”).
3. Logout chưa gọi `VideoPreloadCache.clear()` — nên clear khi hết session.
4. Token trên query HLS (`access_token`) — rủi ro lộ URL; thuộc backlog bảo mật (cần backend Cookie/header).

Chi tiết đề xuất xử lý → **§7**.

---

## 6. File chạm tới (checklist)

**Mới**

- `lib/config/api_defaults.dart`
- `lib/config/api_config.dart`
- `lib/data/debounced_notifier.dart`
- `lib/data/video_preload_cache.dart`
- `lib/widgets/camera_navigation.dart`

**Cập nhật chính**

- Stores: `camera_store`, `recording_store`, `auth_store`, `stats_store`, `storage_store`, `notification_store`, `app_state`
- UI: `home_shell`, `home_tab`, `camera_tab`, `report_tab`, `camera_detail_screen`, `record_list_screen`, `add_camera_screen`

---

## 7. Đề xuất cải thiện tiếp theo

> **Có cần làm thêm không?** Có. Đợt vừa rồi xử lý “rebuild / cold start detail”. Phần còn lại chủ yếu là **ổn định máy yếu**, **session an toàn**, và **dọn nợ kỹ thuật**.  
> Làm theo ROI: **P0 trước** (ít file, hiệu quả cao).

### 7.1. Bảng ưu tiên

| ID | Ưu tiên | Việc | Effort | Impact | Status |
| -- | ------- | ---- | ------ | ------ | ------ |
| P0-1 | P0 | Warm HLS có hàng đợi (max 2–3 concurrent) | S | Giảm spike CPU/RAM lúc vào Home | Todo |
| P0-2 | P0 | `clear()` preload khi `logout` / token hết hạn | XS | Tránh giữ decoder + URL token cũ | Todo |
| P0-3 | P0 | Root app lắng nghe `AuthStore` | S | Logout giữa chừng → Login | Todo |
| P1-1 | P1 | Chỉ play thumbnail khi visible (viewport) | M | Ổn định scroll / nhiều camera | Todo |
| P1-2 | P1 | Gộp `_VideoThumbnail` thành widget chung | S | Một chỗ sửa preload/lifecycle | Todo |
| P1-3 | P1 | Retry UX fetch camera / video lỗi | S | Người dùng tự phục hồi được | Todo |
| P1-4 | P1 | `renameGroup` gọi API thật | S | Tên nhóm không mất sau refresh | Todo |
| P1-5 | P1 | Thu hẹp `NotificationStore` notify | S | Bell/list nhẹ hơn | Todo |
| P2-1 | P2 | “Remember me” thực sự persist | XS | Đúng UX đã hiện trên login | Todo |
| P2-2 | P2 | Xóa / gộp dead code (`add_camera_screen`, `ComingSoonView`) | XS | Giảm drift | Todo |
| P2-3 | P2 | Test store + preload + auth root | M | Chặn regression hiệu năng | Todo |
| P2-4 | P2 | Media URL không gắn token trên query | L | Bảo mật (cần backend) | Todo |

---

### 7.2. Chi tiết từng đề xuất

#### P0-1 — Warm HLS có hàng đợi

**Vấn đề:** `warmMany` dùng `Future.wait` tới `maxWarm = 6` → 6 decoder init cùng lúc.

**Đề xuất**

- Thêm semaphore / queue trong `VideoPreloadCache` (`maxConcurrentWarm = 2` hoặc `3`).
- Có thể hạ `maxWarm` xuống `4` trên thiết bị yếu.
- Ưu tiên warm camera đang visible / vừa được tap hơn là “6 cái đầu list”.

**File:** `lib/data/video_preload_cache.dart`, `lib/data/camera_store.dart`

#### P0-2 — Clear preload khi logout

**Vấn đề:** `VideoPreloadCache.clear()` đã có nhưng không ai gọi → sau logout vẫn có thể giữ HLS + URL có token.

**Đề xuất:** gọi `VideoPreloadCache.instance.clear()` trong `AuthStore.logout()` (và khi `fetchProfile` fail → logout).

**File:** `lib/data/auth_store.dart`

#### P0-3 — Auth reactive ở root

**Vấn đề:** `main.dart` chọn `HomeShell` / `LoginScreen` một lần lúc `runApp`. Logout / hết hạn token giữa session dễ không về login sạch.

**Đề xuất**

- Bọc `home:` bằng `ListenableBuilder(listenable: AuthStore.instance, …)`.
- `!isLoggedIn` → `LoginScreen`; logged in → `HomeShell`.
- Profile chỉ cần `AuthStore.logout()` nếu root đã reactive.

**File:** `lib/main.dart`, `lib/screens/home/tabs/profile_tab.dart`

#### P1-1 — Play thumbnail theo viewport

**Vấn đề:** Trong tab, nhiều tile vẫn warm dù ngoài màn hình (Home nhiều nhóm).

**Đề xuất**

- `VisibilityDetector` (hoặc tự đo viewport): `visibleFraction > 0.3` → warm/attach; ra ngoài → detach surface (cache giữ theo LRU).
- Kết hợp P0-1: chỉ enqueue warm cho item visible.

**File:** thumbnail widget chung (sau P1-2), `home_tab`, `camera_tab`

#### P1-2 — Widget thumbnail chung

**Vấn đề:** `_VideoThumbnail` gần như copy-paste giữa `home_tab.dart` và `camera_tab.dart`.

**Đề xuất:** `lib/widgets/hls_thumbnail.dart` (`HlsThumbnail`) với `cameraId`, `hlsUrl`, `activeTabIndex`.

#### P1-3 — Retry UX

**Vấn đề:** `fetchCameras` bỏ qua non-200 im lặng; thumbnail lỗi chỉ icon, không tap-retry.

**Đề xuất**

- Store giữ `lastError` / `hasError`.
- Empty/error state: nút “Thử lại”.
- Thumbnail lỗi: tap → `invalidate(id)` + `warm` lại.

**File:** `camera_store.dart`, tabs, thumbnail widget

#### P1-4 — `renameGroup` API thật

**Vấn đề:** `CameraStore.renameGroup` chỉ đổi local → `fetchGroups` ghi đè tên cũ.

**Đề xuất:** `PATCH/PUT /api/groups/{id}` (đối chiếu web); success mới `notifyNow()`; fail → snackbar.

**File:** `lib/data/camera_store.dart` (+ contract BE)

#### P1-5 — NotificationStore hẹp hơn

**Vấn đề:** Mỗi toggle / mark-read / fetch đều `notifyListeners()` → bell + full list rebuild.

**Đề xuất:** `ValueNotifier<int> unreadCount` cho bell; list screen listen store đầy đủ; tránh double notify khi unread không đổi.

**File:** `notification_store.dart`, `notification_bell_button.dart`

#### P2-1 — Remember me

**Vấn đề:** Checkbox `_rememberMe` trên login không ghi `SharedPreferences`.

**Đề xuất:** nếu bật → lưu username (không lưu password); prefill lần sau.

**File:** `login_screen.dart`

#### P2-2 — Dead code

- `lib/screens/home/add_camera_screen.dart` — UI chính dùng `camera_form_sheet.dart`.
- `lib/widgets/coming_soon_view.dart` — không reference.

**Đề xuất:** xóa hoặc `@Deprecated` rõ ràng.

#### P2-3 — Tests

**Vấn đề:** `test/widget_test.dart` lệch product hiện tại.

**Đề xuất tối thiểu:** unit `ApiConfig` origin; smoke auth gate; (tuỳ chọn) preload acquire/release không leak.

#### P2-4 — Token khỏi media URL

**Vấn đề:** HLS `?access_token=…`; MP4 `auth_token` query.

**Đề xuất (cần BE):** auth bằng Cookie/header; `VideoPlayerController` + `httpHeaders`; không `debugPrint` full media URL.

---

### 7.3. Lộ trình gợi ý (PR nhỏ)

| PR | Nội dung | Mục tiêu |
| -- | -------- | -------- |
| **PR-A** | P0-1 + P0-2 + P0-3 | Ổn định máy + session an toàn |
| **PR-B** | P1-2 → P1-1 → P1-3 | Thumbnail gọn + viewport + retry |
| **PR-C** | P1-4 + P1-5 + P2-1 + P2-2 | Đúng nghiệp vụ / dọn code |
| **PR-D** | P2-3 (+ P2-4 khi BE sẵn) | Chất lượng dài hạn |

**Khuyến nghị làm ngay tiếp theo:** **PR-A** — ít rủi ro UI, giảm OOM/jank và lỗ hổng session rõ nhất.

---

## 8. Ghi chú bảo trì

- Đổi API host: chỉ sửa `lib/config/api_defaults.dart`.
- Thêm màn dùng video: gọi `openCameraDetail`, không tự `Navigator` + tạo controller riêng.
- Thêm listener store: ưu tiên listen **nhỏ** (per-id / section), tránh wrap cả `Scaffold`.
- Không gọi `CameraStore.notifyListeners()` từ UI; dùng API store (`setRecordingFlag`, `updateCamera`, …).
- Khi hoàn thành một mục §7: đổi Status trong bảng 7.1 và cập nhật §5 nếu hiệu năng đổi.
