import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../data/models/eyerus_qr_data.dart';
import 'gateway_setup_screen.dart';
import 'hotspot_setup_screen.dart';
import '../../utils/app_strings.dart';

class BleScannerScreen extends StatefulWidget {
  const BleScannerScreen({super.key});

  @override
  State<BleScannerScreen> createState() => _BleScannerScreenState();
}

class _BleScannerScreenState extends State<BleScannerScreen> {
  List<ScanResult> _devices = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    // Quét các thiết bị có Improv Service UUID
    FlutterBluePlus.startScan(
        withServices: [Guid("00467768-6228-2272-4663-277478268000")], timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _devices = results;
        });
      }
    });

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _openHotspotSetup() {
    FlutterBluePlus.stopScan();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HotspotSetupScreen()));
  }

  /// Improv Wi-Fi needs no device code: pick the gateway, then choose WiFi.
  void _openSetup(ScanResult result, String deviceName) {
    FlutterBluePlus.stopScan();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GatewaySetupScreen(
          qrData: EyerusQrData(version: '', name: deviceName, mac: result.device.remoteId.str),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quét Bluetooth'.tr),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: _devices.isEmpty
          ? Center(
              child: _isScanning
                  ? Text('Đang tìm kiếm Gateway lân cận...'.tr)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Không tìm thấy thiết bị nào.'.tr),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _openHotspotSetup,
                            icon: const Icon(Icons.wifi_tethering_rounded),
                            label: Text('Dùng WiFi dự phòng (Eyerus-Setup)'.tr),
                          ),
                        ],
                      ),
                    ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final result = _devices[index];
                final name = result.advertisementData.advName.isNotEmpty
                    ? result.advertisementData.advName
                    : result.device.platformName;
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(name.isEmpty ? 'Unknown Device' : name),
                  subtitle: Text(result.device.remoteId.str),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSetup(result, name),
                );
              },
            ),
    );
  }
}
