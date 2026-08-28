# AQ-VISION Mobile → CommaDesk API

Ứng dụng Flutter giám sát camera, đã chuyển từ backend AQ-VISION (`api.aqvision.net`) sang **CommaDesk** (`/api/v1`).

## API CommaDesk đang dùng

| Chức năng | Endpoint CommaDesk |
|-----------|-------------------|
| Đăng nhập | `POST /api/v1/auth/login` (email + password) |
| Profile | `GET/PUT /api/v1/profile` |
| Đổi mật khẩu | `POST /api/v1/profile/change-password` |
| Refresh / Logout | `POST /api/v1/auth/refresh`, `POST /api/v1/auth/logout` |
| Push FCM | `POST /api/v1/push/register` |
| Camera (catalog) | `GET/POST /api/v1/cameras`, `GET /api/v1/me/cameras` |
| Nhóm camera | `GET/POST /api/v1/camera-groups`, `GET /api/v1/me/camera-groups` |
| Trạng thái camera | `PUT /api/v1/cameras/:id/status` |
| Thông báo inbox | `GET /api/v1/notifications`, `PATCH .../read` |
| Cảnh báo AI | `GET /api/v1/alerts` |

## Chạy dev

Sửa URL mặc định tại `lib/config/base_url.dart` hoặc truyền khi build:

```bash
cd requirements/phase_19/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Trên thiết bị thật, thay bằng IP máy chạy CommaDesk backend.

### Phát HLS / WebRTC (MediaServer)

```bash
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.10:8080 \
  --dart-define=MEDIA_PUBLIC_URL=http://192.168.1.10:8080 \
  --dart-define=MEDIA_MANAGEMENT_URL=http://192.168.1.10:8080 \
  --dart-define=MEDIA_API_SECRET=<media-server-secret>
```

- **HLS:** `{MEDIA_PUBLIC_URL}/{app}/{stream}/hls.m3u8`
- **Ghi hình:** gọi trực tiếp MediaServer `/index/api/*` (Luồng A) khi có `MEDIA_API_SECRET`

## Chưa có trên CommaDesk (stub / thông báo trong app)

- Gói subscription / billing (`/subscription/*`)
- Quota lưu trữ cloud (`/storage`)
- SSE trạng thái proxy realtime — thay bằng poll 30s
- Proxy web `/api/rapidmedia/*` — dùng MediaServer trực tiếp nếu cấu hình secret

## Kiểm tra

```bash
flutter analyze
flutter test
```

## Nhánh tích hợp

Branch: `feature/integrate-commadesk` (từ `huong-van`).
