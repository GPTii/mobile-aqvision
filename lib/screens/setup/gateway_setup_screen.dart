import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../data/auth_store.dart';
import '../../config/api_config.dart';
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
  
  StreamSubscription? _stateSub;
  StreamSubscription? _errorSub;

  final TextEditingController _wifiPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startSetup();
  }

  Future<void> _startSetup() async {
    try {
      _stateSub = _bleService.stateStream.listen(_onStateChanged);
      _errorSub = _bleService.errorStream.listen((err) {
        if (err != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi BLE: $err')),
          );
        }
      });

      await _bleService.connectToDevice(widget.qrData.name);
      
      setState(() {
        _statusMessage = 'Đã kết nối. Đang lấy thông tin...';
      });

      final info = await _bleService.deviceInfo();
      print("Device info: $info");

    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi kết nối: ${e.toString()}';
        _isConnecting = false;
      });
    }
  }

  void _onStateChanged(int state) async {
    if (state == 1) { // AUTHORIZATION_REQUIRED
      setState(() {
        _statusMessage = 'Vui lòng nhấn nút trên Gateway để xác thực!';
        _isConnecting = true;
      });
    } else if (state == 2) { // AUTHORIZED
      setState(() {
        _statusMessage = 'Xác thực thành công. Đang quét WiFi...';
      });
      try {
        final nets = await _bleService.scanWifi();
        setState(() {
          _networks = nets.map((e) => EyerusBleNetwork(ssid: e[0], rssi: int.tryParse(e[1]) ?? 0, security: e.length > 2 ? e[2] : '')).toList();
          _statusMessage = 'Vui lòng chọn WiFi để Gateway kết nối';
          _isConnecting = false;
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Lỗi quét WiFi: ${e.toString()}';
          _isConnecting = false;
        });
      }
    } else if (state == 3) { // PROVISIONING
      setState(() {
        _statusMessage = 'Đang kết nối mạng...';
        _isConnecting = true;
      });
    } else if (state == 4) { // PROVISIONED
      setState(() {
        _statusMessage = 'Kết nối mạng thành công!';
        _isConnecting = false;
      });
    }
  }

  void _onSendWifi() async {
    if (_selectedNetwork == null) return;
    
    setState(() {
      _isConfiguring = true;
      _statusMessage = 'Đang gửi thông tin WiFi...';
    });
    
    try {
      final url = await _bleService.sendWifi(
        _selectedNetwork!.ssid, 
        _wifiPasswordController.text
      );
      
      setState(() {
        _statusMessage = 'Gateway đã vào mạng (URL: $url). Đang đăng ký lên Cloud...';
      });
      
      try {
        final token = AuthStore.instance.token ?? '';
        await http.post(
          Uri.parse('${ApiConfig.apiV1Base}/gateways/register'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
          body: jsonEncode({
            'deviceId': widget.qrData.deviceId,
            'name': widget.qrData.name,
            'mac': widget.qrData.mac,
            'localIp': url,
          })
        );
      } catch (e) {
        print('Lỗi đăng ký Cloud: $e');
      }

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
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi gửi WiFi: ${e.toString()}';
        _isConfiguring = false;
      });
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _errorSub?.cancel();
    _bleService.disconnect();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Gateway'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Thiết lập Gateway mới',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              if (_isConnecting) ...[
                const Center(
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 24),
              ],
              
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              
              if (!_isConnecting && _networks.isNotEmpty) ...[
                const SizedBox(height: 32),
                DropdownButtonFormField<EyerusBleNetwork>(
                  decoration: const InputDecoration(
                    labelText: 'Chọn mạng WiFi',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedNetwork,
                  items: _networks.map((net) {
                    return DropdownMenuItem(
                      value: net,
                      child: Text('${net.ssid} (${net.rssi} dBm)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedNetwork = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _wifiPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu WiFi',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isConfiguring ? null : _onSendWifi,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isConfiguring 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kết nối Gateway với WiFi'),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
