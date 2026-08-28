import 'package:flutter/foundation.dart';

import 'api_defaults.dart';
import 'base_url.dart';

/// Resolves CommaDesk API base URLs from [BaseUrl] and dart-define overrides.
class ApiConfig {
  ApiConfig._();

  static String get _hostPort {
    if (kIsWeb) {
      final host =
          Uri.base.host.isNotEmpty ? Uri.base.host : ApiDefaults.localHost;
      final isLocal = host == 'localhost' || host == '127.0.0.1';
      if (isLocal) {
        return '$host:${ApiDefaults.localApiPort}';
      }
      return Uri.base.authority;
    }
    final configured = BaseUrl.api.trim();
    if (configured.isNotEmpty) {
      final uri = Uri.parse(configured.replaceAll(RegExp(r'/+$'), ''));
      final defaultPort = uri.scheme == 'https' ? 443 : 80;
      if (!uri.hasPort || uri.port == defaultPort) return uri.host;
      return uri.authority;
    }
    final host = ApiDefaults.productionHost;
    final port = ApiDefaults.productionPort;
    final defaultPort =
        ApiDefaults.productionScheme == 'https' ? 443 : 80;
    if (port == defaultPort) return host;
    return '$host:$port';
  }

  /// Origin without path, e.g. `http://10.0.2.2:8080`.
  static String get origin {
    if (!kIsWeb) {
      final configured = BaseUrl.api.trim();
      if (configured.isNotEmpty) {
        return configured.replaceAll(RegExp(r'/+$'), '');
      }
    }
    return '${ApiDefaults.productionScheme}://$_hostPort';
  }

  /// CommaDesk REST API base: `/api/v1`.
  static String get apiV1Base =>
      '${origin.replaceAll(RegExp(r'/+$'), '')}${ApiDefaults.apiV1Path}';

  /// Legacy alias kept for stores that referenced `apiBase`.
  static String get apiBase => apiV1Base;

  /// Public MediaServer URL for HLS / MP4 playback.
  static String get mediaPublicBase {
    final configured = ApiDefaults.mediaPublicUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }
    return origin;
  }

  /// MediaServer management base for `/index/api/*` recording calls.
  static String get mediaManagementBase {
    final configured = ApiDefaults.mediaManagementUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceAll(RegExp(r'/+$'), '');
    }
    return mediaPublicBase;
  }

  static String get mediaApiSecret => ApiDefaults.mediaApiSecret.trim();

  static bool get hasMediaRecording =>
      mediaManagementBase.isNotEmpty && mediaApiSecret.isNotEmpty;

  /// Build HLS URL for a camera stream (html5stream convention).
  static String buildHlsUrl({
    required String app,
    required String stream,
    String? accessToken,
  }) {
    final base = mediaPublicBase;
    final path =
        '$base/${Uri.encodeComponent(app)}/${Uri.encodeComponent(stream)}/hls.m3u8';
    if (accessToken == null || accessToken.isEmpty) return path;
    return '$path?token=${Uri.encodeComponent(accessToken)}';
  }

  static String buildFmp4Url({
    required String app,
    required String stream,
    String? accessToken,
  }) {
    final base = mediaPublicBase;
    final path =
        '$base/${Uri.encodeComponent(app)}/${Uri.encodeComponent(stream)}.live.mp4';
    if (accessToken == null || accessToken.isEmpty) return path;
    return '$path?token=${Uri.encodeComponent(accessToken)}';
  }
}
