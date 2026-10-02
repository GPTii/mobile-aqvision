import 'package:flutter/material.dart';

import '../../core/cloud_camera_sync.dart';
import '../../core/gateway_session.dart';
import '../../data/gateway_session_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import '../../widgets/app_ui.dart';

/// A camera in the edit buffer. `/api/save` replaces the WHOLE list, so this
/// screen keeps every camera we want to keep and sends them together (§7).
class _Cam {
  String mount;
  String host;
  int port;
  String username;

  /// null / empty = keep the password already on the gateway (§7).
  String? password;
  bool enabled;
  bool includeAudio;

  // Read-only, from /api/cameras/health — for display only.
  String status;
  bool online;
  bool routeReady;
  String manufacturer;
  String model;

  _Cam({
    required this.mount,
    this.host = '',
    this.port = 2020,
    this.username = 'admin',
    this.password,
    this.enabled = true,
    this.includeAudio = true,
    this.status = '',
    this.online = false,
    this.routeReady = false,
    this.manufacturer = '',
    this.model = '',
  });

  factory _Cam.fromHealth(Map<String, dynamic> h) => _Cam(
        mount: (h['mount'] ?? '') as String,
        host: (h['host'] ?? '') as String,
        port: (h['port'] ?? 2020) as int,
        username: (h['username'] ?? 'admin') as String,
        password: null, // never returned; null = keep existing
        enabled: (h['enabled'] ?? true) as bool,
        includeAudio: (h['include_audio'] ?? true) as bool,
        status: (h['status'] ?? '') as String,
        online: (h['online'] ?? false) as bool,
        routeReady: (h['route_ready'] ?? false) as bool,
        manufacturer: (h['manufacturer'] ?? '') as String,
        model: (h['model'] ?? '') as String,
      );

  /// Payload for POST /api/save. Omits password when unchanged (keeps old, §7).
  Map<String, dynamic> toSave() => {
        'mount': mount,
        'host': host,
        'port': port,
        'username': username,
        if (password != null && password!.isNotEmpty) 'password': password,
        'enabled': enabled,
        'include_audio': includeAudio,
      };
}

class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});

  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  final _store = GatewaySessionStore.instance;

  GatewaySession? _session;
  bool _connecting = true;
  String? _error;

  bool _scanning = false;
  bool _saving = false;

  /// The edit buffer: existing + newly added cameras.
  final List<_Cam> _cams = [];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _error = null;
    });
    final s = await _store.ensureConnected();
    if (!mounted) return;
    if (s == null) {
      setState(() {
        _connecting = false;
        _error = _store.error ?? 'Không kết nối được gateway.'.tr;
      });
      return;
    }
    _session = s;
    await _loadExisting();
    if (!mounted) return;
    setState(() => _connecting = false);
  }

  Future<void> _loadExisting() async {
    try {
      final health = await _session!.cameras();
      _cams
        ..clear()
        ..addAll(health.map(_Cam.fromHealth));
    } catch (e) {
      _snack('Không đọc được danh sách camera: {e}'.trArgs({'e': e}));
    }
  }

  String _suggestMount() {
    var i = 1;
    while (_cams.any((c) => c.mount == 'cam$i')) {
      i++;
    }
    return 'cam$i';
  }

  Future<void> _scan() async {
    if (_session == null || _scanning) return;
    setState(() => _scanning = true);
    try {
      final found = await _session!.scanCameras();
      if (!mounted) return;
      await _showScanResults(found);
    } catch (e) {
      _snack('Quét lỗi: {e}'.trArgs({'e': e}));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _showScanResults(List<Map<String, dynamic>> found) async {
    if (found.isEmpty) {
      _snack('Không tìm thấy camera nào trong mạng.'.tr);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('Camera tìm thấy trong mạng'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: found.length,
                itemBuilder: (_, i) {
                  final f = found[i];
                  final host = (f['host'] ?? f['ip'] ?? f['address'] ?? '') as String;
                  final port = (f['port'] ?? 2020) as int;
                  final label = (f['manufacturer'] ?? f['name'] ?? f['model'] ?? host).toString();
                  final already = _cams.any((c) => c.host == host);
                  return ListTile(
                    leading: const Icon(Icons.videocam_outlined),
                    title: Text(label),
                    subtitle: Text('$host:$port'),
                    trailing: already ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.add),
                    onTap: () {
                      Navigator.pop(ctx);
                      final cam = _Cam(
                        mount: _suggestMount(),
                        host: host,
                        port: port,
                        manufacturer: (f['manufacturer'] ?? '') as String,
                        model: (f['model'] ?? '') as String,
                      );
                      _editCamera(cam, isNew: true);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCamera(_Cam cam, {required bool isNew}) async {
    final mountCtl = TextEditingController(text: cam.mount);
    final hostCtl = TextEditingController(text: cam.host);
    final portCtl = TextEditingController(text: cam.port.toString());
    final userCtl = TextEditingController(text: cam.username);
    final passCtl = TextEditingController();
    var enabled = cam.enabled;
    var includeAudio = cam.includeAudio;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text((isNew ? 'Thêm camera' : 'Sửa camera').tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _field(mountCtl, 'Mount (cam1, cam2… chỉ A-Z a-z 0-9 _ -)'.tr),
              const SizedBox(height: 12),
              _field(hostCtl, 'Địa chỉ IP camera'.tr),
              const SizedBox(height: 12),
              _field(portCtl, 'Cổng ONVIF (Tapo: 2020)'.tr, keyboard: TextInputType.number),
              const SizedBox(height: 12),
              _field(userCtl, 'Tài khoản camera'.tr),
              const SizedBox(height: 12),
              _field(passCtl, (isNew ? 'Mật khẩu camera' : 'Mật khẩu (bỏ trống = giữ cũ)').tr, obscure: true),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Bật camera'.tr),
                value: enabled,
                activeColor: AppColors.accent,
                onChanged: (v) => setSheet(() => enabled = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Kèm âm thanh'.tr),
                subtitle: Text('Tắt để giảm trễ luồng'.tr),
                value: includeAudio,
                activeColor: AppColors.accent,
                onChanged: (v) => setSheet(() => includeAudio = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  final mount = mountCtl.text.trim();
                  if (mount.isEmpty || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(mount)) {
                    ScaffoldMessenger.of(ctx)
                        .showSnackBar(SnackBar(content: Text('Mount không hợp lệ (chỉ A-Z a-z 0-9 _ -)'.tr)));
                    return;
                  }
                  if (hostCtl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Nhập địa chỉ IP camera'.tr)));
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text('Xong'.tr),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;

    cam
      ..mount = mountCtl.text.trim()
      ..host = hostCtl.text.trim()
      ..port = int.tryParse(portCtl.text.trim()) ?? cam.port
      ..username = userCtl.text.trim()
      ..enabled = enabled
      ..includeAudio = includeAudio;
    if (passCtl.text.isNotEmpty) cam.password = passCtl.text;

    setState(() {
      if (isNew && !_cams.contains(cam)) _cams.add(cam);
    });
  }

  Future<void> _save() async {
    if (_session == null || _saving) return;
    if (_cams.isEmpty) {
      _snack('Chưa có camera nào để lưu.'.tr);
      return;
    }
    // New cameras must have a password (nothing to keep).
    final missing = _cams.where((c) => (c.password == null || c.password!.isEmpty) && c.status.isEmpty);
    if (missing.isNotEmpty) {
      _snack('Camera "{mount}" chưa có mật khẩu.'.trArgs({'mount': missing.first.mount}));
      return;
    }

    setState(() => _saving = true);
    try {
      await _session!.saveCameras(_cams.map((c) => c.toSave()).toList());
      _snack('Đã lưu, đang áp dụng cấu hình…'.tr);
      // Restart interrupts streams for a few seconds; give it time then reload (§1.6).
      await Future.delayed(const Duration(seconds: 8));
      await _loadExisting();
      // Gateway now pushes every camera to the media server (auto-push):
      // create the matching cloud cameras so they appear in the app at once.
      final sync = await syncGatewayCamerasToCloud(_session!);
      if (mounted) _snack('{summary}. Hoàn tất.'.trArgs({'summary': sync.summary}));
    } catch (e) {
      _snack('Lưu lỗi: {e}'.trArgs({'e': e}));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Quét camera'.tr,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: (_connecting || _error != null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Đang áp dụng…'.tr : 'Lưu & áp dụng ({n} camera)'.trArgs({'n': _cams.length})),
                ),
              ),
            ),
    ));
  }

  Widget _buildBody() {
    if (_connecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang kết nối gateway…'.tr),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _connect,
                icon: const Icon(Icons.refresh),
                label: Text('Thử lại'.tr),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExisting,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: _scanning
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.radar),
                  label: Text((_scanning ? 'Đang quét…' : 'Quét camera trong mạng').tr),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Thêm thủ công'.tr,
                onPressed: () => _editCamera(_Cam(mount: _suggestMount()), isNew: true),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cams.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(Icons.videocam_off_outlined, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('Chưa có camera. Bấm "Quét camera trong mạng".'.tr,
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            ..._cams.map(_cameraCard),
        ],
      ),
    );
  }

  Widget _cameraCard(_Cam c) {
    final (color, text) = _statusStyle(c);
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(Icons.videocam, color: c.enabled ? AppColors.accent : AppColors.textMuted),
        title: Text(c.mount, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.host}:${c.port}'
                '${c.model.isNotEmpty ? ' · ${c.model}' : ''}'),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text(text, style: TextStyle(color: color, fontSize: 11)),
              ),
              if (c.routeReady) ...[
                const SizedBox(width: 6),
                const Icon(Icons.play_circle_outline, size: 14, color: Colors.green),
              ],
            ]),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editCamera(c, isNew: false),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () => setState(() => _cams.remove(c)),
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _statusStyle(_Cam c) {
    if (!c.enabled) return (AppColors.textMuted, 'Tắt'.tr);
    if (c.online || c.status == 'online') return (AppColors.success, 'Online');
    if (c.status == 'error') return (AppColors.danger, 'Lỗi tài khoản/cổng'.tr);
    if (c.status.isEmpty) return (AppColors.info, 'Mới thêm'.tr);
    return (AppColors.warning, c.status);
  }

  Widget _field(TextEditingController ctl, String label, {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: ctl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
