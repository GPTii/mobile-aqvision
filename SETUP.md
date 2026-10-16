# Cài đặt môi trường cho AQPConnect (Windows)

Clone project về, chạy **một file** là cài xong mọi thứ, sau đó chỉ cần `flutter devices` / `flutter run`.

## 1. Chạy script cài đặt

```powershell
git clone <url-repo>
cd mobile
```

Sau đó **double-click `setup.bat`**, hoặc chạy trong terminal:

```powershell
.\setup.bat
```

Script sẽ tự làm các việc sau (bước nào máy đã có thì bỏ qua):

| Bước | Cài gì | Ghi chú |
|---|---|---|
| 1 | **Git** | cài qua `winget` nếu máy chưa có |
| 2 | **Windows Developer Mode** | Flutter cần quyền tạo symlink cho plugin. Windows sẽ hỏi quyền Admin, hãy chọn **Yes** |
| 3 | **JDK 17** (Eclipse Temurin) | Đặt `JAVA_HOME`. Nếu máy đã có JDK 17–21 thì dùng luôn |
| 4 | **Flutter 3.29.3** | Lấy đúng bản ghim trong `.fvmrc` và thêm vào `PATH` |
| 5 | **Android SDK** | gồm platform-tools (adb), `android-36`, build-tools 35, NDK `27.0.12077973`, Google USB driver. Tự chấp nhận license và đặt `ANDROID_HOME` |
| 6 | **Thư viện project** | `flutter pub get` |
| 7 | **Build thử** | `flutter build apk --debug` để tải sẵn Gradle và thư viện Android |
| 8 | `flutter doctor` | Kiểm tra lại toàn bộ |

- Mặc định mọi thứ được cài vào `C:\dev\` (`jdk-17`, `flutter-3.29.3`, `android-sdk`). Nếu máy đã có Android SDK (ví dụ do Android Studio cài) thì script dùng luôn SDK đó.
- Cần khoảng **6 GB** ổ cứng và mạng ổn định. Lần đầu mất khoảng **15–30 phút**.
- Script chạy lại nhiều lần vẫn an toàn. Nếu đang chạy mà lỗi mạng, cứ chạy lại.

Tuỳ chọn:

```powershell
.\setup.bat -InstallDir D:\dev   # cài vào chỗ khác (đường dẫn không được có dấu cách)
.\setup.bat -SkipWarmup          # bỏ bước build thử để xong nhanh hơn
```

> ⚠️ Cài xong phải **đóng terminal và mở cửa sổ mới**, kể cả VS Code, thì `PATH` mới có hiệu lực.

## 2. Kết nối điện thoại Android

1. Trên điện thoại vào **Cài đặt → Thông tin điện thoại**, chạm **7 lần** vào *Số hiệu bản tạo (Build number)* để mở **Tùy chọn nhà phát triển**.
2. Vào **Tùy chọn nhà phát triển** và bật **Gỡ lỗi USB (USB debugging)**.
3. Cắm cáp USB (phải là cáp truyền dữ liệu, không phải cáp chỉ để sạc). Khi điện thoại hỏi *"Cho phép gỡ lỗi USB?"* thì chọn **Cho phép**.

## 3. Chạy app

```powershell
flutter devices            # phải thấy tên điện thoại trong danh sách
flutter run                # chạy bản debug lên điện thoại (r = hot reload, R = restart, q = thoát)
flutter run -d <device_id> # khi có nhiều thiết bị
flutter run --release      # chạy bản release
```

## 4. Build APK

```powershell
flutter build apk --release --split-per-abi
```

File APK nằm ở **`build\app\outputs\apk\release\`**:

- `AQPConnect-<version>-release-arm64-v8a.apk`: **dùng file này cho hầu hết điện thoại**
- `AQPConnect-<version>-release-armeabi-v7a.apk`: máy 32-bit đời cũ
- `AQPConnect-<version>-release-x86_64.apk`: máy ảo

Muốn một APK duy nhất chạy trên mọi máy: `flutter build apk --release`, file sẽ ở `build\app\outputs\flutter-apk\app-release.apk`.

## Xử lý lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| `flutter` không nhận lệnh | Chưa mở terminal mới sau khi cài, hãy đóng hết rồi mở lại |
| `flutter devices` không thấy điện thoại | Kiểm tra cáp và USB debugging, rút ra cắm lại rồi chọn *Cho phép*. Chạy `adb devices`: nếu thấy `unauthorized` thì mở khóa điện thoại và xác nhận lại |
| `flutter doctor` báo thiếu **Android Studio** / **Visual Studio** | **Bỏ qua được.** Không cần hai thứ này để chạy và build Android |
| Báo đang dùng Flutter khác 3.29.3 | Máy có sẵn một bản Flutter khác trong PATH hệ thống. Gỡ đường dẫn đó khỏi *System variables → Path* |
| Build lỗi lạ | `flutter clean`, rồi `flutter pub get`, rồi build lại |
| Script báo không bật được Developer Mode | Vào *Settings → System → For developers*, bật **Developer Mode** rồi chạy lại `setup.bat` |
