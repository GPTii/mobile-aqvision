import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ble_setup_service.dart';
import '../../data/models/eyerus_ble_models.dart';
import '../../data/models/eyerus_qr_data.dart';

class GatewaySetupScreen extends StatefulWidget {
  final EyerusQrData qrData;

  const GatewaySetupScreen({Key? key, required this.qrData}) : super(key: key);

  @override
  State<GatewaySetupScreen> createState() => _GatewaySetupScreenState();
}

class _GatewaySetupScreenState extends State<GatewaySetupScreen> {
  final BleSetupService _bleService = BleSetupService();
  String _statusMessage = 'Đang tìm kiếm thiết bị...';
  bool _isConnecting = true;
  bool _isConfiguring = false;
  List<EyerusBleNetwork> _networks = [];
  EyerusBleNetwork? _selectedNetwork;

  StreamSubscription? _resultSub;
  StreamSubscription? _statusSub;

  final TextEditingController _wifiPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  Future<void> _startSetup() async {
    try {
      _resultSub = _bleService.resultStream.listen(_onBleResult);
      _statusSub = _bleService.statusStream.listen(_onBleStatus);

      await _bleService.connectToDevice(widget.qrData);
      setState(() {
        _statusMessage = 'Đã kết nối. Đang xác thực...';
      });

      // Bắt đầu auth
      await _bleService.auth(widget.qrData.pin);
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi kết nối: ${e.toString()}';
        _isConnecting = false;
      });
    }
  }

  void _onBleResult(EyerusBleResult result) async {
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${result.error} - ${result.message}')),
      );
      return;
    }

    switch (result.cmd) {
      case 'auth':
        setState(() {
          _statusMessage = 'Xác thực thành công. Đang quét WiFi...';
        });
        await _bleService.scanWifi();
        break;
      
      case 'scan':
        final networks = await _bleService.getNetworks();
        setState(() {
          _networks = networks;
          _statusMessage = 'Vui lòng chọn WiFi để Gateway kết nối';
          _isConnecting = false;
        });
        break;
        
      case 'connect':
        // Kết quả trả về của lệnh gửi pass wifi (chỉ là cờ báo đã nhận)
        setState(() {
          _statusMessage = 'Đang đợi Gateway kết nối WiFi...';
        });
        break;

      case 'init':
        setState(() {
          _statusMessage = 'Đang hoàn tất cấu hình...';
        });
        await _bleService.finish();
        break;

      case 'finish':
        setState(() {
          _isConfiguring = false;
          _statusMessage = 'Thiết lập thành công!';
        });
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Thành công'),
            content: const Text('Gateway đã được cài đặt và kết nối mạng thành công.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng dialog
                  Navigator.pop(context); // Đóng màn hình setup
                },
                child: const Text('Đóng'),
              )
            ],
          )
        );
        break;
    }
  }

  void _onBleStatus(EyerusBleStatus status) async {
    // Nếu gateway đã online (có internet) và ta đang trong bước chờ cấu hình
    if (status.online && _isConfiguring && _statusMessage == 'Đang đợi Gateway kết nối WiFi...') {
      setState(() {
        _statusMessage = 'Đã kết nối WiFi. Đang khởi tạo...';
      });
      
      // Lấy Token của người dùng (Giả lập hoặc lấy từ SharedPreferences/API Core)
      // Đây là dữ liệu giả lập cho owner
      final initData = {
        "gateway": {
          "name": widget.qrData.name,
          "timezone": "Asia/Ho_Chi_Minh",
        },
        "owner": {
          "account_id": "test_user_123",
          "token": "token_placeholder"
        }
      };

      await _bleService.sendInit(initData);
    }
  }

  void _connectToWifi() {
    if (_selectedNetwork == null) return;
    
    setState(() {
      _isConfiguring = true;
      _statusMessage = 'Đang gửi thông tin WiFi...';
    });
    
    _bleService.connectWifi(
      _selectedNetwork!.ssid, 
      _wifiPasswordController.text
    );
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _statusSub?.cancel();
    _bleService.disconnect();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt Gateway')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              _statusMessage, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            if (_isConnecting || _isConfiguring) 
              const CircularProgressIndicator(),

            if (!_isConnecting && !_isConfiguring && _networks.isNotEmpty) ...[
              DropdownButtonFormField<EyerusBleNetwork>(
                value: _selectedNetwork,
                hint: const Text('Chọn mạng WiFi'),
                items: _networks.map((net) => DropdownMenuItem(
                  value: net,
                  child: Text('${net.ssid} (${net.signal}%)'),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedNetwork = val;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _wifiPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu WiFi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _connectToWifi,
                child: const Text('Kết nối'),
              )
            ]
          ],
        ),
      ),
    );
  }
}
