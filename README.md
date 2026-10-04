# AQPConnect (mobile)

Ứng dụng Flutter để xem và quản lý camera của hệ thống **AQ Vision / RapidMedia** (backend: `html5stream` MediaServer + web dashboard Next.js).

- Tên hiển thị: **AQPC**, file APK: `AQPConnect-<version>-release-<abi>.apk`
- Phiên bản hiện tại: xem `version:` trong [`pubspec.yaml`](pubspec.yaml) (ví dụ `1.1.6+18`)
- Nền tảng chính: **Android**. iOS và Web có build được nhưng ít được kiểm thử.

## Tính năng chính

| Nhóm | Mô tả |
| ---- | ----- |
| Xem trực tiếp | Lưới camera chạy HLS (`video_player`); màn chi tiết có công tắc **WebRTC / HLS** (`flutter_webrtc`), chỉ chạy giao thức đang chọn |
| Ghi hình | Danh sách bản ghi, timeline và phát lại (xem [`docs/MOBILE_RECORDING_API.md`](docs/MOBILE_RECORDING_API.md)) |
| Thiết bị / Gateway | Quản lý gateway, đẩy luồng camera lên Media Server, mở trang bảo trì của gateway (WebView) |
| Cài đặt thiết bị | Quét QR, cấp WiFi qua BLE theo chuẩn **Improv WiFi**, cài qua hotspot (`wifi_iot`), tìm gateway trong LAN |
| Thông báo | Push qua Firebase Cloud Messaging + `flutter_local_notifications` |
| Khác | Tin tức, thời tiết, thống kê (`fl_chart`), gói dịch vụ / lưu trữ cloud, thư viện ảnh chụp, nhật ký phiên bản, giao diện sáng/tối, tiếng Việt / tiếng Anh |

Màn chính có 4 tab: **Trang chủ · Camera · Thiết bị · Cài đặt** (`lib/screens/home/home_shell.dart`).

## Hướng dẫn sử dụng

### 1. Đăng nhập và chọn máy chủ

Màn đăng nhập (`screens/auth/login_screen.dart`):

1. Ở mục **MÁY CHỦ KẾT NỐI**, chọn:
   - **Cloud (dev1)**: mặc định, kết nối `dev1.aqvision.net`. Nếu domain chính không phản hồi, app tự chuyển sang domain dự phòng `media.aqptech.cloud`.
   - **Local Server**: dùng khi server nằm trong mạng LAN. Chọn giao thức `http`/`https`, nhập IP và Port (1–65535), rồi bấm **Kiểm tra** để thử kết nối trước khi đăng nhập.
2. Nhập **Email hoặc tên đăng nhập** và **Mật khẩu** (ít nhất 4 ký tự). Tick **Ghi nhớ** để lần sau không phải đăng nhập lại.
3. Bấm **Đăng nhập**.

Máy chủ đang dùng hiển thị ở **Cài đặt → Hệ thống → Máy chủ kết nối**. Muốn đổi máy chủ thì đăng xuất rồi chọn lại ở màn đăng nhập.

### 2. Tab Trang chủ

- **Header**: ngày, giờ, thời tiết theo vị trí hiện tại (cần bật định vị). Có nút **Thông báo** (chuông) và **Tin tức**.
- **Chọn gateway**: bấm tên gateway ở đầu trang để lọc camera theo từng gateway, hoặc chọn **Tất cả** để xem camera của mọi nơi.
- **Nhóm camera**: camera được chia theo nhóm (phòng). Bấm **Thêm nhóm camera** để tạo nhóm mới (VD: *Phòng ngủ*). Bấm nút **…** cạnh tên nhóm để:
  - **Thêm camera có sẵn** vào nhóm (chọn nhiều camera cùng lúc).
  - **Đổi tên nhóm**, **Xoá nhóm**. Xoá nhóm không xoá camera, camera chỉ chuyển về *Chưa phân nhóm*.
  - **Xoá khỏi nhóm** cho từng camera.
- **Ẩn camera**: bấm nút **…** trên ô camera và chọn **Ẩn khỏi trang chủ** (có nút **Hoàn tác**). Camera đã ẩn được gom vào mục **Camera đã ẩn (n)**, có thể **Hiện lại** từng cái hoặc **Hiện tất cả**. Danh sách ẩn chỉ lưu trên điện thoại.
- Bấm vào một camera để mở **màn chi tiết camera** (mục 4).

### 3. Tab Camera

- Lưới toàn bộ camera, xem trực tiếp bằng HLS. Lọc theo **Danh sách phòng** (nhóm) hoặc **Tất cả**.
- Nút **+** (**Thêm thiết bị mới**) có các lựa chọn:
  - **Quét mã QR để cài đặt Gateway Eyerus**: xem mục 6.
  - **Quét camera**: tìm và thêm camera qua gateway trong mạng (mục 7).
  - **Thêm camera** thủ công: nhập **Nguồn RTSP / URL**, **Tên luồng (Stream ID)**, **Nhóm / phòng** (có thể **+ Tạo nhóm mới**), **Vị trí lắp đặt**, **Link Google Maps** (phải bắt đầu bằng `https://`) và bật/tắt **Ghi hình (MP4)**.

### 4. Chi tiết camera

- **Xem trực tiếp**: mặc định chạy **WebRTC** (độ trễ thấp nhất). Dùng công tắc **WebRTC | HLS** để đổi giao thức; app chỉ chạy giao thức đang chọn nên không tốn băng thông gấp đôi. Nếu WebRTC không kết nối được (NAT, tường lửa, chặn UDP), app tự chuyển sang HLS cho tới khi đóng màn hình. Khi lỗi có nút **Thử lại**.
- **Toàn màn hình**: bấm biểu tượng phóng to để xem ngang.
- **Chụp ảnh**: lưu ảnh khung hình hiện tại vào **Thư viện ảnh** của app. Không chụp được khi camera offline.
- **Ghi hình**: bắt đầu hoặc dừng ghi thủ công. Nếu camera đang bật *tự động ghi hình*, phải tắt nó trước khi ghi thủ công.
- **Xem bản ghi / Lịch sử ghi hình**: mở danh sách bản ghi (mục 5).
- **Thông tin thiết bị**: trạng thái online/offline, loại camera, nhóm, **Vị trí lắp đặt**. Nếu camera có link bản đồ thì bấm **Xem trên bản đồ**; nếu chưa có thì bấm **Thêm vị trí**.
- **Lịch sử hoạt động**: các sự kiện gần đây của camera.
- **Sửa thông tin**: đổi tên, nguồn, nhóm, vị trí, bật/tắt ghi hình.
- **Xoá camera**: cần xác nhận, không hoàn tác được.

### 5. Bản ghi và phát lại

Màn **Bản ghi** (`screens/home/record_list_screen.dart`):

- Chọn nguồn **Cloud** hoặc **Thẻ nhớ**. Hiện chỉ Cloud có dữ liệu; tab Thẻ nhớ mới có giao diện.
- Chọn **ngày** bằng lịch, rồi chọn đoạn trên **timeline** theo giờ để phát.
- Trong lúc phát:
  - **Tốc độ phát**: 1.0x, 1.5x hoặc 2.0x.
  - **Toàn màn hình**: tự xoay ngang.
  - **Chụp ảnh** từ video, ảnh được lưu vào Photos.
  - **Tải video** về thư mục Download của máy.
  - **Cắt đoạn video**: chọn khoảng thời gian, server cắt rồi trả về link đoạn clip.
- **Xóa bản ghi**: cần xác nhận, không hoàn tác được.
- Bật hoặc tắt **Tự động ghi hình** cho camera ngay trên màn này. Khi chưa có bản ghi, app gợi ý bật tự động ghi hình hoặc nhấn **Ghi hình**.

### 6. Cài đặt Gateway mới

Mở **Quét mã QR Gateway** (từ tab Camera hoặc Thiết bị → **Thêm Gateway**), rồi đưa mã QR trên thiết bị vào khung. Không quét được QR thì chọn **Tìm Gateway qua Bluetooth**.

**Cách A: qua Bluetooth (Improv WiFi, khuyên dùng)**

1. Để điện thoại gần gateway. App tự tìm và kết nối Bluetooth.
2. Gateway quét các WiFi xung quanh (5–30 giây). **Chọn từ danh sách** hoặc **Nhập tên WiFi thủ công (mạng ẩn)**, sau đó nhập **Mật khẩu WiFi** (ít nhất 8 ký tự).
3. Nếu gateway đang có mạng, nó sẽ yêu cầu xác nhận: **nhấn nhanh nút trên gateway** và app tự gửi lại cấu hình.
4. Khi gateway vào được WiFi, app báo **Thiết lập thành công!** và tự thêm gateway vào danh sách. Muốn quản lý gateway qua LAN thì điện thoại phải ở cùng WiFi đó.

**Cách B: qua WiFi dự phòng (hotspot)**

Dùng khi Bluetooth không được (chọn **Dùng WiFi dự phòng (Eyerus-Setup)**):

1. **Bước 1**: vào WiFi cài đặt của gateway (`Eyerus-Setup…`). Bấm **Bấm để tự kết nối**, hoặc tự vào trong Cài đặt WiFi rồi chọn **Tôi đã vào WiFi này, tiếp tục**. App tìm gateway ở `10.42.0.1`.
2. **Bước 2**: chọn WiFi nhà cho gateway và nhập mật khẩu.
3. Điện thoại tự quay lại WiFi nhà, tìm gateway và thêm vào app.

### 7. Quét và thêm camera qua Gateway

Màn **Quét camera** (`screens/setup/camera_scan_screen.dart`):

1. Bấm **Quét camera trong mạng**. Gateway dò camera bằng ONVIF.
2. Với mỗi camera tìm thấy, nhập **Tài khoản camera** và mật khẩu, đặt **Mount** (VD `cam1`, chỉ dùng `A-Z a-z 0-9 _ -`), chọn **Kèm âm thanh** (tắt để giảm trễ) và **Bật camera**.
3. Không dò được thì **Thêm thủ công**: nhập địa chỉ IP camera và cổng ONVIF (Tapo dùng `2020`).
4. Bấm **Lưu & áp dụng (n camera)**. Gateway áp dụng cấu hình và camera được thêm vào app.

### 8. Tab Thiết bị: quản lý Gateway

**Quản lý thiết bị** (`screens/devices/device_management_screen.dart`):

- Danh sách gateway đã thêm, hiển thị trạng thái **Đang online** hay **Đang dùng**.
- **Thêm Gateway**: bằng **Quét mã QR**, hoặc **Kết nối gateway qua IP** (VD `192.168.1.189`).
- **Xoá gateway**: chỉ xoá khỏi điện thoại này; muốn dùng lại phải thêm lại.
- **Bảo trì Gateway**: mở web quản trị của gateway trong app (nhập IP, port mặc định hoặc kèm port, VD `192.168.1.189:8080`).

**Chi tiết gateway** (`gateway_detail_screen.dart`):

- **Đổi tên Gateway**.
- **Phần cứng / Tài nguyên hệ thống**: vi xử lý, số lõi/luồng, tải từng lõi CPU, bộ nhớ, nhiệt độ chip, bo mạch, hệ điều hành, phiên bản API, thời gian hoạt động.
- **Mạng**: tín hiệu WiFi, cổng HTTP, cổng RTSP.
- **Môi trường**: nhiệt độ, độ ẩm, chất lượng không khí (TVOC, mức Tốt → Nguy hại) nếu gateway có cảm biến.
- **Luồng camera**: trạng thái từng camera (đang phát, đang đẩy).
- Lối tắt tới **Quản lý đẩy luồng**, **Điều khiển gateway** và **Bảo trì nâng cao** (web quản trị: RTSP, đẩy luồng, MQTT, Webhook, nhật ký).

**Đẩy luồng** (`stream_push_screen.dart`):

- **Tự động đẩy lên media server**: bật/tắt cho từng camera, kèm trạng thái *Đang đẩy / Đang khởi động / Đang thử lại / Lỗi / Server từ chối (sai URL/khoá)*. Tổng quan dạng `{đang chạy}/{tổng} camera đang đẩy`.
- **Đích khác (tuỳ chọn)**: **Thêm URL** để đẩy một camera sang server khác (VD YouTube). URL phải bắt đầu bằng `rtsp://`, `rtsps://`, `rtmp://`, `rtmps://` hoặc `srt://`. Có thể tạm dừng hoặc xoá từng đích.
- **Thêm camera vào app** từ các luồng của gateway.
- Muốn thay đổi cấu hình cần tài khoản admin của gateway. Nếu dịch vụ `eyerus-push` trên gateway chưa chạy thì app sẽ báo.

**Điều khiển gateway** (`gateway_control_screen.dart`):

- **Dịch vụ RTSP**: xem trạng thái, **Khởi động lại** (luồng gián đoạn 5–15 giây), **Tắt dịch vụ** / **Bật dịch vụ**.
- **Kiểm tra camera**: **Ping** từng camera đã lưu.
- **WiFi & Bluetooth**: xem mạng hiện tại (IP, % sóng), **Ngắt WiFi**, **Quên mạng**, cho phép cài lại WiFi qua BLE (cần nhấn nút trên gateway).
- **Cụm (cluster)**: mã gateway, tên cụm, định danh, khu vực, broker MQTT (**Thử kết nối**), **Gửi ngay** telemetry.
- **Nhật ký gateway**: 100 dòng gần nhất.

### 9. Tab Cài đặt

| Mục | Chức năng |
| --- | --------- |
| **Người dùng** | Mở **Thông tin tài khoản**: thông tin cá nhân và doanh nghiệp (tên doanh nghiệp, mã số thuế, giấy chứng nhận ĐKKD, trụ sở, hotline, email liên hệ). Có **Chỉnh sửa thông tin**, **Đổi mật khẩu** (mật khẩu hiện tại, mật khẩu mới, xác nhận) và **Đăng xuất** |
| **Gói dịch vụ** | Gói hiện tại, chu kỳ thanh toán (tháng/năm), dung lượng lưu trữ, thời hạn lưu bản ghi, ngày bắt đầu. **Nâng cấp gói dịch vụ** gửi yêu cầu (kèm lời nhắn) để quản trị viên duyệt |
| **Dung lượng Cloud** | Mức sử dụng (Bình thường → Sắp đầy → Gần đầy → Đã đầy/Nguy cấp) và camera chiếm nhiều dung lượng nhất |
| **Thư viện ảnh** | Ảnh đã chụp từ camera: xem, chia sẻ, xoá |
| **Ngoại hình / Ngôn ngữ** | Giao diện **Sáng / Tối**; ngôn ngữ **Tiếng Việt / English** |
| **Nhật ký** | Lịch sử phiên bản app (đọc từ `assets/release_notes.json` và API `/app-releases`) |
| **Máy chủ kết nối** | Hiển thị server đang dùng (cloud hoặc local) |
| **Đăng xuất** | Cần xác nhận, sau đó phải đăng nhập lại |

### 10. Thông báo và tin tức

- **Thông báo** (biểu tượng chuông): cảnh báo *camera mất kết nối*, *phát hiện chuyển động*, *cập nhật hệ thống*. Bấm vào một thông báo để **Đánh dấu đã đọc**. Push được gửi qua Firebase kể cả khi app đang tắt; Android 13+ sẽ hỏi quyền thông báo lần đầu.
- **Tin tức**: danh sách bài viết mới nhất, bấm vào để đọc chi tiết (có lượt xem).

### Chức năng chưa hoàn thiện

Các mục dưới đây đã có giao diện nhưng chưa có logic phía sau:

- Cài đặt → **Tự động cập nhật**, **Phương pháp giải mã**: bấm vào chưa có tác dụng.
- Cài đặt → **Phát lại tự động**, **Phát bằng mạng di động**: công tắc không được lưu lại và chưa ảnh hưởng tới việc phát.
- Bản ghi → tab **Thẻ nhớ**: chưa đọc bản ghi từ thẻ nhớ.

## Yêu cầu

- **Flutter 3.29.3**, đã ghim trong [`.fvmrc`](.fvmrc). Nên dùng [FVM](https://fvm.app): `fvm install && fvm flutter ...`
- Dart SDK `>=3.5.0 <4.0.0`
- Android: JDK 17, Android SDK `compileSdk 36`, NDK `27.0.12077973`
- iOS: Xcode + CocoaPods (cần thêm `GoogleService-Info.plist` cho Firebase)

## Bắt đầu nhanh

```bash
fvm install            # cài đúng bản Flutter theo .fvmrc
fvm flutter pub get
fvm flutter run        # chạy trên máy ảo / thiết bị đang kết nối
```

Chạy bản web để debug giao diện:

```bash
fvm flutter run -d chrome
```

Trên web, nếu đang ở `localhost` thì app gọi API qua `http://localhost:3002` (BFF Next.js của `html5stream/web`).

## Cấu hình máy chủ

Mọi host, port và tiền tố đường dẫn nằm trong [`lib/config/api_defaults.dart`](lib/config/api_defaults.dart). Đừng hardcode URL ở store hay screen mà hãy sửa ở file này.

| Hằng số | Giá trị | Dùng cho |
| ------- | ------- | -------- |
| `productionHost` | `dev1.aqvision.net` | Cloud server chính |
| `backupHost` | `media.aqptech.cloud` | Domain dự phòng, tự chuyển sang khi domain chính không phản hồi |
| `localApiPort` | `3002` | Debug trên web |
| `apiPath` / `apiV1Path` | `/api`, `/api/v1` | REST (groups, rapidmedia, alerts…) / auth, stats, devices |
| `mediaPathSegment` | `media` | HLS và bản ghi: `<origin>/api/media` |
| `mediaIngestHost` | `14.161.6.65` | Host nhận luồng khi gateway đẩy stream |

[`lib/config/api_config.dart`](lib/config/api_config.dart) tạo các base URL từ những giá trị trên. Người dùng cũng có thể chọn **Local Server** (http/https + IP + port trong LAN) ngay tại màn đăng nhập. Lựa chọn này được lưu trong `SharedPreferences`, sau đó toàn bộ API, media và địa chỉ ingest đều chuyển sang máy chủ local.

## Cấu trúc thư mục

```
lib/
├── main.dart          # Khởi tạo Firebase, ApiConfig, AuthStore, theme → RapidMediaApp
├── config/            # ApiDefaults (hằng số) + ApiConfig (tạo URL, chọn cloud/local/backup)
├── core/              # Giao tiếp gateway: BLE Improv, LAN finder, session, telemetry, đồng bộ camera cloud
├── data/              # Store dạng ChangeNotifier (auth, camera, recording, gateway, notification…) + models
├── screens/
│   ├── auth/          # Đăng nhập
│   ├── home/          # HomeShell, các tab, chi tiết camera, bản ghi, nhóm, gói dịch vụ
│   ├── devices/       # Quản lý / điều khiển gateway, đẩy luồng, trang bảo trì
│   └── setup/         # Quét QR / BLE / camera, cài đặt gateway và hotspot
├── widgets/           # UI dùng chung, webrtc_player, camera_navigation, sheet và dialog
├── theme/             # AppColors
└── utils/             # Chuỗi đa ngôn ngữ (.tr), xử lý lỗi mạng, ảnh chụp
assets/
├── release_notes.json # Nhật ký phiên bản hiển thị trong app (vi/en)
├── images/            # Ảnh được đóng gói vào app
└── icon/              # Chỉ dùng để sinh launcher icon / splash, không đóng gói vào app
docs/                  # Ghi chú kiến trúc, hiệu năng, API recording
test/                  # Unit / widget test
tool/                  # Script chụp ảnh UI để review thiết kế
```

State được quản lý bằng `ChangeNotifier` + `ListenableBuilder`, không dùng thư viện state management bên ngoài. Các store thường là singleton (`XxxStore.instance`). Xem thêm phần đánh giá hiệu năng trong [`docs/MOBILE_PERF_STATE_EVAL.md`](docs/MOBILE_PERF_STATE_EVAL.md).

## Kiểm thử

```bash
fvm flutter analyze
fvm flutter test
```

Chụp ảnh các màn hình ra PNG (390×844 @3x) mà không cần thiết bị:

```bash
fvm flutter test tool/ui_screenshots_test.dart   # ảnh nằm ở build/ui_shots/
```

## Build & phát hành

### Android APK

```bash
fvm flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/AQPConnect-<version>-release-arm64-v8a.apk (và các ABI khác)
```

Tên file APK được đặt trong `android/app/build.gradle.kts` (`applicationVariants`).

### Quy trình ra bản mới

1. Tăng `version:` trong `pubspec.yaml`, cả version name lẫn build number (ví dụ `1.1.6+18` → `1.1.7+19`).
2. Thêm một mục mới **ở đầu** `assets/release_notes.json`, gồm `version`, `buildNumber`, `releasedAt`, `teaser` và `sections`, viết cả `vi` lẫn `en`.
3. Build APK.
4. Trên server, `build_and_publish.sh` build rồi copy APK sang `html5stream/web/public/app/app-release-v<version>.apk`. Backend nhận ra bản mới và gửi thông báo cập nhật cho người dùng. Trong app, nhật ký phiên bản được lấy từ API `/app-releases`.

### Icon và splash

```bash
fvm dart run flutter_launcher_icons
fvm dart run flutter_native_splash:create
```

Màu nền thương hiệu là `#8E0104`, ảnh gốc nằm trong `assets/icon/`.

## Quyền Android

App xin các quyền: Internet, Camera (quét QR, chụp ảnh), Bluetooth / BLE scan & connect (cài gateway), Location và Nearby WiFi devices (quét BLE/WiFi), đổi trạng thái WiFi/mạng (cài qua hotspot) và Post notifications. Xem đầy đủ trong `android/app/src/main/AndroidManifest.xml`.

## Lưu ý và việc còn tồn đọng

- `applicationId` vẫn là `com.example.mobile`, và bản release đang **ký bằng debug key**. Cần tạo keystore riêng trước khi phát hành chính thức.
- Repo đang commit file **Firebase Admin SDK** (`aq-vision-camera-firebase-adminsdk-*.json`). Đây là khóa phía server, app không cần dùng. Nên gỡ khỏi repo, thu hồi và tạo khóa mới trên Firebase Console.
- Các file APK (`AQPConnect-*.apk`) và các script `patch_*.py` ở thư mục gốc là sản phẩm tạm. Nên chuyển ra ngoài repo hoặc thêm vào `.gitignore`.
- Trên dev, `ApiConfig.mediaBase` ép HTTP cho domain `dev1` để ExoPlayer chấp nhận chứng chỉ tự ký.
