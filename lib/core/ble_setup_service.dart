import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../data/models/eyerus_ble_models.dart';
import '../data/models/eyerus_qr_data.dart';
import 'dart:io';

class BleSetupService {
  // Service UUID
  static const String SERVICE_UUID = "e7e50001-7a1e-4c3b-9d2f-5a6b8c0d1e2f";
  // Characteristic UUIDs
  static const String INFO_UUID = "e7e50002-7a1e-4c3b-9d2f-5a6b8c0d1e2f";
  static const String STATUS_UUID = "e7e50003-7a1e-4c3b-9d2f-5a6b8c0d1e2f";
  static const String NETWORKS_UUID = "e7e50004-7a1e-4c3b-9d2f-5a6b8c0d1e2f";
  static const String COMMAND_UUID = "e7e50005-7a1e-4c3b-9d2f-5a6b8c0d1e2f";
  static const String RESULT_UUID = "e7e50006-7a1e-4c3b-9d2f-5a6b8c0d1e2f";

  BluetoothDevice? _device;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _resultChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _infoChar;
  BluetoothCharacteristic? _networksChar;

  StreamSubscription<List<int>>? _resultSub;
  StreamSubscription<List<int>>? _statusSub;
  
  // Stream Controllers to notify UI
  final _statusController = StreamController<EyerusBleStatus>.broadcast();
  final _resultController = StreamController<EyerusBleResult>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<EyerusBleStatus> get statusStream => _statusController.stream;
  Stream<EyerusBleResult> get resultStream => _resultController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  EyerusBleInfo? deviceInfo;
  
  /// Bắt đầu quét và kết nối tới thiết bị
  Future<void> connectToDevice(EyerusQrData qrData) async {
    bool found = false;

    // Lắng nghe kết quả scan
    var subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == qrData.name || r.device.remoteId.str == qrData.mac) {
          found = true;
          await FlutterBluePlus.stopScan();
          _device = r.device;
          
          await _device!.connect(autoConnect: false, license: License.nonprofit);
          _connectionController.add(true);
          
          // Request MTU (cho Android)
          if (Platform.isAndroid) { // Thường dùng logic check nền tảng, giả lập
             await _device!.requestMtu(517);
          }

          await _discoverServices();
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    if (!found) {
      throw Exception("Không tìm thấy thiết bị ${qrData.name}");
    }
  }

  Future<void> _discoverServices() async {
    if (_device == null) return;
    List<BluetoothService> services = await _device!.discoverServices();
    
    for (var service in services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var char in service.characteristics) {
          if (char.uuid.toString() == INFO_UUID) _infoChar = char;
          if (char.uuid.toString() == STATUS_UUID) _statusChar = char;
          if (char.uuid.toString() == NETWORKS_UUID) _networksChar = char;
          if (char.uuid.toString() == COMMAND_UUID) _cmdChar = char;
          if (char.uuid.toString() == RESULT_UUID) _resultChar = char;
        }
      }
    }

    if (_infoChar == null || _cmdChar == null || _resultChar == null) {
      throw Exception("Thiết bị không hỗ trợ dịch vụ Eyerus");
    }

    // Đọc INFO ban đầu
    List<int> infoBytes = await _infoChar!.read();
    deviceInfo = EyerusBleInfo.fromJson(jsonDecode(utf8.decode(infoBytes)));

    // Bật notify cho RESULT và STATUS
    if (_resultChar!.properties.notify) {
      await _resultChar!.setNotifyValue(true);
      _resultSub = _resultChar!.lastValueStream.listen((value) async {
        if (value.isNotEmpty) {
           // Notify chỉ là cờ báo, cần read() lại để lấy toàn bộ json
           var fullData = await _resultChar!.read();
           var resJson = jsonDecode(utf8.decode(fullData));
           _resultController.add(EyerusBleResult.fromJson(resJson));
        }
      });
    }

    if (_statusChar!.properties.notify) {
      await _statusChar!.setNotifyValue(true);
      _statusSub = _statusChar!.lastValueStream.listen((value) async {
        if (value.isNotEmpty) {
           var fullData = await _statusChar!.read();
           var statusJson = jsonDecode(utf8.decode(fullData));
           _statusController.add(EyerusBleStatus.fromJson(statusJson));
        }
      });
    }
  }

  /// Ghi lệnh xuống Gateway
  Future<void> sendCommand(Map<String, dynamic> command) async {
    if (_cmdChar == null) throw Exception("Chưa kết nối");
    String jsonStr = jsonEncode(command);
    List<int> bytes = utf8.encode(jsonStr);
    
    // Gửi lệnh qua COMMAND characteristic
    await _cmdChar!.write(bytes, withoutResponse: false);
  }

  /// Các lệnh Helper
  Future<void> auth(String pin) async {
    await sendCommand({"cmd": "auth", "pin": pin, "id": "auth1"});
  }
  
  Future<void> scanWifi() async {
    await sendCommand({"cmd": "scan", "id": "scan1"});
  }
  
  Future<List<EyerusBleNetwork>> getNetworks() async {
    if (_networksChar == null) return [];
    List<int> bytes = await _networksChar!.read();
    List<dynamic> list = jsonDecode(utf8.decode(bytes));
    return list.map((e) => EyerusBleNetwork.fromJson(e)).toList();
  }
  
  Future<void> connectWifi(String ssid, String password) async {
    await sendCommand({
      "cmd": "connect", 
      "ssid": ssid, 
      "password": password, 
      "id": "conn1"
    });
  }

  Future<void> sendInit(Map<String, dynamic> initData) async {
    initData["cmd"] = "init";
    initData["id"] = "init1";
    await sendCommand(initData);
  }

  Future<void> finish() async {
    await sendCommand({"cmd": "finish", "id": "fin1"});
  }

  void disconnect() {
    _resultSub?.cancel();
    _statusSub?.cancel();
    _device?.disconnect();
    _connectionController.add(false);
  }
}
