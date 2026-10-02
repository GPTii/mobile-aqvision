import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/eyerus_qr_data.dart';

void main() {
  test('parses the real gateway label (README_BLE Phụ lục B), no PIN field', () {
    final q = EyerusQrData.tryParse(
        'EYERUS:3;N:Eyerus-8C09;M:FC:23:CD:03:8C:09;D:6f352dc9d8e9;G:gw-6f352dc9;U:kP4mZx7Qad')!;
    expect(q.version, '3');
    expect(q.name, 'Eyerus-8C09');
    expect(q.mac, 'FC:23:CD:03:8C:09');
    expect(q.deviceId, '6f352dc9d8e9');
    expect(q.gatewayId, 'gw-6f352dc9');
    expect(q.bleTarget, 'Eyerus-8C09');
  });

  test('old EYERUS:2 label without U/G still works', () {
    final q = EyerusQrData.tryParse('EYERUS:2;N:Eyerus-8C09;M:FC:23:CD:03:8C:09;D:6f352dc9d8e9')!;
    expect(q.name, 'Eyerus-8C09');
    expect(q.gatewayId, '');
  });

  test('rejects foreign QR codes and labels without a BLE name or MAC', () {
    expect(EyerusQrData.tryParse('https://example.com'), isNull);
    expect(EyerusQrData.tryParse('EYERUS:3;D:6f352dc9d8e9'), isNull);
  });
}
