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

Chỉ hỗ trợ cài tự động trên **Windows 10/11**. Script `setup.bat` cài toàn bộ những thứ dưới đây, không cần cài tay:

| Thành phần | Phiên bản | Ghi chú |
|---|---|---|
| **Git** | bản mới nhất | cài qua `winget` |
| **Flutter** | **3.29.3** | đã ghim trong [`.fvmrc`](.fvmrc) |
| Dart SDK | `>=3.5.0 <4.0.0` | có sẵn trong Flutter |
| **JDK** | 17 (Eclipse Temurin) | dùng được JDK 17–21 nếu máy đã có |
| **Android SDK** | `compileSdk 36`, build-tools 35 | kèm platform-tools (`adb`) và Google USB driver |
| **NDK** | `27.0.12077973` | |
| Gradle | 8.14 | wrapper tự tải khi build |
| Windows Developer Mode | bật | Flutter cần quyền tạo symlink cho plugin |
| Firebase | `android/app/google-services.json` | đã có sẵn trong repo |

Ngoài ra cần khoảng **6 GB** ổ cứng trống, mạng ổn định và một **điện thoại Android** cùng **cáp USB truyền dữ liệu**.

## Cài đặt sau khi clone

### Bước 1. Clone project

```powershell
git clone <url-repo>
cd mobile
```

### Bước 2. Chạy script cài đặt

Double-click **`setup.bat`**, hoặc chạy trong terminal:

```powershell
.\setup.bat
```

Script lần lượt làm các việc sau (bước nào máy đã có thì bỏ qua):

1. Cài **Git** nếu chưa có.
2. Bật **Developer Mode**. Windows sẽ hiện hộp thoại quyền Admin, hãy chọn **Yes**.
3. Cài **JDK 17** vào `C:\dev\jdk-17` và đặt `JAVA_HOME`.
4. Cài **Flutter 3.29.3** vào `C:\dev\flutter-3.29.3` và thêm vào `PATH`.
5. Cài **Android SDK** vào `C:\dev\android-sdk`, tự chấp nhận license và đặt `ANDROID_HOME`. Nếu máy đã có SDK, ví dụ do Android Studio cài, thì script dùng luôn SDK đó.
6. Chạy `flutter pub get` để tải thư viện của project.
7. Build thử một bản debug để tải sẵn Gradle và thư viện Android.
8. Chạy `flutter doctor` để kiểm tra lại.

Lần đầu mất khoảng **15–30 phút**. Nếu đang chạy mà lỗi mạng, cứ chạy lại `setup.bat`: script chạy lại nhiều lần vẫn an toàn.

Khi chạy xong, màn hình sẽ hiện:

```
======================================================================
 CAI DAT XONG!
 Mo mot cua so terminal MOI (de nhan PATH moi), cd vao project, roi:
     flutter devices     # kiem tra dien thoai da ket noi
     flutter run         # chay app len dien thoai
======================================================================
```

> ⚠️ Cài xong phải **đóng terminal (cả VS Code) và mở lại cửa sổ mới**, nếu không lệnh `flutter` sẽ không nhận.

`flutter doctor` báo thiếu **Android Studio** hoặc **Visual Studio** thì **bỏ qua được**, vì không cần hai thứ đó để chạy và build Android.

Tuỳ chọn của script:

```powershell
.\setup.bat -InstallDir D:\dev   # cài vào thư mục khác (đường dẫn không được có dấu cách)
.\setup.bat -SkipWarmup          # bỏ bước build thử để xong nhanh hơn
```

### Bước 3. Kết nối điện thoại Android

1. Vào **Cài đặt → Thông tin điện thoại**, chạm **7 lần** vào *Số hiệu bản tạo (Build number)* để mở **Tùy chọn nhà phát triển**.
2. Vào **Tùy chọn nhà phát triển** và bật **Gỡ lỗi USB (USB debugging)**.
3. Cắm cáp USB vào máy tính. Khi điện thoại hỏi *"Cho phép gỡ lỗi USB?"*, chọn **Cho phép**.

Kiểm tra máy tính đã nhận điện thoại chưa:

```powershell
flutter devices
```

Kết quả đúng sẽ có tên điện thoại trong danh sách, ví dụ:

```
Found 3 connected devices:
  SM A525F (mobile) • R58R12345AB • android-arm64  • Android 14 (API 34)
  Windows (desktop) • windows     • windows-x64    • Microsoft Windows
  Chrome (web)      • chrome      • web-javascript • Google Chrome
```

### Bước 4. Chạy app lên điện thoại

```powershell
flutter run                  # chạy bản debug, có hot reload
flutter run -d <device_id>   # khi có nhiều thiết bị, device_id là cột thứ 2 của `flutter devices`
flutter run --release        # chạy bản release (nhanh hơn, không hot reload)
```

Khi app đang chạy, gõ vào terminal: `r` để hot reload, `R` để hot restart, `q` để thoát.

Chạy bản web để debug giao diện: `flutter run -d chrome`. Trên web, nếu đang ở `localhost` thì app gọi API qua `http://localhost:3002` (BFF Next.js của `html5stream/web`).

## Build APK

```powershell
flutter build apk --release --split-per-abi
```

File APK nằm ở **`build\app\outputs\apk\release\`**:

| File | Dùng cho |
|---|---|
| `AQPConnect-<version>-release-arm64-v8a.apk` | **hầu hết điện thoại hiện nay, gửi file này** |
| `AQPConnect-<version>-release-armeabi-v7a.apk` | máy 32-bit đời cũ |
| `AQPConnect-<version>-release-x86_64.apk` | máy ảo, máy x86 |

Flutter cũng chép thêm một bản ra `build\app\outputs\flutter-apk\`, với tên mặc định như `app-arm64-v8a-release.apk`.

Muốn **một APK duy nhất** cài được trên mọi máy (dung lượng lớn hơn):

```powershell
flutter build apk --release
# → build\app\outputs\flutter-apk\app-release.apk
```

- `<version>` lấy từ dòng `version:` trong `pubspec.yaml`, hiện là `1.1.6+18`.
- Tên file được đặt trong `android/app/build.gradle.kts` (`applicationVariants`).
- Bản release hiện đang ký bằng **khóa debug**: cài thử được nhưng không đưa lên Google Play được.

## Xử lý lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| `flutter` không nhận lệnh | Chưa mở terminal mới sau khi cài, hãy đóng hết rồi mở lại |
| `flutter devices` không thấy điện thoại | Kiểm tra cáp và USB debugging, rút ra cắm lại rồi chọn *Cho phép*. Chạy `adb devices`: nếu thấy `unauthorized` thì mở khóa điện thoại và xác nhận lại |
| Báo đang dùng Flutter khác 3.29.3 | Máy có sẵn một bản Flutter khác trong PATH hệ thống. Gỡ đường dẫn đó trong *System variables → Path* |
| Script báo không bật được Developer Mode | Vào *Settings → System → For developers*, bật **Developer Mode** rồi chạy lại `setup.bat` |
| Build lỗi lạ | `flutter clean`, rồi `flutter pub get`, rồi build lại |
