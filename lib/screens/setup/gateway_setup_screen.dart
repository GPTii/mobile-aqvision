import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../core/ble_setup_service.dart';
import '../../core/gateway_lan_finder.dart';
import '../../core/gateway_session.dart';
import '../../data/auth_store.dart';
import '../../data/gateway_session_store.dart';
import '../../data/models/eyerus_ble_models.dart';
import '../../data/models/eyerus_qr_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import 'hotspot_setup_screen.dart';
import '../../widgets/app_ui.dart';

/// BLE onboarding (Improv Wi-Fi, README_BLE §3): connect → scan nearby WiFi
/// right away (scanning needs no authorization) → pick a network → send.
/// No code / PIN / pre-authorization step. Only if the gateway itself refuses
/// the WiFi settings (error 0x04, gateway already online) the user is asked to
/// press its button, and the send is retried automatically.
class GatewaySetupScreen extends StatefulWidget {
  final EyerusQrData qrData;
  const GatewaySetupScreen({super.key, required this.qrData});

  @override
  State<GatewaySetupScreen> createState() => _GatewaySetupScreenState();
}

enum _Phase { connecting, scanning, ready, sending, done, failed }

class _GatewaySetupScreenState extends State<GatewaySetupScreen> {
  final BleSetupService _ble = BleSetupService();
  final _password = TextEditingController();
  final _manualSsid = TextEditingController();

  _Phase _phase = _Phase.connecting;
  String? _error;
  int? _improvState;
  List<EyerusBleNetwork> _networks = [];
  EyerusBleNetwork? _selected;
  bool _manual = false;
  bool _showPassword = false;
  bool _waitingButton = false;
  String _doneMessage = '';

  StreamSubscription<int>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _ble.stateStream.stream.listen((s) {
      if (mounted) setState(() => _improvState = s);
    });
    _connect();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _ble.disconnect();
    _password.dispose();
    _manualSsid.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _phase = _Phase.connecting;
      _error = null;
    });
    try {
      if (!_ble.isConnected) await _ble.connectToDevice(widget.qrData.bleTarget);
      await _scan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = 'Lỗi kết nối: {e}'.trArgs({'e': _clean(e)});
      });
    }
  }

  Future<void> _scan() async {
    setState(() {
      _phase = _Phase.scanning;
      _error = null;
    });
    try {
      final nets = await _ble.scanWifi();
      if (!mounted) return;
      setState(() {
        _networks = [
          for (final e in nets)
            EyerusBleNetwork.fromJson({
              'ssid': e[0],
              'signal': int.tryParse(e.length > 1 ? e[1] : '') ?? 0,
              'secure': e.length > 2 && e[2] != 'NO',
            }),
        ];
        if (_selected != null && !_networks.any((n) => n.ssid == _selected!.ssid)) _selected = null;
        _manual = _networks.isEmpty;
        _phase = _Phase.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _manual = true;
        _error = e is FlutterBluePlusException
            ? _gattHint
            : 'Không quét được WiFi ({e}). Có thể nhập tên WiFi thủ công.'.trArgs({'e': _clean(e)});
      });
    }
  }

  String get _ssid => _manual ? _manualSsid.text.trim() : (_selected?.ssid ?? '');
  bool get _needsPassword => _manual || (_selected?.secure ?? true);

  Future<void> _send() async {
    final ssid = _ssid;
    final pass = _needsPassword ? _password.text : '';
    if (ssid.isEmpty) {
      setState(() => _error = 'Chọn hoặc nhập tên WiFi'.tr);
      return;
    }
    if (pass.isNotEmpty && pass.length < 8) {
      setState(() => _error = 'Mật khẩu WiFi cần ít nhất 8 ký tự'.tr);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _phase = _Phase.sending;
      _error = null;
      _waitingButton = false;
    });

    String url;
    try {
      url = await _sendWithButtonRetry(ssid, pass);
    } catch (e) {
      // A BLE error does not mean the WiFi was not applied: the gateway may be
      // online already. Look for it on the LAN before reporting a failure.
      if (e is! ImprovError && await _findOnLan()) return;
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _waitingButton = false;
        _error = e is ImprovError && e.code == 0x03
            ? 'Gateway không vào được "{ssid}". Kiểm tra lại mật khẩu.'.trArgs({'ssid': ssid})
            : e is FlutterBluePlusException
                ? _gattHint
                : 'Lỗi gửi WiFi: {e}'.trArgs({'e': _clean(e)});
      });
      return;
    }

    // WiFi is set: the rest (LAN session, cloud) is best effort.
    await _afterProvisioned(url);
  }

  /// Sends the WiFi settings. A gateway that is already online answers 0x04
  /// (not authorized) until its button is pressed: wait for AUTHORIZED, retry once.
  Future<String> _sendWithButtonRetry(String ssid, String pass) async {
    try {
      return await _ble.sendWifi(ssid, pass);
    } on ImprovError catch (e) {
      if (e.code != 0x04) rethrow;
    }
    if (mounted) setState(() => _waitingButton = true);
    if (_improvState != 0x02) {
      await _ble.stateStream.stream.firstWhere((s) => s == 0x02).timeout(
            const Duration(seconds: 90),
            onTimeout: () => throw Exception('Hết thời gian chờ nhấn nút trên Gateway'.tr),
          );
    }
    if (mounted) setState(() => _waitingButton = false);
    return _ble.sendWifi(ssid, pass);
  }

  Future<void> _afterProvisioned(String url) async {
    var message = 'Gateway đã kết nối WiFi thành công.'.tr;
    if (url.isNotEmpty) {
      try {
        // Phone must be on the same network to reach the gateway (§4).
        final session = await GatewaySession.afterProvisioning(url).timeout(const Duration(seconds: 70));
        await GatewaySessionStore.instance.adopt(session);
        final gw = (session.system?['gateway'] as Map?) ?? const {};
        unawaited(_registerCloud(url, (gw['gateway_id'] ?? '').toString()));
        message = 'Gateway đã vào mạng và đã được thêm vào app ({url}).'.trArgs({'url': url});
      } catch (_) {
        message =
            'Gateway đã vào mạng ({url}). Kết nối điện thoại vào cùng WiFi đó để quản lý gateway.'.trArgs({'url': url});
      }
    }
    if (!mounted) return;
    setState(() {
      _phase = _Phase.done;
      _doneMessage = message;
    });
  }

  /// BLE fallback: look for the just-provisioned gateway on the phone's LAN.
  /// Returns true when it was reached and added to the app.
  Future<bool> _findOnLan() async {
    if (!mounted) return false;
    setState(() => _phase = _Phase.sending);
    // The gateway needs a few seconds to join the WiFi and start its web server.
    String? url;
    for (var i = 0; i < 3 && url == null && mounted; i++) {
      await Future.delayed(const Duration(seconds: 8));
      url = await findNewGatewayOnLan(labelName: widget.qrData.name, mac: widget.qrData.mac);
    }
    if (url == null) return false;
    try {
      final session = await GatewaySession.afterProvisioning(url).timeout(const Duration(seconds: 45));
      await GatewaySessionStore.instance.adopt(session);
      final gw = (session.system?['gateway'] as Map?) ?? const {};
      unawaited(_registerCloud(url, (gw['gateway_id'] ?? '').toString()));
      if (!mounted) return true;
      setState(() {
        _phase = _Phase.done;
        _doneMessage = 'Gateway đã vào mạng và đã được thêm vào app ({url}).'.trArgs({'url': url});
      });
      return true;
    } catch (e) {
      debugPrint('[SETUP] LAN fallback $url failed: $e');
      return false;
    }
  }

  /// Non-blocking: LAN control works without it (endpoint not deployed yet).
  Future<void> _registerCloud(String url, String gatewayId) async {
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.apiV1Base}/gateways/register'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${AuthStore.instance.token ?? ''}',
            },
            body: jsonEncode({
              'deviceId': widget.qrData.deviceId,
              'labelGatewayId': widget.qrData.gatewayId,
              'name': widget.qrData.name,
              'mac': widget.qrData.mac,
              'localIp': url,
              'gatewayId': gatewayId,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[SETUP] cloud register failed: $e');
    }
  }

  static String _clean(Object e) => '$e'.replaceFirst('Exception: ', '');

  /// GATT errors (e.g. android-code 14 GATT_UNLIKELY) come from the gateway's
  /// Bluetooth service refusing the command — not from the phone.
  static String get _gattHint =>
      'Gateway không nhận lệnh qua Bluetooth. Rút điện gateway khoảng 10 giây rồi cắm lại và thử lại, hoặc bấm "Dùng WiFi dự phòng".'
          .tr;

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final name = widget.qrData.name.isNotEmpty ? widget.qrData.name : widget.qrData.mac;
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Cài đặt Gateway'.tr,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _deviceCard(name),
            const SizedBox(height: 16),
            ..._body(),
          ],
        ),
      ),
    ));
  }

  Widget _deviceCard(String name) {
    final (label, color) = switch (_phase) {
      _Phase.connecting => ('Đang kết nối Bluetooth…'.tr, AppColors.info),
      _Phase.failed => ('Chưa kết nối'.tr, AppColors.danger),
      _ => ('Đã kết nối Bluetooth'.tr, AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: AppColors.info.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.router_rounded, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
          if (_phase == _Phase.connecting)
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
        ],
      ),
    );
  }

  List<Widget> _body() {
    switch (_phase) {
      case _Phase.connecting:
        return [_hint('Đang tìm và kết nối Gateway qua Bluetooth. Để điện thoại gần Gateway.'.tr)];
      case _Phase.failed:
        return [
          _errorBox(_error ?? ''),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: _connect,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Thử lại'.tr),
          ),
          const SizedBox(height: 10),
          _hotspotButton(),
        ];
      case _Phase.scanning:
        return [
          const SizedBox(height: 24),
          Center(child: CircularProgressIndicator(color: AppColors.accent)),
          const SizedBox(height: 14),
          _hint('Gateway đang quét WiFi xung quanh (5–30 giây)…'.tr),
        ];
      case _Phase.done:
        return [
          const SizedBox(height: 12),
          Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
          const SizedBox(height: 12),
          Text('Thiết lập thành công!'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _hint(_doneMessage),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Xong'.tr),
          ),
        ];
      case _Phase.ready:
      case _Phase.sending:
        return _wifiForm();
    }
  }

  List<Widget> _wifiForm() {
    final sending = _phase == _Phase.sending;
    return [
      Row(
        children: [
          Expanded(
            child: Text('Chọn WiFi cho Gateway'.tr,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          TextButton.icon(
            onPressed: sending ? null : _scan,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Quét lại'.tr),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (_networks.isNotEmpty)
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.cardRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _networks.length; i++) ...[
                _networkTile(_networks[i], sending),
                if (i != _networks.length - 1) Divider(height: 1, color: AppColors.divider, indent: 52),
              ],
            ],
          ),
        )
      else
        _hint('Không tìm thấy WiFi nào. Bấm "Quét lại" hoặc nhập tên WiFi thủ công.'.tr),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: sending ? null : () => setState(() => _manual = !_manual),
          child: Text(_manual ? 'Chọn từ danh sách'.tr : 'Nhập tên WiFi thủ công (mạng ẩn)'.tr,
              style: TextStyle(color: AppColors.accent)),
        ),
      ),
      if (_manual) ...[
        TextField(
          controller: _manualSsid,
          enabled: !sending,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: _decoration('Tên WiFi (SSID)'.tr),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
      ],
      if (_needsPassword && (_manual || _selected != null)) ...[
        TextField(
          controller: _password,
          enabled: !sending,
          obscureText: !_showPassword,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: _decoration('Mật khẩu WiFi'.tr).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
          onSubmitted: (_) => _send(),
        ),
        const SizedBox(height: 12),
      ],
      if (_waitingButton)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gateway đang có mạng nên cần xác nhận: nhấn nhanh nút trên Gateway, app sẽ tự gửi lại.'.tr,
                  style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      if (_error != null) ...[_errorBox(_error!), const SizedBox(height: 12)],
      if (_error != null && _networks.isEmpty && !sending) ...[_hotspotButton(), const SizedBox(height: 12)],
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onPressed: sending || _ssid.isEmpty ? null : _send,
        child: sending
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: 10),
                  Text(_waitingButton ? 'Đang chờ nhấn nút…'.tr : 'Đang kết nối WiFi…'.tr),
                ],
              )
            : Text('Kết nối Gateway với WiFi'.tr),
      ),
    ];
  }

  Widget _networkTile(EyerusBleNetwork n, bool sending) {
    final selected = !_manual && _selected?.ssid == n.ssid;
    // RSSI dBm -> 1..4 bars
    final bars = n.signal >= -55
        ? 4
        : n.signal >= -67
            ? 3
            : n.signal >= -78
                ? 2
                : 1;
    final icon = [
      Icons.wifi_1_bar_rounded,
      Icons.wifi_2_bar_rounded,
      Icons.network_wifi_3_bar_rounded,
      Icons.wifi_rounded
    ][bars - 1];
    return ListTile(
      enabled: !sending,
      leading: Icon(icon, color: selected ? AppColors.accent : AppColors.textSecondary),
      title: Text(n.ssid,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textPrimary,
          )),
      subtitle: Text('${n.signal} dBm', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (n.secure) Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, size: 20, color: AppColors.accent),
          ],
        ],
      ),
      onTap: () => setState(() {
        _manual = false;
        _selected = n;
        _error = null;
      }),
    );
  }

  /// Bluetooth not working: configure through the gateway's setup hotspot.
  Widget _hotspotButton() => OutlinedButton.icon(
        onPressed: () {
          _ble.disconnect();
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => HotspotSetupScreen(qrData: widget.qrData),
          ));
        },
        icon: const Icon(Icons.wifi_tethering_rounded),
        label: Text('Dùng WiFi dự phòng (Eyerus-Setup)'.tr),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(text,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
      );

  Widget _errorBox(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.4)),
      );
}
