import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../data/gateway_session_store.dart';
import '../../data/gateway_store.dart';
import '../../data/models/eyerus_qr_data.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import '../../widgets/app_ui.dart';

/// WiFi backup onboarding (README_BLE §13 H1) when Bluetooth does not work:
/// the gateway broadcasts `Eyerus-Setup-XXXX` (password `eyerus1234`) after
/// ~1 min without network; the phone joins it and configures the home WiFi
/// through the gateway's local API at `http://10.42.0.1:5050`.
class HotspotSetupScreen extends StatefulWidget {
  final EyerusQrData? qrData;
  const HotspotSetupScreen({super.key, this.qrData});

  @override
  State<HotspotSetupScreen> createState() => _HotspotSetupScreenState();
}

enum _Step { join, loading, pickWifi, sending, done }

class _Net {
  final String ssid;
  final int signal;
  final bool secure;
  const _Net(this.ssid, this.signal, this.secure);
}

class _HotspotSetupScreenState extends State<HotspotSetupScreen> {
  static const hotspotPrefix = 'Eyerus-Setup-';
  static const hotspotPassword = 'eyerus1234';
  static final Uri gatewayBase = Uri.parse('http://10.42.0.1:5050');

  _Step _step = _Step.join;
  String? _error;
  String _busyText = '';
  bool _findingHotspots = false;
  List<String> _hotspots = [];
  bool _forcedWifi = false;

  SavedGateway? _gateway;
  List<_Net> _networks = [];
  _Net? _selected;
  bool _manual = false;
  bool _showPassword = false;
  final _password = TextEditingController();
  final _manualSsid = TextEditingController();
  String _doneMessage = '';

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) _findHotspots();
  }

  @override
  void dispose() {
    _releaseWifi();
    _password.dispose();
    _manualSsid.dispose();
    super.dispose();
  }

  // ── Step 1: get the phone onto the gateway hotspot ─────────────────────

  /// Android only (iOS apps cannot list WiFi networks).
  Future<void> _findHotspots() async {
    setState(() {
      _findingHotspots = true;
      _error = null;
    });
    try {
      await [Permission.location, Permission.nearbyWifiDevices].request();
      final list = await WiFiForIoTPlugin.loadWifiList();
      final names = {
        for (final n in list)
          if ((n.ssid ?? '').startsWith(hotspotPrefix)) n.ssid!,
      }.toList()
        ..sort();
      // Put the one matching this gateway's label first when we know it.
      final hints = _labelSuffixes();
      bool mine(String n) => hints.any((h) => n.toUpperCase().endsWith(h));
      names.sort((a, b) => (mine(b) ? 1 : 0) - (mine(a) ? 1 : 0));
      if (mounted) setState(() => _hotspots = names);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không dò được WiFi: {e}'.trArgs({'e': e}));
    } finally {
      if (mounted) setState(() => _findingHotspots = false);
    }
  }

  /// Likely hotspot suffixes for the scanned label: the BLE name uses the
  /// Bluetooth MAC (Eyerus-8C09), the hotspot the WiFi MAC, which is 1 lower
  /// on the Radxa (Eyerus-Setup-8C08). Only used to sort the list.
  List<String> _labelSuffixes() {
    final name = widget.qrData?.name ?? '';
    final i = name.lastIndexOf('-');
    final v = i >= 0 ? int.tryParse(name.substring(i + 1), radix: 16) : null;
    if (v == null) return const [];
    String hex(int x) => (x & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return [hex(v - 1), hex(v)];
  }

  Future<void> _joinHotspot(String ssid) async {
    setState(() {
      _step = _Step.loading;
      _busyText = 'Đang vào WiFi {ssid}…'.trArgs({'ssid': ssid});
      _error = null;
    });
    final ok = await WiFiForIoTPlugin.connect(
      ssid,
      password: hotspotPassword,
      security: NetworkSecurity.WPA,
      joinOnce: true,
      withInternet: false,
    );
    if (!ok) {
      if (mounted) {
        setState(() {
          _step = _Step.join;
          _error = 'Không vào được {ssid}. Thử vào thủ công trong Cài đặt WiFi.'.trArgs({'ssid': ssid});
        });
      }
      return;
    }
    await _openGateway();
  }

  /// The hotspot has no internet: Android would send our requests over mobile
  /// data. Bind the app to WiFi while talking to 10.42.0.1.
  Future<void> _bindWifi() async {
    if (!Platform.isAndroid) return;
    try {
      _forcedWifi = await WiFiForIoTPlugin.forceWifiUsage(true);
    } catch (_) {}
  }

  Future<void> _releaseWifi() async {
    if (!_forcedWifi) return;
    _forcedWifi = false;
    try {
      await WiFiForIoTPlugin.forceWifiUsage(false);
    } catch (_) {}
  }

  // ── Step 2: talk to the gateway on the hotspot ─────────────────────────

  Future<dynamic> _get(String path, {Duration timeout = const Duration(seconds: 8)}) async {
    final r = await http.get(gatewayBase.resolve(path)).timeout(timeout);
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400 || (j is Map && j['success'] == false)) {
      throw Exception(j is Map ? (j['error'] ?? 'HTTP ${r.statusCode}') : 'HTTP ${r.statusCode}');
    }
    return j;
  }

  Future<void> _openGateway() async {
    setState(() {
      _step = _Step.loading;
      _busyText = 'Đang tìm Gateway tại 10.42.0.1…'.tr;
      _error = null;
    });
    await _bindWifi();

    // The WiFi link needs a few seconds after joining: retry up to ~20 s.
    Object? lastError;
    for (var i = 0; i < 10; i++) {
      try {
        final h = await _get('/api/health', timeout: const Duration(seconds: 3));
        if (h is Map && h['status'] == 'ok') {
          lastError = null;
          break;
        }
      } catch (e) {
        lastError = e;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (lastError != null) {
      if (mounted) {
        setState(() {
          _step = _Step.join;
          _error = 'Chưa thấy Gateway. Kiểm tra điện thoại đang ở WiFi {prefix}XXXX.'.trArgs({'prefix': hotspotPrefix});
        });
      }
      return;
    }

    // Remember the gateway now: the hotspot disappears once it joins the home WiFi.
    try {
      final sys = await _get('/api/system') as Map;
      final gw = (sys['gateway'] as Map?) ?? const {};
      final id = '${gw['gateway_id'] ?? ''}';
      if (id.isNotEmpty) {
        _gateway = SavedGateway(id, '${gw['gateway_name'] ?? ''}', '', '${gw['hostname'] ?? ''}');
        await GatewayStore().save(_gateway!);
      }
    } catch (_) {
      // Older firmware: setup still works, the gateway is found later by the user.
    }
    await _scanWifi();
  }

  Future<void> _scanWifi() async {
    setState(() {
      _step = _Step.loading;
      _busyText = 'Gateway đang quét WiFi xung quanh (5–30 giây)…'.tr;
      _error = null;
    });
    try {
      final j = await _get('/api/wifi/scan?rescan=1', timeout: const Duration(seconds: 60)) as Map;
      final byName = <String, _Net>{};
      for (final n in (j['data'] as List? ?? const []).cast<Map>()) {
        final ssid = '${n['ssid'] ?? ''}'.trim();
        if (ssid.isEmpty || ssid.startsWith(hotspotPrefix)) continue;
        final sec = '${n['security'] ?? ''}'.trim();
        final net = _Net(ssid, (n['signal'] as num?)?.toInt() ?? 0, sec.isNotEmpty && sec != '--' && sec != 'NO');
        if ((byName[ssid]?.signal ?? -1) < net.signal) byName[ssid] = net;
      }
      if (!mounted) return;
      setState(() {
        _networks = byName.values.toList()..sort((a, b) => b.signal.compareTo(a.signal));
        _manual = _networks.isEmpty;
        _step = _Step.pickWifi;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.pickWifi;
        _manual = true;
        _error = 'Không quét được WiFi ({e}). Có thể nhập tên WiFi thủ công.'
            .trArgs({'e': '$e'.replaceFirst('Exception: ', '')});
      });
    }
  }

  // ── Step 3: send the home WiFi ─────────────────────────────────────────

  String get _ssid => _manual ? _manualSsid.text.trim() : (_selected?.ssid ?? '');
  bool get _needsPassword => _manual || (_selected?.secure ?? true);

  Future<void> _send() async {
    final ssid = _ssid;
    final pass = _needsPassword ? _password.text : '';
    if (ssid.isEmpty) return;
    if (pass.isNotEmpty && pass.length < 8) {
      setState(() => _error = 'Mật khẩu WiFi cần ít nhất 8 ký tự'.tr);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = _Step.sending;
      _error = null;
    });

    // Joining the home WiFi takes the hotspot down under our feet, so a
    // dropped request here usually means "switching" rather than failure.
    var dropped = false;
    try {
      final r = await http
          .post(gatewayBase.resolve('/api/wifi/connect'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'ssid': ssid, 'password': pass, 'hidden': _manual}))
          .timeout(const Duration(seconds: 60));
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode >= 400 || (j is Map && j['success'] == false && j['pending'] != true)) {
        throw Exception(j is Map ? (j['error'] ?? 'HTTP ${r.statusCode}') : 'HTTP ${r.statusCode}');
      }
      if (j is Map && j['pending'] == true) dropped = !await _waitConnected(ssid);
    } on SocketException {
      dropped = true;
    } on TimeoutException {
      dropped = true;
    } on http.ClientException {
      dropped = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.pickWifi;
        _error = 'Lỗi gửi WiFi: {e}'.trArgs({'e': '$e'.replaceFirst('Exception: ', '')});
      });
      return;
    }
    await _finish(ssid, dropped);
  }

  /// `pending: true` → poll `/api/wifi/status` until last_connect settles.
  /// Returns false when the hotspot went away before we could tell.
  Future<bool> _waitConnected(String ssid) async {
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 2));
      try {
        final st = ((await _get('/api/wifi/status', timeout: const Duration(seconds: 3)))['data'] as Map?) ?? {};
        final last = (st['last_connect'] as Map?) ?? {};
        if (last['ssid'] == ssid && last['state'] == 'connected') return true;
        if (last['ssid'] == ssid && last['state'] == 'failed') {
          throw Exception('Gateway không vào được "{ssid}". Kiểm tra lại mật khẩu.'.trArgs({'ssid': ssid}));
        }
      } on SocketException {
        return false;
      } on TimeoutException {
        return false;
      }
    }
    return false;
  }

  Future<void> _finish(String ssid, bool unconfirmed) async {
    await _releaseWifi();
    if (Platform.isAndroid) {
      try {
        await WiFiForIoTPlugin.disconnect(); // leave the setup hotspot (joinOnce)
      } catch (_) {}
    }
    setState(() {
      _step = _Step.loading;
      _busyText = 'Điện thoại đang quay lại WiFi nhà và tìm Gateway…'.tr;
    });

    var found = false;
    final gw = _gateway;
    if (gw != null) {
      // Back on the home WiFi: find the gateway by hostname (mDNS) — its IP is new.
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (!found && DateTime.now().isBefore(deadline) && mounted) {
        found = await GatewaySessionStore.instance.ensureConnected(gatewayId: gw.id) != null;
        if (!found) await Future.delayed(const Duration(seconds: 4));
      }
      if (found) await GatewaySessionStore.instance.select(gw.id);
    }
    if (!mounted) return;
    setState(() {
      _step = _Step.done;
      _doneMessage = found
          ? 'Gateway đã vào WiFi "{ssid}" và đã được thêm vào app.'.trArgs({'ssid': ssid})
          : (unconfirmed
              ? 'Đã gửi WiFi "{ssid}" cho Gateway. Nếu đèn Gateway báo đã có mạng là thành công; nếu sau 1 phút Gateway lại phát WiFi {prefix}XXXX thì mật khẩu chưa đúng, làm lại.'
                  .trArgs({'ssid': ssid, 'prefix': hotspotPrefix})
              : 'Gateway đã vào WiFi "{ssid}". Kết nối điện thoại vào cùng WiFi đó để quản lý gateway.'
                  .trArgs({'ssid': ssid}));
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Cài đặt qua WiFi dự phòng'.tr,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: switch (_step) {
            _Step.join => _joinStep(),
            _Step.loading => _loading(_busyText),
            _Step.pickWifi || _Step.sending => _pickStep(),
            _Step.done => _doneStep(),
          },
        ),
      ),
    ));
  }

  List<Widget> _joinStep() => [
        _infoCard(
          icon: Icons.wifi_tethering_rounded,
          title: 'Bước 1: Vào WiFi cài đặt của Gateway'.tr,
          body: 'Gateway không có mạng khoảng 1 phút sẽ tự phát WiFi {prefix}XXXX, mật khẩu {pass}.'
              .trArgs({'prefix': hotspotPrefix, 'pass': hotspotPassword}),
        ),
        const SizedBox(height: 16),
        if (Platform.isAndroid) ...[
          Row(
            children: [
              Expanded(
                child: Text('WiFi Gateway tìm thấy'.tr,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ),
              TextButton.icon(
                onPressed: _findingHotspots ? null : _findHotspots,
                icon: _findingHotspots
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text('Dò lại'.tr),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ],
          ),
          if (_hotspots.isEmpty && !_findingHotspots)
            _hint('Chưa thấy WiFi {prefix}XXXX. Chờ thêm khoảng 1 phút sau khi Gateway mất mạng rồi bấm "Dò lại".'
                .trArgs({'prefix': hotspotPrefix})),
          for (final ssid in _hotspots)
            Card(
              color: AppColors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.divider),
              ),
              child: ListTile(
                leading: Icon(Icons.router_rounded, color: AppColors.info),
                title: Text(ssid, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                subtitle: Text('Bấm để tự kết nối'.tr, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                onTap: () => _joinHotspot(ssid),
              ),
            ),
          const SizedBox(height: 12),
        ] else
          _hint('Mở Cài đặt → WiFi trên iPhone, chọn {prefix}XXXX và nhập mật khẩu {pass}, rồi quay lại app.'
              .trArgs({'prefix': hotspotPrefix, 'pass': hotspotPassword})),
        if (_error != null) ...[const SizedBox(height: 8), _errorBox(_error!)],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _openGateway,
          icon: const Icon(Icons.check_rounded),
          label: Text('Tôi đã vào WiFi này, tiếp tục'.tr),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ];

  List<Widget> _pickStep() {
    final sending = _step == _Step.sending;
    return [
      _infoCard(
        icon: Icons.check_circle_rounded,
        title: 'Đã kết nối Gateway qua WiFi dự phòng'.tr,
        body:
            _gateway == null ? '10.42.0.1' : '${_gateway!.name.isNotEmpty ? _gateway!.name : _gateway!.id} · 10.42.0.1',
        color: AppColors.success,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Text('Bước 2: Chọn WiFi nhà cho Gateway'.tr,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
          TextButton.icon(
            onPressed: sending ? null : _scanWifi,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Quét lại'.tr),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
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
                _netTile(_networks[i], sending),
                if (i != _networks.length - 1) Divider(height: 1, color: AppColors.divider, indent: 52),
              ],
            ],
          ),
        ),
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
      if (_error != null) ...[_errorBox(_error!), const SizedBox(height: 12)],
      FilledButton(
        style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 15)),
        onPressed: sending || _ssid.isEmpty ? null : _send,
        child: sending
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: 10),
                  Text('Đang kết nối WiFi…'.tr),
                ],
              )
            : Text('Kết nối Gateway với WiFi'.tr),
      ),
    ];
  }

  Widget _netTile(_Net n, bool sending) {
    final selected = !_manual && _selected?.ssid == n.ssid;
    // wifi agent reports signal as 0..100 %
    final bars = n.signal >= 75
        ? 4
        : n.signal >= 50
            ? 3
            : n.signal >= 25
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
          style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: AppColors.textPrimary)),
      subtitle: Text('${n.signal}%', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (n.secure) Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, size: 20, color: AppColors.accent)
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

  List<Widget> _doneStep() => [
        const SizedBox(height: 12),
        Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
        const SizedBox(height: 12),
        Text('Hoàn tất'.tr,
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

  List<Widget> _loading(String text) => [
        const SizedBox(height: 48),
        Center(child: CircularProgressIndicator(color: AppColors.accent)),
        const SizedBox(height: 16),
        _hint(text),
      ];

  Widget _infoCard({required IconData icon, required String title, required String body, Color? color}) {
    final c = color ?? AppColors.info;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
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
