import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../core/cloud_camera_sync.dart';
import '../../core/gateway_session.dart';
import '../../data/gateway_session_store.dart';
import '../../data/gateway_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import '../../widgets/prompt_dialog.dart';
import 'demo_gateway_data.dart';
import '../../widgets/app_ui.dart';

/// "Đẩy luồng" (README_BLE §9): every camera is pushed to our media server by
/// default (`/api/rtsp/autopush`), each one can be switched off, and extra
/// destinations can be added (`/api/rtsp/outputs`). Same data as the Maintain
/// web page, so both UIs stay in sync.
class StreamPushScreen extends StatefulWidget {
  final SavedGateway gateway;
  const StreamPushScreen({super.key, required this.gateway});

  @override
  State<StreamPushScreen> createState() => _StreamPushScreenState();
}

/// Where the screen reads/writes: the live gateway or the demo data.
abstract class _PushBackend {
  bool get canEdit;
  Future<Map<String, dynamic>> autopush();
  Future<Map<String, dynamic>> saveAutopush(Map<String, dynamic> change);
  Future<List<Map<String, dynamic>>> outputs();
  Future<List<Map<String, dynamic>>> saveOutputs(List<Map<String, dynamic>> outputs);
  Future<List<Map<String, dynamic>>> cameras();
}

class _GatewayBackend implements _PushBackend {
  final GatewaySession s;
  _GatewayBackend(this.s);

  /// Gateway accounts off => "admin"; the gateway still answers 403 otherwise.
  @override
  bool get canEdit => s.role == 'admin';

  @override
  Future<Map<String, dynamic>> autopush() => s.autopush();

  @override
  Future<Map<String, dynamic>> saveAutopush(Map<String, dynamic> change) => s.saveAutopush(change);

  @override
  Future<List<Map<String, dynamic>>> outputs() => s.outputs();

  @override
  Future<List<Map<String, dynamic>>> saveOutputs(List<Map<String, dynamic>> outputs) async {
    await s.saveOutputs(outputs);
    return s.outputs();
  }

  @override
  Future<List<Map<String, dynamic>>> cameras() => s.cameras();
}

class _DemoBackend implements _PushBackend {
  final DemoGateway demo;
  bool _enabled = true;
  String? _customUrl;
  String get _url => _customUrl ?? 'rtsp://${ApiConfig.mediaIngestHost}:1936/{mount}';
  set _url(String val) => _customUrl = val;
  final Set<String> _off = {};
  final List<Map<String, dynamic>> _outputs = [];
  final DateTime _start = DateTime.now();

  _DemoBackend(this.demo);

  @override
  bool get canEdit => true;

  String _target(String mount) => _url.contains('{mount}')
      ? _url.replaceAll('{mount}', mount).replaceAll('{gateway_id}', demo.gateway.id)
      : '${_url.replaceAll(RegExp(r'/+$'), '')}/$mount';

  @override
  Future<Map<String, dynamic>> autopush() async {
    final up = DateTime.now().difference(_start).inSeconds + 3600;
    return {
      'enabled': _enabled,
      'url': _url,
      'pusher_online': true,
      'cameras': [
        for (final c in demo.cameras())
          {
            'mount': c['mount'],
            'host': c['host'],
            'camera_enabled': true,
            'push': !_off.contains(c['mount']),
            'target': _target(c['mount']),
            'state': !_enabled ? 'disabled' : (_off.contains(c['mount']) ? 'off' : 'running'),
            'uptime_seconds': up,
            'engine': 'gstreamer',
            'via_output': '',
          },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> saveAutopush(Map<String, dynamic> change) async {
    if (change['enabled'] != null) _enabled = change['enabled'] as bool;
    if (change['url'] != null) _url = change['url'] as String;
    (change['cameras'] as Map?)?.forEach((m, on) => on == true ? _off.remove(m) : _off.add('$m'));
    return autopush();
  }

  @override
  Future<List<Map<String, dynamic>>> outputs() async => [
        for (final o in _outputs)
          {
            ...o,
            'pusher_online': true,
            'streams': [
              if (o['enabled'] == true)
                {'mount': o['camera'], 'state': 'running', 'target': o['url'], 'uptime_seconds': 42},
            ],
          },
      ];

  @override
  Future<List<Map<String, dynamic>>> saveOutputs(List<Map<String, dynamic>> outputs) async {
    _outputs
      ..clear()
      ..addAll(
          outputs.map((o) => {...o, 'id': (o['id'] ?? '').toString().isEmpty ? 'demo${_outputs.length}' : o['id']}));
    return this.outputs();
  }

  @override
  Future<List<Map<String, dynamic>>> cameras() async => demo.cameras();
}

class _StreamPushScreenState extends State<StreamPushScreen> {
  _PushBackend? _backend;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _auto;
  List<Map<String, dynamic>> _outputs = const [];
  Timer? _poll;

  bool get _isDemo => DemoGateway.isDemo(widget.gateway.id);

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (_isDemo) {
      _backend = _DemoBackend(DemoGateway(widget.gateway));
    } else {
      final s = await GatewaySessionStore.instance.ensureConnected(gatewayId: widget.gateway.id);
      if (!mounted) return;
      if (s == null) {
        setState(() {
          _loading = false;
          _error = GatewaySessionStore.instance.error ?? 'Không kết nối được gateway'.tr;
        });
        return;
      }
      _backend = _GatewayBackend(s);
    }
    await _refresh();
    if (mounted) setState(() => _loading = false);
    // Status changes on the gateway side (running / retrying…): poll like the web page.
    _poll ??= Timer.periodic(const Duration(seconds: 5), (_) => _refresh(quiet: true));
  }

  Future<void> _refresh({bool quiet = false}) async {
    final b = _backend;
    if (b == null || _saving) return;
    try {
      Map<String, dynamic>? auto;
      try {
        auto = await b.autopush();
      } catch (_) {
        // Gateway doesn't have /api/rtsp/autopush yet.
      }
      final outs = await b.outputs();
      if (auto == null) {
        // Fallback for gateways without /api/rtsp/autopush: synthesize from cameras + outputs
        final rawCams = await b.cameras();
        final serverUrl = _auto?['url'] ?? 'rtsp://${ApiConfig.mediaIngestHost}:1936/live/{mount}';
        final cams = <Map<String, dynamic>>[];
        for (final c in rawCams) {
          final mount = '${c['mount']}';
          final outMatch = outs.cast<Map<String, dynamic>?>().firstWhere(
                (o) => o?['camera'] == mount,
                orElse: () => null,
              );
          final hasOut = outMatch != null && outMatch['enabled'] != false;
          final streams = (outMatch?['streams'] as List? ?? const []).cast<Map>();
          final stream = streams.isNotEmpty ? streams.first : null;
          final state = !hasOut
              ? 'off'
              : (stream?['state'] ?? 'running');
          final target = outMatch != null
              ? '${outMatch['url']}'
              : (serverUrl.contains('{mount}')
                  ? serverUrl.replaceAll('{mount}', mount)
                  : '${serverUrl.replaceAll(RegExp(r'/+$'), '')}/$mount');

          cams.add({
            'mount': mount,
            'host': c['host'] ?? '',
            'camera_enabled': c['enabled'] != false,
            'push': hasOut,
            'target': target,
            'state': state,
            'uptime_seconds': stream?['uptime_seconds'] ?? 0,
            'via_output': outMatch?['id'] ?? '',
          });
        }
        auto = {
          'enabled': cams.any((c) => c['push'] == true),
          'url': serverUrl,
          'pusher_online': true,
          'supported': false,
          'cameras': cams,
        };
      }
      if (!mounted) return;
      setState(() {
        _auto = auto;
        _outputs = outs;
        _error = null;
      });
    } catch (e) {
      if (!quiet && mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _run(Future<void> Function(_PushBackend b) action) async {
    final b = _backend;
    if (b == null) return;
    setState(() => _saving = true);
    try {
      await action(b);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveAuto(Map<String, dynamic> change) => _run((b) async {
        if (_auto?['supported'] == false) {
          if (change['url'] != null) {
            final newUrl = '${change['url']}';
            _auto = {..._auto!, 'url': newUrl};
            final currentOutputs = _plainOutputs();
            final updatedOutputs = currentOutputs.map((o) {
              final cam = o['camera'];
              if (cam != null) {
                final target = newUrl.contains('{mount}')
                    ? newUrl.replaceAll('{mount}', '$cam')
                    : '${newUrl.replaceAll(RegExp(r'/+$'), '')}/$cam';
                return {...o, 'url': target};
              }
              return o;
            }).toList();
            await _saveOutputs(updatedOutputs);
          }
          if (change['enabled'] != null) {
            final on = change['enabled'] == true;
            final cams = (_auto?['cameras'] as List? ?? const []).cast<Map>();
            for (final c in cams) {
              await _toggleCamera(c, on);
            }
          }
          if (change['cameras'] != null && change['cameras'] is Map) {
            final map = change['cameras'] as Map;
            for (final entry in map.entries) {
              final cam = (_auto?['cameras'] as List? ?? const [])
                  .cast<Map>()
                  .firstWhere((c) => '${c['mount']}' == '${entry.key}', orElse: () => const {});
              if (cam.isNotEmpty) {
                await _toggleCamera(cam, entry.value == true);
              }
            }
          }
          await _refresh();
          return;
        }
        final fresh = await b.saveAutopush(change);
        if (mounted) setState(() => _auto = fresh);
      });

  Future<void> _toggleCamera(Map cam, bool on) async {
    final mount = '${cam['mount']}';
    if (_auto?['supported'] == false) {
      final serverUrl = (_auto?['url'] ?? 'rtsp://${ApiConfig.mediaIngestHost}:1936/live/{mount}').toString();
      final target = serverUrl.contains('{mount}')
          ? serverUrl.replaceAll('{mount}', mount)
          : '${serverUrl.replaceAll(RegExp(r'/+$'), '')}/$mount';

      final currentOutputs = _plainOutputs();
      final existingIndex = currentOutputs.indexWhere((o) => o['camera'] == mount);
      List<Map<String, dynamic>> newOutputs;
      if (existingIndex >= 0) {
        newOutputs = [
          for (var i = 0; i < currentOutputs.length; i++)
            i == existingIndex ? {...currentOutputs[i], 'enabled': on, 'url': target} : currentOutputs[i]
        ];
      } else if (on) {
        newOutputs = [
          ...currentOutputs,
          {
            'id': 'out_$mount',
            'name': 'media_$mount',
            'url': target,
            'camera': mount,
            'enabled': true,
          }
        ];
      } else {
        newOutputs = currentOutputs;
      }
      await _saveOutputs(newOutputs);
      await _refresh();
      return;
    }
    await _saveAuto({
      'cameras': {mount: on},
    });
  }

  /// Create cloud cameras for every camera pushed to our media server, so
  /// they show in the Camera / Home tabs (cameras saved before this existed).
  Future<void> _syncCloud() => _run((b) async {
        final result = await syncGatewayCamerasToCloud((b as _GatewayBackend).s);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.summary)));
        }
      });

  Future<void> _editServerUrl() async {
    final url = await showTextPromptDialog(
      context,
      title: 'URL media server'.tr,
      initialValue: (_auto?['url'] ?? '').toString(),
      hint: 'rtsp://${ApiConfig.mediaIngestHost}:1936/{mount}',
    );
    if (url != null && url != _auto?['url']) await _saveAuto({'url': url});
  }

  /// POST /api/rtsp/outputs replaces the whole list: always send every entry
  /// (masked URLs are fine, the gateway keeps the stored secrets).
  List<Map<String, dynamic>> _plainOutputs() => [
        for (final o in _outputs)
          {'id': o['id'], 'name': o['name'], 'url': o['url'], 'enabled': o['enabled'] != false, 'camera': o['camera']},
      ];

  Future<void> _saveOutputs(List<Map<String, dynamic>> list) => _run((b) async {
        final fresh = await b.saveOutputs(list);
        if (mounted) setState(() => _outputs = fresh);
      });

  Future<void> _addOutput() async {
    final mounts = [for (final c in (_auto?['cameras'] as List? ?? const [])) '${c['mount']}'];
    if (mounts.isEmpty) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OutputForm(mounts: mounts),
    );
    if (result != null) await _saveOutputs([..._plainOutputs(), result]);
  }

  Future<void> _removeOutput(Map<String, dynamic> o) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Xoá đích đẩy luồng?'.tr,
      message: 'Luồng {camera} sẽ ngừng đẩy tới {url}.'.trArgs({'camera': o['camera'], 'url': o['url']}),
    );
    if (!ok) return;
    await _saveOutputs(_plainOutputs().where((x) => x['id'] != o['id']).toList());
  }

  Future<void> _toggleOutput(Map<String, dynamic> o, bool on) => _saveOutputs([
        for (final x in _plainOutputs()) x['id'] == o['id'] ? {...x, 'enabled': on} : x,
      ]);

  @override
  Widget build(BuildContext context) {
    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Đẩy luồng'.tr,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: _saving
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child:
                    LinearProgressIndicator(minHeight: 2, color: AppColors.accent, backgroundColor: Colors.transparent),
              )
            : null,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _auto == null
              ? _Message(message: _error ?? 'Không kết nối được gateway'.tr, onRetry: _connect)
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.accent,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildAutoCard(),
                      const SizedBox(height: 20),
                      _SectionLabel('Camera'.tr),
                      _buildCameraList(),
                      if (_backend is _GatewayBackend) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _syncCloud,
                          icon: const Icon(Icons.playlist_add_rounded),
                          label: Text('Thêm camera vào app'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _SectionLabel('Đích khác (tuỳ chọn)'.tr,
                          trailing: _backend!.canEdit
                              ? TextButton.icon(
                                  onPressed: _saving ? null : _addOutput,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text('Thêm URL'.tr),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                )
                              : null),
                      _buildOutputs(),
                    ],
                  ),
                ),
    ));
  }

  Widget _buildAutoCard() {
    final a = _auto!;
    final enabled = a['enabled'] == true;
    final canEdit = _backend!.canEdit;
    final cams = (a['cameras'] as List? ?? const []).cast<Map>();
    final running = cams.where((c) => c['state'] == 'running').length;
    final pushing = cams.where((c) => c['push'] == true && c['camera_enabled'] != false).length;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.cloud_upload_outlined, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tự động đẩy lên media server'.tr,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(
                        pushing > 0
                            ? '{running}/{total} camera đang đẩy'.trArgs({'running': running, 'total': pushing})
                            : 'Đang tắt'.tr,
                        style: TextStyle(fontSize: 12, color: pushing > 0 ? AppColors.success : AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  activeTrackColor: AppColors.accent,
                  onChanged: canEdit && !_saving ? (v) => _saveAuto({'enabled': v}) : null,
                ),
              ],
            ),
          ),
          Divider(height: 16, color: AppColors.divider, indent: 14, endIndent: 14),
          InkWell(
            onTap: canEdit && !_saving ? _editServerUrl : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Row(
                children: [
                  Icon(Icons.dns_outlined, size: 17, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Media server'.tr, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('${a['url']}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  if (canEdit) Icon(Icons.edit_outlined, size: 17, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          if (a['pusher_online'] == false)
            _Banner(
              color: AppColors.danger,
              text: 'Dịch vụ đẩy luồng (eyerus-push) trên gateway chưa chạy.'.tr,
            ),
          if (!canEdit) _Banner(color: AppColors.warning, text: 'Cần tài khoản admin của gateway để thay đổi.'.tr),
        ],
      ),
    );
  }

  Widget _buildCameraList() {
    final cams = (_auto!['cameras'] as List? ?? const []).cast<Map>();
    if (cams.isEmpty) {
      return _Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Chưa có camera nào được kết nối với gateway.'.tr,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      );
    }
    final autoOn = _auto!['enabled'] == true;
    final isSupported = _auto!['supported'] != false;
    final canEdit = _backend!.canEdit && (autoOn || !isSupported) && !_saving;
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < cams.length; i++) ...[
            _CameraRow(
              cam: cams[i],
              onToggle: canEdit && cams[i]['camera_enabled'] != false
                  ? (v) => _toggleCamera(cams[i], v)
                  : null,
            ),
            if (i != cams.length - 1) Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildOutputs() {
    if (_outputs.isEmpty) {
      return _Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Chưa có. Thêm URL để đẩy một camera sang server khác (rtsp, rtmp, srt…).'.tr,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
        ),
      );
    }
    final canEdit = _backend!.canEdit && !_saving;
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < _outputs.length; i++) ...[
            _OutputRow(
              output: _outputs[i],
              onToggle: canEdit ? (v) => _toggleOutput(_outputs[i], v) : null,
              onDelete: canEdit ? () => _removeOutput(_outputs[i]) : null,
            ),
            if (i != _outputs.length - 1) Divider(height: 1, color: AppColors.divider, indent: 14, endIndent: 14),
          ],
        ],
      ),
    );
  }
}

/// (label, color) for a push state (README_BLE §9 + auto-push states).
(String, Color) pushStateStyle(String state) => switch (state) {
      'running' => ('Đang đẩy'.tr, AppColors.success),
      'starting' => ('Đang khởi động'.tr, AppColors.info),
      'retrying' => ('Đang thử lại'.tr, AppColors.warning),
      'auth_failed' => ('Server từ chối (sai URL/khoá)'.tr, AppColors.danger),
      'error' => ('Lỗi'.tr, AppColors.danger),
      'pusher_offline' => ('Dịch vụ đẩy chưa chạy'.tr, AppColors.danger),
      'off' => ('Đã tắt'.tr, AppColors.textMuted),
      'disabled' => ('Tạm dừng'.tr, AppColors.textMuted),
      _ => (state, AppColors.textMuted),
    };

class _CameraRow extends StatelessWidget {
  final Map cam;
  final ValueChanged<bool>? onToggle;
  const _CameraRow({required this.cam, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final state = cam['camera_enabled'] == false ? 'disabled' : '${cam['state']}';
    final (label, color) =
        cam['camera_enabled'] == false ? ('Camera đang tắt'.tr, AppColors.textMuted) : pushStateStyle(state);
    final err = '${cam['last_error'] ?? ''}';
    final via = '${cam['via_output'] ?? ''}'.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.videocam_outlined, size: 19, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text('${cam['mount']}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    _Pill(label: label, color: color),
                  ],
                ),
                const SizedBox(height: 3),
                Text('→ ${cam['target']}', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                if (via)
                  Text('Đang đẩy qua đích khác cùng URL'.tr, style: TextStyle(fontSize: 11, color: AppColors.info)),
                if (state != 'running' && err.isNotEmpty)
                  Text(err,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.danger)),
              ],
            ),
          ),
          Switch.adaptive(
            value: cam['push'] == true,
            activeTrackColor: AppColors.accent,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class _OutputRow extends StatelessWidget {
  final Map<String, dynamic> output;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;
  const _OutputRow({required this.output, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final streams = (output['streams'] as List? ?? const []).cast<Map>();
    final enabled = output['enabled'] != false;
    final state = !enabled
        ? 'off'
        : output['pusher_online'] == false
            ? 'pusher_offline'
            : (streams.isEmpty ? 'starting' : '${streams.first['state']}');
    final (label, color) = pushStateStyle(state);
    final err = streams.isEmpty ? '' : '${streams.first['last_error'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 0, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.alt_route_rounded, size: 19, color: AppColors.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${output['name'] ?? ''} · ${output['camera']}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    _Pill(label: label, color: color),
                  ],
                ),
                const SizedBox(height: 3),
                Text('→ ${output['url']}', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                if (state != 'running' && err.isNotEmpty)
                  Text(err,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.danger)),
              ],
            ),
          ),
          Switch.adaptive(value: enabled, activeTrackColor: AppColors.accent, onChanged: onToggle),
          IconButton(
            tooltip: 'Xoá'.tr,
            icon: Icon(Icons.delete_outline_rounded, color: onDelete == null ? AppColors.textMuted : AppColors.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet form for one extra destination (camera + URL + name).
class _OutputForm extends StatefulWidget {
  final List<String> mounts;
  const _OutputForm({required this.mounts});

  @override
  State<_OutputForm> createState() => _OutputFormState();
}

class _OutputFormState extends State<_OutputForm> {
  final _formKey = GlobalKey<FormState>();
  final _url = TextEditingController();
  final _name = TextEditingController();
  late String _camera = widget.mounts.first;

  static const _schemes = ['rtsp', 'rtsps', 'rtmp', 'rtmps', 'srt'];

  @override
  void dispose() {
    _url.dispose();
    _name.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Text('Thêm đích đẩy luồng'.tr,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _camera,
                decoration: _decoration('Camera'.tr),
                dropdownColor: AppColors.card,
                items: [for (final m in widget.mounts) DropdownMenuItem(value: m, child: Text(m))],
                onChanged: (v) => setState(() => _camera = v ?? _camera),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: _decoration('URL đích'.tr, hint: 'rtmp://a.rtmp.youtube.com/live2/<key>'),
                validator: (v) {
                  final uri = Uri.tryParse((v ?? '').trim());
                  if (uri == null || !_schemes.contains(uri.scheme.toLowerCase()) || uri.host.isEmpty) {
                    return 'URL phải bắt đầu bằng rtsp://, rtsps://, rtmp://, rtmps:// hoặc srt://'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: _decoration('Tên (tuỳ chọn)'.tr, hint: 'VD: YouTube'.tr),
              ),
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context, {
                    'name': _name.text.trim(),
                    'url': _url.text.trim(),
                    'camera': _camera,
                    'enabled': true,
                  });
                },
                child: Text('Thêm'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const _SectionLabel(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text.toUpperCase(),
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final String text;
  const _Banner({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.4)),
    );
  }
}

class _Message extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Message({required this.message, required this.onRetry});

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
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
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
