import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/gateway_session.dart';
import '../../core/gateway_telemetry.dart';
import '../../data/gateway_session_store.dart';
import '../../data/gateway_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import '../../widgets/prompt_dialog.dart';
import '../../data/auth_store.dart';
import 'demo_gateway_data.dart';
import 'gateway_control_screen.dart';
import 'maintain_web_screen.dart';
import 'stream_push_screen.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/gateway_avatar.dart';

/// Live view of one gateway (README_BLE §5–6, README_INTEGRATION §6):
/// environment (DHT11 temperature/humidity, AGS10 TVOC), CPU/RAM/disk/SoC
/// temperature over SSE, plus camera streams, network and hardware info.
class GatewayDetailScreen extends StatefulWidget {
  final SavedGateway gateway;
  const GatewayDetailScreen({super.key, required this.gateway});

  @override
  State<GatewayDetailScreen> createState() => _GatewayDetailScreenState();
}

class _GatewayDetailScreenState extends State<GatewayDetailScreen> {
  /// 1 sample/s is plenty for a dashboard (sensors refresh every 1–1.5 s anyway).
  static const _intervalMs = 1000;

  final _store = GatewaySessionStore.instance;
  GatewaySession? _session;
  StreamSubscription? _sysSub;
  StreamSubscription? _telSub;
  Timer? _staleTimer;

  bool _connecting = true;
  String? _error;

  /// Set for the placeholder gateways shown before a real one is added.
  DemoGateway? _demo;
  Timer? _demoTimer;

  Map<String, dynamic> _system = const {};
  Map<String, dynamic>? _telemetry;
  DateTime? _lastSample;

  Map<String, dynamic>? _hardware;
  Map<String, dynamic>? _wifi;
  Map<String, dynamic>? _signal;
  List<Map<String, dynamic>>? _cameras;

  @override
  void initState() {
    super.initState();
    _connect();
    // Re-render the "live" dot so it greys out when samples stop arriving.
    _staleTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _staleTimer?.cancel();
    _demoTimer?.cancel();
    _sysSub?.cancel();
    _telSub?.cancel();
    _session?.stop();
    super.dispose();
  }

  /// Feed the page from [DemoGateway] instead of a live SSE session.
  void _startDemo() {
    final demo = _demo ??= DemoGateway(widget.gateway);
    _system = demo.system();
    _hardware = demo.hardware();
    _wifi = demo.wifi();
    _signal = demo.signal();
    _cameras = demo.cameras();
    _telemetry = demo.nextTelemetry();
    _lastSample = DateTime.now();
    _connecting = false;
    _demoTimer ??= Timer.periodic(const Duration(milliseconds: _intervalMs), (_) {
      if (!mounted) return;
      setState(() {
        _telemetry = demo.nextTelemetry();
        _lastSample = DateTime.now();
      });
    });
  }

  Future<void> _connect() async {
    if (DemoGateway.isDemo(widget.gateway.id)) {
      setState(_startDemo);
      return;
    }
    setState(() {
      _connecting = true;
      _error = null;
    });
    final s = await _store.ensureConnected(gatewayId: widget.gateway.id);
    if (!mounted) return;
    if (s == null) {
      setState(() {
        _connecting = false;
        _error = _store.error ?? 'Không kết nối được gateway'.tr;
      });
      return;
    }
    _bind(s);
    setState(() => _connecting = false);
    await _loadDetails();
  }

  void _bind(GatewaySession s) {
    _sysSub?.cancel();
    _telSub?.cancel();
    _session = s;
    _system = s.system ?? const {};
    _telemetry = s.latest;
    _sysSub = s.systemStream.listen((sys) {
      if (mounted) setState(() => _system = sys);
    });
    _telSub = s.telemetryStream.listen((t) {
      if (mounted) {
        setState(() {
          _telemetry = t;
          _lastSample = DateTime.now();
        });
      }
    });
    s.start(intervalMs: _intervalMs);
  }

  /// One-shot REST details. Each call is independent so one failing endpoint
  /// (older firmware) doesn't blank the rest of the page.
  Future<void> _loadDetails() async {
    if (_demo != null) {
      setState(() => _signal = _demo!.signal());
      return;
    }
    final s = _session;
    if (s == null) return;
    Future<T?> safe<T>(Future<T> Function() f) async {
      try {
        return await f();
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([
      safe(s.hardware),
      safe(s.wifiStatus),
      safe(s.signal),
      safe(s.cameras),
    ]);
    if (!mounted) return;
    setState(() {
      _hardware = results[0] as Map<String, dynamic>?;
      _wifi = results[1] as Map<String, dynamic>?;
      _signal = results[2] as Map<String, dynamic>?;
      _cameras = results[3] as List<Map<String, dynamic>>?;
    });
  }

  Future<void> _rename() async {
    final s = _session;
    if (s == null) return;
    final current = _gatewayName;
    final name = await showTextPromptDialog(
      context,
      title: 'Đổi tên Gateway'.tr,
      initialValue: current,
      hint: 'VD: Gateway tầng 1'.tr,
    );
    if (name == null || name == current || !mounted) return;
    try {
      await s.rename(name);
      await GatewayStore().save(widget.gateway.copyWith(name: name));
      await _store.loadSaved();
      if (mounted) {
        setState(() => _system = {
              ..._system,
              'gateway': {...?_map(_system['gateway']), 'gateway_name': name},
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: {e}'.trArgs({'e': e}))));
      }
    }
  }

  // ── derived values ────────────────────────────────────────────────────

  Map<String, dynamic> get _gw => _map(_system['gateway']) ?? const {};

  String get _gatewayName {
    final n = (_gw['gateway_name'] ?? '').toString();
    if (n.isNotEmpty) return _demo != null ? n.tr : n;
    return widget.gateway.name.isNotEmpty ? widget.gateway.name : widget.gateway.id;
  }

  /// Live hardware sample, falling back to the connect-time snapshot.
  Map<String, dynamic> get _hw => _map(_telemetry?['hardware']) ?? _map(_system['status']) ?? const {};

  Map<String, dynamic> get _sensors => _map(_telemetry?['sensors']) ?? _map(_system['sensors']) ?? const {};

  bool get _live => _lastSample != null && DateTime.now().difference(_lastSample!) < const Duration(seconds: 5);

  @override
  Widget build(BuildContext context) {
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(_gatewayName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          if (_session != null)
            IconButton(
              tooltip: 'Điều khiển gateway'.tr,
              icon: const Icon(Icons.tune_rounded),
              onPressed: _openControl,
            ),
          if (_session != null)
            IconButton(
              tooltip: 'Đổi tên Gateway'.tr,
              icon: const Icon(Icons.edit_outlined),
              onPressed: _rename,
            ),
        ],
      ),
      body: _connecting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: 14),
                  Text('Đang kết nối gateway…'.tr, style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _connect)
              : RefreshIndicator(
                  onRefresh: _loadDetails,
                  color: AppColors.accent,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildHeader(),
                      if (_session != null) ...[
                        const SizedBox(height: 12),
                        _buildControlEntry(),
                      ],
                      if (AuthStore.instance.isAdmin) ...[
                        const SizedBox(height: 12),
                        _buildMaintainEntry(),
                      ],
                      const SizedBox(height: 20),
                      _buildEnvironment(),
                      const SizedBox(height: 20),
                      _buildResources(),
                      const SizedBox(height: 20),
                      _buildStreams(),
                      const SizedBox(height: 20),
                      _buildNetwork(),
                      const SizedBox(height: 20),
                      _buildHardwareInfo(),
                    ],
                  ),
                ),
    ));
  }

  Widget _buildHeader() {
    final t = _lastSample;
    final updated = t == null ? 'Đang chờ dữ liệu…'.tr : 'Cập nhật lúc {time}'.trArgs({'time': _hms(t)});
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Tap the photo to change it (gallery, camera or a product photo).
          GestureDetector(
            onTap: () => showGatewayImageSheet(context, widget.gateway),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GatewayAvatar(gateway: widget.gateway, size: 60, radius: 16),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.card, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_gatewayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  [(_gw['ip'] ?? widget.gateway.ip).toString(), (_gw['gateway_id'] ?? widget.gateway.id).toString()]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _live ? AppColors.success : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(updated,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _live ? AppColors.success : AppColors.textMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openControl() async {
    final s = _session;
    if (s == null) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => GatewayControlScreen(session: s)));
    if (mounted) _loadDetails();
  }

  /// Native REST control (RTSP service, camera ping, WiFi, cluster, admin tools).
  Widget _buildControlEntry() {
    return _Card(
      child: ListTile(
        onTap: _openControl,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.tune_rounded, color: AppColors.info),
        ),
        title: Text('Điều khiển gateway'.tr,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        subtitle: Text('Khởi động lại, ping camera, WiFi, Bluetooth, cụm'.tr,
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }

  /// Admin-only: the gateway's own Maintain web (RTSP server, push outputs,
  /// MQTT/Webhook, cluster, logs) embedded instead of rebuilt natively.
  Widget _buildMaintainEntry() {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MaintainWebScreen(gateway: widget.gateway),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.admin_panel_settings_outlined, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bảo trì nâng cao'.tr,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('Web quản trị: RTSP, đẩy luồng, MQTT, Webhook, nhật ký'.tr,
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child:
                    Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  // ── Môi trường ────────────────────────────────────────────────────────

  Widget _buildEnvironment() {
    final sensors = _sensors;
    final dhtRaw = _map(sensors['dht11']);
    final agsRaw = _map(sensors['ags10']);
    final dht = decodeDht11(dhtRaw?['raw']?.toString());
    final tvoc = decodeAgs10(agsRaw?['raw']?.toString());
    final available = sensors['available'] != false && (dhtRaw != null || agsRaw != null);

    if (!available) {
      return _Section(
        title: 'Môi trường'.tr,
        child: _Card(
          padding: const EdgeInsets.all(16),
          child:
              Text('Gateway chưa gửi dữ liệu cảm biến.'.tr, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      );
    }

    final (aqLabel, aqColor) = tvoc == null ? ('--', AppColors.textMuted) : _airQuality(airQualityFromTvoc(tvoc));

    return _Section(
      title: 'Môi trường'.tr,
      trailing: _sensorStatus(dhtRaw, agsRaw),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.thermostat_rounded,
                  color: dht == null ? AppColors.textMuted : _tempColor(dht.temperature, warn: 32, bad: 38),
                  label: 'Nhiệt độ'.tr,
                  value: dht == null ? '--' : dht.temperature.toStringAsFixed(1),
                  unit: '°C',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.water_drop_rounded,
                  color: AppColors.info,
                  label: 'Độ ẩm'.tr,
                  value: dht == null ? '--' : dht.humidity.toStringAsFixed(1),
                  unit: '%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricTile(
            icon: Icons.air_rounded,
            color: aqColor,
            label: 'Chất lượng không khí (TVOC)'.tr,
            value: tvoc == null ? '--' : '$tvoc',
            unit: 'ppb',
            badge: aqLabel,
          ),
        ],
      ),
    );
  }

  Widget? _sensorStatus(Map<String, dynamic>? dht, Map<String, dynamic>? ags) {
    final bad = [
      if (dht != null && dht['status'] != null && dht['status'] != 'ok') 'DHT11',
      if (ags != null && ags['status'] != null && ags['status'] != 'ok') 'AGS10',
    ];
    if (bad.isEmpty) return null;
    return Text('Lỗi cảm biến: {names}'.trArgs({'names': bad.join(', ')}),
        style: TextStyle(fontSize: 11.5, color: AppColors.warning, fontWeight: FontWeight.w600));
  }

  (String, Color) _airQuality(AirQuality q) => switch (q) {
        AirQuality.good => ('Tốt'.tr, AppColors.success),
        AirQuality.moderate => ('Trung bình'.tr, AppColors.info),
        AirQuality.poor => ('Kém'.tr, AppColors.warning),
        AirQuality.veryPoor => ('Rất kém'.tr, AppColors.danger),
        AirQuality.hazardous => ('Nguy hại'.tr, AppColors.danger),
      };

  // ── Tài nguyên ────────────────────────────────────────────────────────

  Widget _buildResources() {
    final hw = _hw;
    final cpu = _num(hw['cpu_percent']);
    final socTemp = _num(hw['cpu_temperature_c']);
    final freq = _num(hw['cpu_freq_mhz']);
    final load = _num(hw['load_1m']);
    final ramPct = _num(hw['ram_percent']);
    final ramUsed = _num(hw['ram_used_mb']);
    final ramTotal = _num(hw['ram_total_mb']) ?? _num(_map(_hardware?['memory'])?['total_mb']);
    final diskPct = _num(hw['disk_percent']);
    final diskUsed = _num(hw['disk_used_gb']);
    final diskTotal = _num(hw['disk_total_gb']) ?? _num(_map(_hardware?['storage'])?['total_gb']);
    final cores = (hw['cpu_per_core'] as List?)?.map(_num).whereType<double>().toList() ?? const <double>[];

    return _Section(
      title: 'Tài nguyên hệ thống'.tr,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.memory_rounded,
                  color: _pctColor(cpu),
                  label: 'CPU',
                  value: cpu == null ? '--' : cpu.toStringAsFixed(1),
                  unit: '%',
                  footnote: [
                    if (freq != null) '${freq.round()} MHz',
                    if (load != null) 'load ${load.toStringAsFixed(2)}',
                  ].join(' · '),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.device_thermostat_rounded,
                  color: socTemp == null ? AppColors.textMuted : _tempColor(socTemp, warn: 70, bad: 85),
                  label: 'Nhiệt độ chip'.tr,
                  value: socTemp == null ? '--' : socTemp.toStringAsFixed(1),
                  unit: '°C',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Column(
              children: [
                _UsageBar(
                  icon: Icons.sd_storage_outlined,
                  label: 'RAM',
                  percent: ramPct,
                  detail: ramUsed == null || ramTotal == null
                      ? null
                      : '${_gb(ramUsed / 1024)} / ${_gb(ramTotal / 1024)} GB',
                ),
                _UsageBar(
                  icon: Icons.storage_rounded,
                  label: 'Bộ nhớ'.tr,
                  percent: diskPct,
                  detail: diskUsed == null || diskTotal == null ? null : '${_gb(diskUsed)} / ${_gb(diskTotal)} GB',
                ),
              ],
            ),
          ),
          if (cores.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tải từng lõi CPU'.tr,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < cores.length; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: FractionallySizedBox(
                                        heightFactor: (cores[i] / 100).clamp(0.04, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _pctColor(cores[i]),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('$i', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Luồng camera ──────────────────────────────────────────────────────

  Widget _buildStreams() {
    final st = _map(_system['streams']) ?? const {};
    final rtt = <String, double>{
      for (final c in (_signal?['cameras'] as List? ?? const []))
        if (c is Map && _num(c['rtt_ms']) != null) '${c['mount']}': _num(c['rtt_ms'])!,
    };

    return _Section(
      title: 'Luồng camera'.tr,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _CountTile(label: 'Đã cấu hình'.tr, value: st['cameras_total'])),
              const SizedBox(width: 10),
              Expanded(child: _CountTile(label: 'Đang bật'.tr, value: st['cameras_enabled'])),
              const SizedBox(width: 10),
              Expanded(child: _CountTile(label: 'Đang phát'.tr, value: st['routes_ready'], color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _CountTile(label: 'Đích đẩy luồng'.tr, value: st['push_outputs'])),
              const SizedBox(width: 10),
              Expanded(child: _CountTile(label: 'Đang đẩy'.tr, value: st['push_running'], color: AppColors.success)),
              const SizedBox(width: 10),
              Expanded(child: _CountTile(label: 'Cổng RTSP'.tr, value: st['rtsp_port'])),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(Icons.cloud_upload_outlined, color: AppColors.accent),
              title: Text('Quản lý đẩy luồng'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              subtitle: Text('Tự động đẩy lên media server, bật/tắt từng camera, thêm URL khác'.tr,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => StreamPushScreen(gateway: widget.gateway),
                ));
                if (mounted) _loadDetails();
              },
            ),
          ),
          if (_cameras != null && _cameras!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                children: [
                  for (var i = 0; i < _cameras!.length; i++) ...[
                    _cameraRow(_cameras![i], rtt),
                    if (i != _cameras!.length - 1)
                      Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cameraRow(Map<String, dynamic> c, Map<String, double> rtt) {
    final mount = (c['mount'] ?? '').toString();
    final enabled = c['enabled'] != false;
    final online = c['online'] == true;
    final (color, label) = !enabled
        ? (AppColors.textMuted, 'Tắt'.tr)
        : online
            ? (AppColors.success, 'Online')
            : (AppColors.danger, c['status'] == 'error' ? 'Lỗi tài khoản/cổng'.tr : 'Offline');
    final model = [c['manufacturer'], c['model']].where((v) => v != null && '$v'.isNotEmpty).join(' ');
    final ping = rtt[mount];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Icon(Icons.videocam_outlined, size: 19, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mount,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(
                  [c['host'], if (model.isNotEmpty) model, if (ping != null) '${ping.toStringAsFixed(1)} ms']
                      .where((v) => v != null && '$v'.isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ── Mạng ──────────────────────────────────────────────────────────────

  Widget _buildNetwork() {
    final wifi = _wifi;
    final sigWifi = _map(_signal?['wifi']);
    // Hide virtual links (docker0, veth*, lo) — only physical ports matter here.
    final ifaces = (_hardware?['network_interfaces'] as List? ?? const [])
        .whereType<Map>()
        .where((i) => !RegExp(r'^(docker|veth|br-|lo$)').hasMatch('${i['interface']}'))
        .toList();
    final rows = <(String, String)>[
      if (wifi != null && wifi['available'] != false) ...[
        ('WiFi', wifi['connected'] == true ? (wifi['ssid'] ?? '--').toString() : 'Chưa kết nối'.tr),
        if (wifi['signal'] != null)
          (
            'Tín hiệu WiFi'.tr,
            [
              '${wifi['signal']}%',
              if (sigWifi?['level_dbm'] != null) '${sigWifi!['level_dbm']} dBm',
            ].join(' · ')
          ),
        if ((wifi['ip'] ?? '').toString().isNotEmpty) ('IP WiFi', wifi['ip'].toString()),
      ],
      for (final i in ifaces)
        (
          '${i['interface']}',
          [i['ip'], i['mac'], i['state']].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
        ),
      ('Hostname', (_gw['hostname'] ?? widget.gateway.hostname).toString()),
      if (_gw['http_port'] != null) ('Cổng HTTP'.tr, '${_gw['http_port']}'),
    ];
    return _Section(title: 'Mạng'.tr, child: _KeyValueCard(rows: rows));
  }

  // ── Phần cứng ─────────────────────────────────────────────────────────

  Widget _buildHardwareInfo() {
    final h = _map(_system['hardware']) ?? const {};
    final board = _map(_hardware?['board']);
    final uptime = _num(board?['uptime_seconds']);
    final cores = h['cpu_cores'];
    final threads = h['cpu_threads'];
    final maxFreq = _num(h['cpu_max_freq_mhz']);
    final rows = <(String, String)>[
      if (h['board'] != null) ('Bo mạch'.tr, '${h['board']}'),
      if (h['processor'] != null) ('Vi xử lý'.tr, '${h['processor']}'),
      if (cores != null)
        (
          'Lõi / luồng CPU'.tr,
          '$cores / ${threads ?? cores}${maxFreq == null ? '' : ' · ${maxFreq.round()} MHz'}',
        ),
      if (h['os'] != null) ('Hệ điều hành'.tr, '${h['os']}'),
      if (h['kernel'] != null) ('Kernel', '${h['kernel']}'),
      if (h['serial'] != null) ('Serial', '${h['serial']}'),
      if (uptime != null) ('Thời gian hoạt động'.tr, _uptime(uptime.round())),
      if (_gw['cluster_id'] != null) ('Cluster', '${_gw['cluster_id']}'),
      if (_gw['zone'] != null) ('Zone', '${_gw['zone']}'),
      if (_system['version'] != null) ('Phiên bản API'.tr, '${_system['version']}'),
    ];
    return _Section(title: 'Phần cứng'.tr, child: _KeyValueCard(rows: rows));
  }

  // ── helpers ───────────────────────────────────────────────────────────

  static Map<String, dynamic>? _map(dynamic v) => v is Map ? v.cast<String, dynamic>() : null;
  static double? _num(dynamic v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
  static String _gb(double v) => v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  static String _hms(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  static String _uptime(int s) {
    final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60;
    if (d > 0) return '{d} ngày {h} giờ'.trArgs({'d': d, 'h': h});
    if (h > 0) return '{h} giờ {m} phút'.trArgs({'h': h, 'm': m});
    return '{m} phút'.trArgs({'m': m});
  }

  static Color _pctColor(double? p) {
    if (p == null) return AppColors.textMuted;
    if (p < 60) return AppColors.success;
    if (p < 85) return AppColors.warning;
    return AppColors.danger;
  }

  static Color _tempColor(double t, {required double warn, required double bad}) {
    if (t < warn) return AppColors.success;
    if (t < bad) return AppColors.warning;
    return AppColors.danger;
  }
}

// ── building blocks ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(title.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: child,
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String? badge;
  final String? footnote;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    this.badge,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration:
                      BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(badge!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(width: 3),
              Text(unit, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ],
          ),
          if (footnote != null && footnote!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(footnote!, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? percent;
  final String? detail;

  const _UsageBar({required this.icon, required this.label, required this.percent, this.detail});

  @override
  Widget build(BuildContext context) {
    final p = percent;
    final color = _GatewayDetailScreenState._pctColor(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              if (detail != null) Text(detail!, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Text(p == null ? '--' : '${p.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p == null ? 0 : (p / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.divider,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color? color;
  const _CountTile({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Text(value == null ? '--' : '$value',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color ?? AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _KeyValueCard extends StatelessWidget {
  final List<(String, String)> rows;
  const _KeyValueCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return _Card(
        padding: const EdgeInsets.all(16),
        child: Text('Chưa có dữ liệu'.tr, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      );
    }
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(rows[i].$1, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: SelectableText(rows[i].$2,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1) Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

/// Marks pages fed by [DemoGateway] so nobody mistakes them for live data.

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Thử lại'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
