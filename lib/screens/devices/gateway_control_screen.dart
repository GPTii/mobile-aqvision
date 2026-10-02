import 'package:flutter/material.dart';

import '../../core/gateway_session.dart';
import '../../data/auth_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import '../../widgets/prompt_dialog.dart';
import '../../widgets/app_ui.dart';

/// Remote control of one gateway over its local REST API
/// (TaiLieuTichHop §4.2): RTSP service, camera ping, WiFi / Bluetooth,
/// cluster identity and — admin only — MQTT, Webhook and logs.
///
/// Admin features follow §4.2 "Phân quyền trên UI app": hidden unless the app
/// account is admin and the gateway didn't log us in as `user`.
class GatewayControlScreen extends StatefulWidget {
  final GatewaySession session;
  const GatewayControlScreen({super.key, required this.session});

  @override
  State<GatewayControlScreen> createState() => _GatewayControlScreenState();
}

class _GatewayControlScreenState extends State<GatewayControlScreen> {
  GatewaySession get _s => widget.session;

  bool _loading = true;
  String? _busy;

  String? _gatewayRole;
  Map<String, dynamic>? _status;
  List<Map<String, dynamic>> _cameras = const [];
  Map<String, dynamic>? _wifi;
  Map<String, dynamic>? _ble;
  Map<String, dynamic>? _cluster;
  Map<String, dynamic>? _mqtt;
  Map<String, dynamic>? _webhook;

  /// mount -> last ping result (rtt ms, or null = failed).
  final Map<String, double?> _ping = {};

  bool get _admin => AuthStore.instance.isAdmin && _gatewayRole != 'user';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<T?> _safe<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final me = await _s.me();
    _gatewayRole = me['role']?.toString();
    final r = await Future.wait([
      _safe(_s.rtspStatus),
      _safe(_s.config),
      _safe(_s.wifiStatus),
      _safe(_s.ble),
      _safe(_s.cluster),
      if (_admin) ...[_safe(_s.mqttConfig), _safe(_s.webhookState)],
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _status = r[0];
      _cameras = (r[1]?['cameras'] as List? ?? const []).cast<Map<String, dynamic>>();
      _wifi = r[2];
      _ble = r[3];
      _cluster = r[4];
      if (_admin) {
        _mqtt = r[5];
        _webhook = r[6];
      }
    });
  }

  /// Runs one REST action with a busy marker and a result snackbar.
  Future<void> _run(String key, Future<void> Function() action, {String? done, bool reload = true}) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await action();
      if (done != null) _toast(done);
      if (reload) await _load();
    } catch (e) {
      _toast('Lỗi: {e}'.trArgs({'e': e}));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirm(String title, String message) => showConfirmDialog(context, title: title, message: message);

  // ── actions ──────────────────────────────────────────────────────────

  Future<void> _restart() async {
    if (!await _confirm('Khởi động lại gateway RTSP?'.tr, 'Các luồng camera sẽ gián đoạn khoảng 5–15 giây.'.tr)) {
      return;
    }
    await _run('restart', _s.restart, done: 'Đã khởi động lại'.tr);
  }

  Future<void> _toggleContainer(bool run) async {
    if (!run &&
        !await _confirm('Tắt dịch vụ RTSP?'.tr, 'Mọi luồng camera và đẩy luồng sẽ dừng cho tới khi bật lại.'.tr)) {
      return;
    }
    await _run('container', () => _s.setContainer(run), done: run ? 'Đã bật dịch vụ'.tr : 'Đã tắt dịch vụ'.tr);
  }

  Future<void> _pingCamera(String mount) async {
    await _run('ping:$mount', () async {
      final r = await _s.pingCamera(mount);
      final rtt = r['success'] == true ? (r['rtt_ms'] as num?)?.toDouble() ?? 0 : null;
      if (mounted) setState(() => _ping[mount] = rtt);
    }, reload: false);
  }

  Future<void> _wifiDisconnect() async {
    if (!await _confirm(
        'Ngắt WiFi?'.tr, 'Nếu điện thoại đang nói chuyện với gateway qua WiFi này, kết nối sẽ mất.'.tr)) {
      return;
    }
    await _run('wifi', _s.wifiDisconnect, done: 'Đã ngắt WiFi'.tr);
  }

  Future<void> _wifiForget(String ssid) async {
    if (!await _confirm('Quên mạng "{ssid}"?'.trArgs({'ssid': ssid}), 'Gateway sẽ không tự kết nối lại mạng này.'.tr)) {
      return;
    }
    await _run('wifi', () => _s.wifiForget(ssid), done: 'Đã quên mạng'.tr);
  }

  Future<void> _editCluster(String key, String title) async {
    final current = (_cluster?[key] ?? '').toString();
    final v = await showTextPromptDialog(context, title: title, initialValue: current);
    if (v == null || v == current) return;
    await _run('cluster', () => _s.saveCluster({key: v}), done: 'Đã lưu'.tr);
  }

  Future<void> _showLogs() async {
    List<String> lines;
    try {
      lines = await _s.logs();
    } catch (e) {
      _toast('Lỗi: {e}'.trArgs({'e': e}));
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, ctl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nhật ký gateway'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ),
            Expanded(
              child: lines.isEmpty
                  ? Center(child: Text('Chưa có dữ liệu'.tr, style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
                      controller: ctl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: lines.length,
                      itemBuilder: (_, i) => Text(lines[i],
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: AppColors.textSecondary)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Điều khiển gateway'.tr,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: _busy != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child:
                    LinearProgressIndicator(minHeight: 2, color: AppColors.accent, backgroundColor: Colors.transparent),
              )
            : null,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _address(),
                  const SizedBox(height: 20),
                  _rtspSection(),
                  const SizedBox(height: 20),
                  _cameraSection(),
                  const SizedBox(height: 20),
                  _networkSection(),
                  const SizedBox(height: 20),
                  _clusterSection(),
                  if (_admin) ...[
                    const SizedBox(height: 20),
                    _adminSection(),
                  ],
                ],
              ),
            ),
    ));
  }

  Widget _address() {
    final role = _gatewayRole;
    return _Card(
      child: ListTile(
        leading: Icon(Icons.lan_outlined, color: AppColors.info),
        title: Text('REST: {url}'.trArgs({'url': _s.api.base}),
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(
          role == null ? 'Gateway chưa bật tài khoản'.tr : 'Vai trò trên gateway: {role}'.trArgs({'role': role}),
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: _admin ? const _AdminBadge() : null,
      ),
    );
  }

  Widget _rtspSection() {
    final running = _status?['running'] == true;
    final label = _status == null ? 'Không rõ'.tr : (running ? 'Đang chạy'.tr : 'Đã dừng'.tr);
    return _Section(
      title: 'Dịch vụ RTSP'.tr,
      child: _Card(
        child: Column(
          children: [
            ListTile(
              leading:
                  Icon(Icons.settings_input_antenna_rounded, color: running ? AppColors.success : AppColors.danger),
              title: Text(label,
                  style: TextStyle(fontWeight: FontWeight.w700, color: running ? AppColors.success : AppColors.danger)),
              subtitle: _status?['started'] != null
                  ? Text('Chạy từ {t}'.trArgs({'t': _status!['started']}),
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btn(Icons.restart_alt_rounded, 'Khởi động lại'.tr, _restart, busyKey: 'restart'),
                  if (_admin)
                    running
                        ? _btn(Icons.stop_circle_outlined, 'Tắt dịch vụ'.tr, () => _toggleContainer(false),
                            busyKey: 'container', danger: true)
                        : _btn(Icons.play_circle_outline, 'Bật dịch vụ'.tr, () => _toggleContainer(true),
                            busyKey: 'container'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraSection() {
    return _Section(
      title: 'Kiểm tra camera'.tr,
      child: _Card(
        child: _cameras.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child:
                    Text('Gateway chưa lưu camera nào.'.tr, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              )
            : Column(
                children: [
                  for (final c in _cameras)
                    Builder(builder: (_) {
                      final mount = (c['mount'] ?? '').toString();
                      final pinged = _ping.containsKey(mount);
                      final rtt = _ping[mount];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.videocam_outlined,
                            color: c['enabled'] == false ? AppColors.textMuted : AppColors.info),
                        title: Text(mount, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        subtitle: Text(
                          [
                            '${c['host'] ?? ''}',
                            if (pinged) rtt == null ? 'Không ping được'.tr : '${rtt.toStringAsFixed(1)} ms',
                          ].join(' · '),
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  !pinged ? AppColors.textMuted : (rtt == null ? AppColors.danger : AppColors.success)),
                        ),
                        trailing: _busy == 'ping:$mount'
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : TextButton(onPressed: () => _pingCamera(mount), child: Text('Ping'.tr)),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _networkSection() {
    final ssid = (_wifi?['ssid'] ?? '').toString();
    final connected = _wifi?['connected'] == true;
    final ble = _ble;
    return _Section(
      title: 'WiFi & Bluetooth'.tr,
      child: _Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: connected ? AppColors.success : AppColors.textMuted),
              title: Text(connected ? ssid : 'Chưa kết nối WiFi'.tr,
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: connected
                  ? Text('{ip} · sóng {sig}%'.trArgs({'ip': _wifi?['ip'] ?? '', 'sig': _wifi?['signal'] ?? '--'}),
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                  : null,
            ),
            if (connected)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _btn(Icons.link_off_rounded, 'Ngắt WiFi'.tr, _wifiDisconnect, busyKey: 'wifi'),
                    _btn(Icons.delete_sweep_outlined, 'Quên mạng'.tr, () => _wifiForget(ssid),
                        busyKey: 'wifi', danger: true),
                  ],
                ),
              ),
            Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading:
                  Icon(Icons.bluetooth_rounded, color: ble?['running'] == true ? AppColors.info : AppColors.textMuted),
              title: Text((ble?['name'] ?? 'Bluetooth').toString(),
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text(_bleState(ble?['state']?.toString()),
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  String _bleState(String? s) => switch (s) {
        'authorized' => 'Đang cho phép cài WiFi qua BLE'.tr,
        'authorization_required' => 'Cần nhấn nút trên gateway'.tr,
        'provisioning' => 'Đang cài WiFi'.tr,
        'provisioned' => 'Đã cài WiFi'.tr,
        null => 'Không rõ'.tr,
        _ => s,
      };

  Widget _clusterSection() {
    final c = _cluster ?? const {};
    Widget row(String label, String key) => ListTile(
          dense: true,
          title: Text(label, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          subtitle: Text((c[key] ?? '--').toString(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          trailing: _admin && key != 'gateway_id'
              ? IconButton(
                  icon: Icon(Icons.edit_outlined, size: 19, color: AppColors.textMuted),
                  onPressed: () => _editCluster(key, label),
                )
              : null,
        );
    return _Section(
      title: 'Định danh (cụm)'.tr,
      child: _Card(
        child: Column(
          children: [
            row('Mã gateway'.tr, 'gateway_id'),
            row('Tên cụm'.tr, 'cluster_name'),
            row('Khu vực'.tr, 'zone'),
          ],
        ),
      ),
    );
  }

  Widget _adminSection() {
    final mqtt = _mqtt;
    final webhook = _webhook;
    final mqttOn = mqtt?['enabled'] == true;
    final pushUrl = (webhook?['push_url'] ?? (webhook?['config'] as Map?)?['push_url'] ?? '').toString();
    return _Section(
      title: 'Quản trị'.tr,
      trailing: const _AdminBadge(),
      child: _Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.hub_outlined, color: mqttOn ? AppColors.success : AppColors.textMuted),
              title: Text('MQTT', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text(
                mqtt == null
                    ? 'Không đọc được cấu hình'.tr
                    : mqttOn
                        ? '${mqtt['broker_host']}:${mqtt['broker_port']} · ${mqtt['base_topic'] ?? ''}'
                        : 'Đang tắt'.tr,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            if (mqttOn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  _btn(Icons.network_check_rounded, 'Thử kết nối'.tr,
                      () => _run('mqtt', _s.mqttTest, done: 'Kết nối broker thành công'.tr, reload: false),
                      busyKey: 'mqtt'),
                  _btn(Icons.send_rounded, 'Gửi ngay'.tr,
                      () => _run('mqtt', () => _s.mqttPublish('stream'), done: 'Đã gửi'.tr, reload: false),
                      busyKey: 'mqtt'),
                ]),
              ),
            Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: Icon(Icons.webhook_rounded, color: pushUrl.isNotEmpty ? AppColors.success : AppColors.textMuted),
              title: Text('Webhook', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text(pushUrl.isEmpty ? 'Chưa cấu hình'.tr : pushUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              trailing: pushUrl.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () =>
                          _run('webhook', () => _s.webhookPush('stream'), done: 'Đã gửi'.tr, reload: false),
                      child: Text('Gửi ngay'.tr)),
            ),
            Divider(height: 1, color: AppColors.divider),
            ListTile(
              leading: Icon(Icons.receipt_long_outlined, color: AppColors.info),
              title: Text('Nhật ký gateway'.tr,
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              subtitle: Text('100 dòng gần nhất'.tr, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              onTap: _showLogs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onPressed, {required String busyKey, bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.accent;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _busy == null ? onPressed : null,
      icon: _busy == busyKey
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

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
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      child: child,
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
    );
  }
}
