class EyerusQrData {
  final String version;
  final String name;
  final String mac;
  final String deviceId;
  final String pin;

  EyerusQrData({
    required this.version,
    required this.name,
    required this.mac,
    required this.deviceId,
    required this.pin,
  });

  /// Parse QR Code có định dạng: EYERUS:1;N:Eyerus-8C09;M:FC:23:CD:03:8C:09;D:6f352dc9d8e9;P:482913
  static EyerusQrData? tryParse(String qrCode) {
    if (!qrCode.startsWith('EYERUS:')) return null;

    final parts = qrCode.split(';');
    String version = '';
    String name = '';
    String mac = '';
    String deviceId = '';
    String pin = '';

    for (var part in parts) {
      final idx = part.indexOf(':');
      if (idx == -1) continue;
      final key = part.substring(0, idx);
      final value = part.substring(idx + 1);

      switch (key) {
        case 'EYERUS':
          version = value;
          break;
        case 'N':
          name = value;
          break;
        case 'M':
          mac = value;
          break;
        case 'D':
          deviceId = value;
          break;
        case 'P':
          pin = value;
          break;
      }
    }

    if (name.isEmpty || deviceId.isEmpty || pin.isEmpty) return null;

    return EyerusQrData(
      version: version,
      name: name,
      mac: mac,
      deviceId: deviceId,
      pin: pin,
    );
  }
}
