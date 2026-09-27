import 'package:flutter/foundation.dart';

import 'api_defaults.dart';

/// Resolves API base URLs from [ApiDefaults].
/// Do not put raw hosts/ports here — change [ApiDefaults] instead.
class ApiConfig {
  ApiConfig._();

  /// Production origin, e.g. `https://api.aqvision.net`.
  static String get productionOrigin =>
      '${ApiDefaults.productionScheme}://${ApiDefaults.productionHost}';

  /// Scheme + host (+ port if needed), without `/api` path.
  static String get origin {
    if (kIsWeb) {
      final host =
          Uri.base.host.isNotEmpty ? Uri.base.host : ApiDefaults.localHost;
      final isLocal = host == 'localhost' || host == '127.0.0.1';
      if (isLocal && Uri.base.port != ApiDefaults.localApiPort) {
        return 'http://$host:${ApiDefaults.localApiPort}';
      }
      return '${Uri.base.scheme}://${Uri.base.authority}';
    }
    return productionOrigin;
  }

  /// `/api` — groups, proxies, rapidmedia, alerts, storage, …
  static String get apiBase => '$origin${ApiDefaults.apiPath}';

  /// `/api/v1` — auth, stats, devices, …
  static String get apiV1Base => '$origin${ApiDefaults.apiV1Path}';

  /// Web app origin for cookie auth (`/api/auth/login`, logout).
  static String get webOrigin => origin;

  /// HLS / recording media base: `/api/media`.
  /// Force HTTP for media to prevent ExoPlayer from rejecting self-signed SSL on dev.
  static String get mediaBase {
    if (origin.startsWith('https://dev1')) {
      return '${origin.replaceFirst('https://', 'http://')}${ApiDefaults.apiPath}/${ApiDefaults.mediaPathSegment}';
    }
    return '$apiBase/${ApiDefaults.mediaPathSegment}';
  }
}
