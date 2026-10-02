import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/gateway_session.dart';
import '../../data/gateway_session_store.dart';
import '../../data/gateway_store.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_ui.dart';
import '../../widgets/gateway_avatar.dart';
import '../../utils/app_strings.dart';
import '../../widgets/prompt_dialog.dart';
import '../setup/qr_scanner_screen.dart';
import '../../data/auth_store.dart';
import 'demo_gateway_data.dart';
import 'maintain_web_screen.dart';
import 'gateway_detail_screen.dart';

/// "Quản lý thiết bị": every gateway saved on this phone, with a quick
/// reachability check. Tap one for live telemetry and parameters.
class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final _store = GatewaySessionStore.instance;

  /// gateway_id -> reachable (null = still checking).
  final Map<String, bool?> _online = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await _store.loadSaved();
    final gateways = _store.savedGateways;
    setState(() {
      _online
        ..clear()
        ..addEntries(gateways.map((g) => MapEntry(g.id, null)));
    });
    await Future.wait(gateways.map((g) async {
      final ok = await _ping(g);
      if (mounted) setState(() => _online[g.id] = ok);
    }));
  }

  /// `/api/health` needs no login (README_BLE §4) — cheap liveness probe.
  Future<bool> _ping(SavedGateway g) async {
    for (final host in [g.ip, if (g.hostname.isNotEmpty) '${g.hostname}.local']) {
      if (host.isEmpty) continue;
      try {
        final r = await http.get(Uri.parse('http://$host:${g.port}/api/health')).timeout(const Duration(seconds: 3));
        if (r.statusCode == 200) return true;
      } catch (_) {
        // try next host
      }
    }
    return false;
  }

  Future<void> _addGateway() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (mounted) _refresh();
  }

  /// Add a gateway by its local REST address (TaiLieuTichHop §4.2),
  /// e.g. `localhost` or a LAN IP, without going through BLE / QR.
  Future<void> _addByIp() async {
    final input = await showHostPortDialog(
      context,
      title: 'Kết nối gateway qua IP'.tr,
      initialHost: 'localhost',
      initialPort: kGatewayPort,
      hint: 'VD: localhost hoặc 192.168.1.189'.tr,
      confirmLabel: 'Kết nối'.tr,
    );
    if (input == null || !mounted) return;
    final (h, port) = input;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text('Đang kết nối {host}…'.trArgs({'host': '$h:$port'}))));
    try {
      await _store.addManual(h, port: port);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Đã thêm gateway'.tr)));
      if (mounted) _refresh();
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _removeGateway(SavedGateway g) async {
    // Only admin accounts may remove gateways.
    if (!AuthStore.instance.isAdmin) return;
    final name = g.name.isNotEmpty ? g.name : (g.hostname.isNotEmpty ? g.hostname : g.id);
    final ok = await showConfirmDialog(
      context,
      title: 'Xoá gateway?'.tr,
      message:
          'Gateway "{name}" sẽ bị xoá khỏi điện thoại này. Muốn dùng lại phải thêm gateway lại.'.trArgs({'name': name}),
      confirmLabel: 'Xoá'.tr,
    );
    if (!ok) return;
    await _store.forget(g.id);
    if (!mounted) return;
    setState(() => _online.remove(g.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xoá gateway "{name}"'.trArgs({'name': name}))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Quản lý thiết bị'.tr,
                actions: [
                  if (AuthStore.instance.isAdmin)
                    IconButton(
                      tooltip: 'Bảo trì Gateway'.tr,
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MaintainWebScreen(
                          gateway: _store.savedGateways.isEmpty ? null : _store.selectedGateway,
                        ),
                      )),
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'Thêm Gateway'.tr,
                    icon: const Icon(Icons.add_rounded),
                    color: AppColors.card,
                    onSelected: (v) => v == 'ip' ? _addByIp() : _addGateway(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'qr',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.qr_code_scanner_rounded),
                          title: Text('Quét mã QR'.tr),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'ip',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lan_outlined),
                          title: Text('Nhập địa chỉ IP'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _store,
                  builder: (context, _) {
                    // Demo gateways always follow the real ones (for showing the app).
                    final real = _store.savedGateways;
                    final gateways = [...real, ...DemoGateway.gateways];
                    final selectedId = _store.selectedGateway?.id;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.accent,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        children: [
                          _Summary(
                            total: gateways.length,
                            online: DemoGateway.gateways.length + _online.values.where((v) => v == true).length,
                          ),
                          const SizedBox(height: 16),
                          for (final g in gateways)
                            if (DemoGateway.isDemo(g.id)) ...[
                              _GatewayCard(
                                gateway: g,
                                online: true,
                                isCurrent: false,
                                isDemo: true,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => GatewayDetailScreen(gateway: g),
                                )),
                              ),
                              const SizedBox(height: 12),
                            ] else ...[
                              _GatewayCard(
                                gateway: g,
                                online: _online[g.id],
                                isCurrent: g.id == selectedId,
                                onDelete: AuthStore.instance.isAdmin ? () => _removeGateway(g) : null,
                                onTap: () async {
                                  await Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => GatewayDetailScreen(gateway: g),
                                  ));
                                  if (mounted) _refresh();
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          if (real.isEmpty) ...[
                            const SizedBox(height: 4),
                            Center(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                                onPressed: _addGateway,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                                label: Text('Thêm Gateway'.tr),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int total;
  final int online;
  const _Summary({required this.total, required this.online});

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String value, Color color, IconData icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppColors.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(height: 14),
                Text(value,
                    style:
                        TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        tile('Gateway'.tr, '$total', AppIconColors.blue, Icons.router_rounded),
        const SizedBox(width: 12),
        tile('Đang online'.tr, '$online', AppIconColors.green, Icons.wifi_tethering_rounded),
      ],
    );
  }
}

class _GatewayCard extends StatelessWidget {
  final SavedGateway gateway;
  final bool? online;
  final bool isCurrent;
  final bool isDemo;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _GatewayCard({
    required this.gateway,
    required this.online,
    required this.isCurrent,
    required this.onTap,
    this.onDelete,
    this.isDemo = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (online) {
      null => (AppColors.textMuted, 'Đang kiểm tra…'.tr),
      true => (AppColors.success, 'Online'),
      false => (AppColors.danger, 'Offline'),
    };
    final name = isDemo
        ? gateway.name.tr
        : (gateway.name.isNotEmpty ? gateway.name : (gateway.hostname.isNotEmpty ? gateway.hostname : gateway.id));

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        side: isCurrent ? BorderSide(color: AppColors.accent, width: 1.4) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
          child: Row(
            children: [
              GatewayAvatar(gateway: gateway),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        ),
                        if (isCurrent || isDemo) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDemo ? AppColors.warning : AppColors.accent).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(isDemo ? 'Mẫu'.tr : 'Đang dùng'.tr,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDemo ? AppColors.warning : AppColors.accent)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [if (gateway.ip.isNotEmpty) gateway.address, gateway.id].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Xoá gateway'.tr,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
                  onPressed: onDelete,
                )
              else
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
