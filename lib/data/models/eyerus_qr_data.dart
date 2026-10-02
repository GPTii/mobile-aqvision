/// Gateway label QR (README_BLE Phụ lục B):
/// `EYERUS:3;N:<BLE name>;M:<Bluetooth MAC>;D:<device id>;G:<gateway id>[;U:<user password>]`.
///
/// Setup over BLE (Improv Wi-Fi) only needs the BLE name to find the right
/// gateway, then the WiFi SSID + password. Everything else is informational.
class EyerusQrData {
  final String version;
  final String name;
  final String mac;
  final String deviceId;
  final String gatewayId;

  EyerusQrData({
    required this.version,
    required this.name,
    this.mac = '',
    this.deviceId = '',
    this.gatewayId = '',
  });

  /// BLE name when known, otherwise the MAC (Android can match on it).
  String get bleTarget => name.isNotEmpty ? name : mac;

  static EyerusQrData? tryParse(String qrCode) {
    if (!qrCode.startsWith('EYERUS:')) return null;

    final fields = <String, String>{};
    for (final part in qrCode.split(';')) {
      // Split on the FIRST ':' only — MAC addresses contain ':' too.
      final idx = part.indexOf(':');
      if (idx > 0) fields[part.substring(0, idx)] = part.substring(idx + 1);
    }

    final name = fields['N'] ?? '';
    final mac = fields['M'] ?? '';
    if (name.isEmpty && mac.isEmpty) return null;

    return EyerusQrData(
      version: fields['EYERUS'] ?? '',
      name: name,
      mac: mac,
      deviceId: fields['D'] ?? '',
      gatewayId: fields['G'] ?? '',
    );
  }
}
