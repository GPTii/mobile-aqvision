/// Default API / environment values.
/// Edit this file only when changing hosts, ports, or path prefixes.
class ApiDefaults {
  ApiDefaults._();

  /// Production API host (no scheme).
  static const String productionHost = 'dev1.aqvision.net';

  /// Production URL scheme (`https` or `http`).
  /// `http` for now: dev1 serves a self-signed cert that ExoPlayer rejects.
  static const String productionScheme = 'http';

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
}
