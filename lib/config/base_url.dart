/// Điểm cấu hình URL duy nhất — sửa file này hoặc truyền `--dart-define` khi build.
///
/// Máy dev hiện tại: CommaDesk + MediaServer cùng host `100.114.11.37:8080`.
/// Android emulator trên cùng máy: `--dart-define=API_BASE_URL=http://10.0.2.2:8080`
class BaseUrl {
  BaseUrl._();

  /// CommaDesk backend origin (không kèm `/api/v1`).
  static const String api = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://100.114.11.37:8080',
  );

  /// MediaServer public URL cho HLS/MP4.
  static const String mediaPublic = String.fromEnvironment(
    'MEDIA_PUBLIC_URL',
    defaultValue: 'http://100.114.11.37:8080',
  );

  /// MediaServer management URL cho `/index/api/*` ghi hình.
  static const String mediaManagement = String.fromEnvironment(
    'MEDIA_MANAGEMENT_URL',
    defaultValue: 'http://100.114.11.37:8080',
  );

  /// Secret MediaServer (Luồng A ghi hình). Không commit giá trị thật.
  /// `--dart-define=MEDIA_API_SECRET=...`
  static const String mediaApiSecret = String.fromEnvironment(
    'MEDIA_API_SECRET',
    defaultValue: '',
  );
}
