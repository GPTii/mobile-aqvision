import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/app_strings.dart';

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
  @override
  String toString() => "Improv error 0x${code.toRadixString(16)}";
}

class BleSetupService {
  BluetoothDevice? device;
  late BluetoothCharacteristic _state, _error, _cmd, _result, _caps;

  final stateStream = StreamController<int>.broadcast();
  final errorStream = StreamController<int>.broadcast();
  final resultStream = StreamController<List<int>>.broadcast();

  bool get isConnected => device != null;

  /// RPC commands written on the current connection.
  int _commandsSent = 0;
  final _subs = <StreamSubscription>[];

  /// Finds the gateway by BLE name (or remote id / MAC) and connects.
  /// startScan() returns as soon as scanning starts, so wait for the match
  /// itself (up to 15 s) instead of cancelling the listener right away.
  Future<void> connectToDevice(String nameOrMac) async {
    final found = Completer<BluetoothDevice>();
    bool matches(ScanResult r) =>
        r.device.platformName == nameOrMac ||
        r.advertisementData.advName == nameOrMac ||
        r.device.remoteId.str.toUpperCase() == nameOrMac.toUpperCase();
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        if (matches(r) && !found.isCompleted) found.complete(r.device);
      }
    });
    try {
      await FlutterBluePlus.startScan(withServices: [improvService], timeout: const Duration(seconds: 15));
      device = await found.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw Exception('Không tìm thấy thiết bị {name}'.trArgs({'name': nameOrMac}));
    } finally {
      await sub.cancel();
      await FlutterBluePlus.stopScan();
    }

    await _open();
  }

  /// Connects to [device] the way the official Improv SDK does: one MTU
  /// request (517), discover, enable the 3 notifications.
  Future<void> _open() async {
    // mtu: null — FBP would otherwise request 512 itself, and we request 517 below.
    await device!.connect(license: License.commercial, timeout: const Duration(seconds: 15), mtu: null);
    if (Platform.isAndroid) await device!.requestMtu(517);

    final chars = (await device!.discoverServices()).firstWhere((s) => s.uuid == improvService).characteristics;

    BluetoothCharacteristic c(int n) => chars.firstWhere((x) => x.uuid == improvChar(n));
    _state = c(1);
    _error = c(2);
    _cmd = c(3);
    _result = c(4);
    _caps = c(5);

    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs
      ..clear()
      ..add(_state.onValueReceived.listen((v) => stateStream.add(v.first)))
      ..add(_error.onValueReceived.listen((v) => errorStream.add(v.first)))
      ..add(_result.onValueReceived.listen(resultStream.add));

    for (final ch in [_state, _error, _result]) {
      await ch.setNotifyValue(true);
    }
    _commandsSent = 0;
    stateStream.add((await _state.read()).first);
  }

  /// Fresh BLE connection to the same gateway. The gateway's BLE service
  /// answers the 2nd and later RPC writes of a connection with GATT_UNLIKELY
  /// (android-code 14) — the official Improv app only ever sends one command
  /// per connection. So the WiFi command always goes out on a new link.
  Future<void> _reconnect() async {
    final d = device;
    if (d == null) return;
    try {
      await d.disconnect();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 800));
    await _open();
  }

  Future<int> capabilities() async => (await _caps.read()).first;

  /// Sends an RPC frame in one write, like the Improv SDK. Only when it does
  /// not fit the negotiated MTU is it split into MTU-sized writes (the gateway
  /// re-assembles consecutive writes, ble_protocol.py `on_write`).
  Future<void> _send(List<int> frame) async {
    _commandsSent++;
    final max = (device?.mtuNow ?? 23) - 3;
    for (var i = 0; i < frame.length; i += max) {
      final end = i + max < frame.length ? i + max : frame.length;
      await _cmd.write(frame.sublist(i, end), withoutResponse: false);
    }
  }

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
    } finally {
      await s1.cancel();
      await s2.cancel();
    }
  }

  /// Current Improv state, or null when it can't be read (link lost).
  Future<int?> _readState() async {
    try {
      final v = await _state.read();
      return v.isEmpty ? null : v.first;
    } catch (_) {
      return null;
    }
  }

  /// Result of `cmd` from the RESULT characteristic (when its notify was missed).
  Future<List<String>?> _readResult(int cmd) async {
    try {
      final v = await _result.read();
      return v.isNotEmpty && v.first == cmd ? improvStrings(v) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> deviceInfo() => _call(0x03, [], const Duration(seconds: 10));
  Future<void> identify() => _send(improvFrame(0x02));

  /// [(ssid, rssi, security)], strongest first; ends at the empty Result.
  /// Needs no authorization (README_BLE §3.4) — works in every state.
  Future<List<List<String>>> scanWifi() async {
    final bySsid = <String, List<String>>{};
    final done = Completer<void>();
    final sub = resultStream.stream.listen((v) {
      if (v.isEmpty || v.first != 0x04) return;
      final s = improvStrings(v);
      if (s == null) return; // corrupted frame: skip it, it is NOT the end marker
      if (s.isEmpty) {
        if (!done.isCompleted) done.complete();
        return;
      }
      if (s.first.trim().isEmpty) return; // hidden network
      // Same SSID on 2.4/5 GHz or several APs: keep the strongest.
      final old = bySsid[s.first];
      if (old == null ||
          (int.tryParse(s.length > 1 ? s[1] : '') ?? -999) > (int.tryParse(old.length > 1 ? old[1] : '') ?? -999)) {
        bySsid[s.first] = s;
      }
    });
    // The gateway reports a failed / refused scan through the Error characteristic.
    final errSub = errorStream.stream.listen((e) {
      if (e != 0 && !done.isCompleted) done.completeError(ImprovError(e));
    });
    try {
      if (_commandsSent > 0) await _reconnect(); // "Quét lại": new link, see _reconnect
      await _send(improvFrame(0x04));
      // The gateway allows its own WiFi rescan up to 45 s.
      await done.future.timeout(const Duration(seconds: 60));
    } finally {
      await sub.cancel();
      await errSub.cancel();
    }
    final nets = bySsid.values.toList()
      ..sort((a, b) =>
          (int.tryParse(b.length > 1 ? b[1] : '') ?? -999).compareTo(int.tryParse(a.length > 1 ? a[1] : '') ?? -999));
    return nets;
  }

  /// Returns the gateway URL, e.g. "http://192.168.1.189:5050"
  ///
  /// The write can come back with a GATT error (android-code 14 GATT_UNLIKELY
  /// on Android 14) even though the gateway received the frame and goes on to
  /// join the WiFi. So a write error is not trusted: we check whether the
  /// gateway moved to PROVISIONING / PROVISIONED and keep waiting for its result.
  Future<String> sendWifi(String ssid, String password) async {
    final s = utf8.encode(ssid), p = utf8.encode(password);
    final frame = improvFrame(0x01, [s.length, ...s, p.length, ...p]);
    // WiFi must be the first command of its connection (see _reconnect).
    if (_commandsSent > 0) await _reconnect();
    const timeout = Duration(seconds: 120);

    final done = Completer<List<String>>();
    void finish(List<String>? r) {
      if (r != null && !done.isCompleted) done.complete(r);
    }

    final s1 = resultStream.stream.listen((v) {
      if (v.isNotEmpty && v.first == 0x01) finish(improvStrings(v) ?? []);
    });
    final s2 = errorStream.stream.listen((e) {
      if (e != 0 && !done.isCompleted) done.completeError(ImprovError(e));
    });
    // PROVISIONED (0x04): read the result in case its notify was missed.
    final s3 = stateStream.stream.listen((st) async {
      if (st == 0x04) finish(await _readResult(0x01));
    });
    try {
      try {
        await _send(frame);
      } on FlutterBluePlusException catch (e) {
        if (!await _gatewayTookWifi()) rethrow;
        debugPrint('[BLE] WiFi write reported $e but the gateway is provisioning — waiting for its result');
        if (await _readState() == 0x04) finish(await _readResult(0x01));
      }
      final r = await done.future.timeout(timeout);
      return r.isNotEmpty ? r.first : "";
    } finally {
      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
    }
  }

  /// After a failed write: did the gateway start provisioning anyway?
  Future<bool> _gatewayTookWifi() async {
    for (var i = 0; i < 5; i++) {
      final st = await _readState();
      if (st == 0x03 || st == 0x04) return true;
      if (st == null) return false; // link lost: let the caller fall back to the LAN
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  void disconnect() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    device?.disconnect();
    device = null;
  }
}
