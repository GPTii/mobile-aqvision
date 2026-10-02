/// Default API / environment values.
/// Edit this file only when changing hosts, ports, or path prefixes.
class ApiDefaults {
  ApiDefaults._();

  /// Production API host (no scheme).
  static const String productionHost = 'dev1.aqvision.net';

  /// Backup API host, used when [productionHost] cannot be reached.
  /// Separate deployment (own database): accounts/cameras differ from dev1.
  static const String backupHost = 'media.aqptech.cloud';

  /// Production URL scheme (`https` or `http`).
  static const String productionScheme = 'https';

  /// Local Next.js / BFF port when debugging on web.
  static const int localApiPort = 3002;

  /// Fallback host name used on web when [Uri.base.host] is empty.
  static const String localHost = 'localhost';

  /// Path prefix for most REST endpoints.
  static const String apiPath = '/api';

  /// Path prefix for v1 auth / stats / devices endpoints.
  static const String apiV1Path = '/api/v1';

  /// Path segment for HLS / recording media under [apiPath].
  static const String mediaPathSegment = 'media';

  /// Public host gateways push camera streams to (MediaMTX ingest,
  /// `rtsp://<host>:1936/<path>`; gateway auto-push default).
  static const String mediaIngestHost = '14.161.6.65';

  /// The same ingest as seen by the media server itself: cloud cameras pull
  /// `rtsp://127.0.0.1:1935/<path>` (how cam1 / cam3 are set up on the server).
  static const String mediaIngestInternal = 'rtsp://127.0.0.1:1935';
}
