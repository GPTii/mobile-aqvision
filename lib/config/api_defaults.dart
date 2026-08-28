import 'base_url.dart';

/// Path prefix và fallback dev — host/URL xem [BaseUrl].
class ApiDefaults {
  ApiDefaults._();

  static String get productionHost => _hostFrom(BaseUrl.api);
  static int get productionPort => _portFrom(BaseUrl.api);
  static String get productionScheme => _schemeFrom(BaseUrl.api);

  static const int localApiPort = 8080;
  static const String localHost = 'localhost';
  static const String apiV1Path = '/api/v1';

  static String get mediaPublicUrl => BaseUrl.mediaPublic;
  static String get mediaManagementUrl => BaseUrl.mediaManagement;
  static String get mediaApiSecret => BaseUrl.mediaApiSecret;

  static String _schemeFrom(String url) {
    final uri = Uri.tryParse(url);
    return uri?.scheme.isNotEmpty == true ? uri!.scheme : 'http';
  }

  static String _hostFrom(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return '10.0.2.2';
    return uri.host;
  }

  static int _portFrom(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 8080;
    if (uri.hasPort) return uri.port;
    return uri.scheme == 'https' ? 443 : 80;
  }
}
