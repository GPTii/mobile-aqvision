import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/gateway_session.dart';
import 'package:mobile/data/gateway_store.dart';

void main() {
  test('parseGatewayAddress splits host and port', () {
    expect(parseGatewayAddress('192.168.1.189'), ('192.168.1.189', 5050));
    expect(parseGatewayAddress('192.168.1.189:8080'), ('192.168.1.189', 8080));
    expect(parseGatewayAddress('http://gw.local:9000/abc'), ('gw.local', 9000));
    // An explicit port field wins over one typed into the address.
    expect(parseGatewayAddress('192.168.1.189:8080', port: 7000), ('192.168.1.189', 7000));
  });

  test('SavedGateway keeps its port and old data defaults to 5050', () {
    final old = SavedGateway.fromJson({'id': 'a', 'name': 'n', 'ip': '1.2.3.4', 'hostname': 'h'});
    expect(old.port, 5050);
    expect(old.address, '1.2.3.4');

    final custom = SavedGateway.fromJson(const SavedGateway('a', 'n', '1.2.3.4', 'h', 8080).toJson());
    expect(custom.port, 8080);
    expect(custom.address, '1.2.3.4:8080');
  });
}
