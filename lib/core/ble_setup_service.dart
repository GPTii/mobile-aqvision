import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

final improvService = Guid("00467768-6228-2272-4663-277478268000");
Guid improvChar(int n) => Guid("00467768-6228-2272-4663-27747826800$n");

List<int> improvFrame(int cmd, [List<int> data = const []]) {
  final out = [cmd, data.length, ...data];
  return [...out, out.fold<int>(0, (a, b) => a + b) & 0xFF];
}

/// Result frame -> list of strings (null when the checksum is wrong)
List<String>? improvStrings(List<int> v) {
  if (v.length < 3) return null;
  if (v.sublist(0, v.length - 1).fold<int>(0, (a, b) => a + b) & 0xFF != v.last) return null;
  final out = <String>[];
  var i = 2;
  while (i < v.length - 1) {
    final n = v[i];
    out.add(utf8.decode(v.sublist(i + 1, i + 1 + n)));
    i += 1 + n;
  }
  return out;
}

class ImprovError implements Exception {
  final int code;
  ImprovError(this.code);
  @override String toString() => "Improv error 0x${code.toRadixString(16)}";
}

class BleSetupService {
  BluetoothDevice? device;
  late BluetoothCharacteristic _state, _error, _cmd, _result, _caps;
  
  final stateStream = StreamController<int>.broadcast();
  final errorStream = StreamController<int>.broadcast();
  final resultStream = StreamController<List<int>>.broadcast();

  bool get isConnected => device != null;

  Future<void> connectToDevice(String nameOrMac) async {
    bool found = false;
    var sub = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == nameOrMac || r.device.remoteId.str == nameOrMac) {
          found = true;
          await FlutterBluePlus.stopScan();
          device = r.device;
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(withServices: [improvService], timeout: const Duration(seconds: 15));
    await sub.cancel();

    if (!found || device == null) {
      throw Exception("Không tìm thấy thiết bị $nameOrMac");
    }

    await device!.connect(timeout: const Duration(seconds: 15));
    if (Platform.isAndroid) await device!.requestMtu(517);
    
    final chars = (await device!.discoverServices())
        .firstWhere((s) => s.uuid == improvService).characteristics;
    
    BluetoothCharacteristic c(int n) => chars.firstWhere((x) => x.uuid == improvChar(n));
    _state = c(1); _error = c(2); _cmd = c(3); _result = c(4); _caps = c(5);
    
    _state.onValueReceived.listen((v) => stateStream.add(v.first));
    _error.onValueReceived.listen((v) => errorStream.add(v.first));
    _result.onValueReceived.listen(resultStream.add);
    
    for (final ch in [_state, _error, _result]) { await ch.setNotifyValue(true); }
    stateStream.add((await _state.read()).first);
  }

  Future<int> capabilities() async => (await _caps.read()).first;

  Future<void> _send(List<int> frame) => _cmd.write(frame, withoutResponse: false);

  /// Waits for the Result of `cmd`; throws on an Error notify != 0
  Future<List<String>> _call(int cmd, List<int> data, Duration timeout) async {
    final done = Completer<List<String>>();
    final s1 = resultStream.stream.listen((v) {
      if (v.isNotEmpty && v.first == cmd && !done.isCompleted) done.complete(improvStrings(v) ?? []);
    });
    final s2 = errorStream.stream.listen((e) {
      if (e != 0 && !done.isCompleted) done.completeError(ImprovError(e));
    });
    try {
      await _send(improvFrame(cmd, data));
      return await done.future.timeout(timeout);
    } finally { await s1.cancel(); await s2.cancel(); }
  }

  Future<List<String>> deviceInfo() => _call(0x03, [], const Duration(seconds: 10));
  Future<void> identify() => _send(improvFrame(0x02));

  /// [(ssid, rssi, security)], strongest first; ends at the empty Result
  Future<List<List<String>>> scanWifi() async {
    final nets = <List<String>>[];
    final done = Completer<void>();
    final sub = resultStream.stream.listen((v) {
      if (v.isEmpty || v.first != 0x04) return;
      final s = improvStrings(v) ?? [];
      if (s.isEmpty) { if (!done.isCompleted) done.complete(); } else { nets.add(s); }
    });
    try {
      await _send(improvFrame(0x04));
      await done.future.timeout(const Duration(seconds: 30));
      return nets;
    } finally { await sub.cancel(); }
  }

  /// Returns the gateway URL, e.g. "http://192.168.1.189:5050"
  Future<String> sendWifi(String ssid, String password) async {
    final s = utf8.encode(ssid), p = utf8.encode(password);
    final r = await _call(0x01, [s.length, ...s, p.length, ...p], const Duration(seconds: 120));
    return r.isNotEmpty ? r.first : "";
  }

  void disconnect() {
    device?.disconnect();
    device = null;
  }
}
