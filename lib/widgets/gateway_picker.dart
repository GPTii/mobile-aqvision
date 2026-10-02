import 'package:flutter/material.dart';

import '../data/gateway_session_store.dart';
import '../data/gateway_store.dart';
import '../screens/devices/device_management_screen.dart';
import '../screens/setup/qr_scanner_screen.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

/// Display name of a home/gateway in the header picker.
String gatewayLabel(SavedGateway g) {
  if (GatewaySessionStore.isSample(g.id)) return g.name.tr;
  if (g.name.isNotEmpty) return g.name;
  if (g.hostname.isNotEmpty) return g.hostname;
  return g.id;
}

/// Header title that doubles as the home/gateway switcher: tapping it drops a
/// panel down from right under the title (not a bottom sheet).
///
/// With [filter] the picker filters the page it sits on and adds an
/// "Tất cả" (all) entry — `null` in [filter]. Picking a home then also
/// switches the selected gateway only when [selectsGateway] is set.
/// Without [filter], picking always changes the selected gateway.
class GatewayPicker extends StatefulWidget {
  final double fontSize;
  final ValueNotifier<String?>? filter;
  final bool selectsGateway;
  const GatewayPicker({super.key, this.fontSize = 18, this.filter, this.selectsGateway = false});

  @override
  State<GatewayPicker> createState() => _GatewayPickerState();
}

sealed class _PickerAction {}

class _PickGateway extends _PickerAction {
  final SavedGateway gateway;
  _PickGateway(this.gateway);
}

class _PickAll extends _PickerAction {}

class _OpenDevices extends _PickerAction {}

class _AddGateway extends _PickerAction {}

class _GatewayPickerState extends State<GatewayPicker> {
  final _store = GatewaySessionStore.instance;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _store.loadSaved();
  }

  Future<void> _toggle() async {
    final box = context.findRenderObject() as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    _store.loadSaved();
    setState(() => _open = true);
    final filter = widget.filter;
    final action = await nav.push(_DropdownRoute(
      anchor: anchor,
      showAll: filter != null,
      selectedId: () => filter != null ? filter.value : _store.selectedGateway?.id,
    ));
    if (!mounted) return;
    setState(() => _open = false);

    switch (action) {
      case _PickAll():
        filter?.value = null;
      case _PickGateway(:final gateway):
        filter?.value = gateway.id;
        if (filter != null && !widget.selectsGateway) return;
        if (gateway.id == _store.selectedGateway?.id &&
            (_store.isConnected || GatewaySessionStore.isSample(gateway.id))) {
          return;
        }
        final ok = await _store.select(gateway.id);
        if (!ok) {
          messenger.showSnackBar(SnackBar(content: Text(_store.error ?? 'Không kết nối được gateway'.tr)));
        }
      case _OpenDevices():
        nav.push(MaterialPageRoute(builder: (_) => const DeviceManagementScreen()));
      case _AddGateway():
        await nav.push(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
        _store.loadSaved();
      case null:
        break;
    }
  }

  /// Name of the picked home, or null for "Tất cả" in filter mode.
  String? _label() {
    final filter = widget.filter;
    if (filter == null) return gatewayLabel(_store.selectedGateway!);
    for (final g in _store.homes) {
      if (g.id == filter.value) return gatewayLabel(g);
    }
    return null; // unset, or a home that no longer exists
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: ListenableBuilder(
        listenable: Listenable.merge([_store, if (widget.filter != null) widget.filter!]),
        builder: (context, _) {
          final label = _label();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(label == null ? Icons.apps_rounded : Icons.home_rounded,
                  color: AppColors.textPrimary, size: widget.fontSize + 6),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label ?? 'Tất cả'.tr,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textPrimary, size: 20),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Transparent route that drops [_DropdownPanel] down from [anchor].
class _DropdownRoute extends PopupRoute<_PickerAction> {
  final Rect anchor;
  final bool showAll;
  final String? Function() selectedId;
  _DropdownRoute({required this.anchor, required this.showAll, required this.selectedId});

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.12);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Đóng'.tr;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final screen = MediaQuery.of(context).size;
    final width = (screen.width - 24).clamp(0.0, 340.0);
    final left = anchor.left.clamp(12.0, screen.width - width - 12);
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);

    return Stack(
      children: [
        Positioned(
          left: left,
          top: anchor.bottom + 6,
          width: width,
          child: FadeTransition(
            opacity: curved,
            child: SizeTransition(
              sizeFactor: curved,
              axisAlignment: -1,
              child: _DropdownPanel(maxHeight: screen.height * 0.6, showAll: showAll, selectedId: selectedId),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownPanel extends StatelessWidget {
  final double maxHeight;
  final bool showAll;
  final String? Function() selectedId;
  const _DropdownPanel({required this.maxHeight, required this.showAll, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    final store = GatewaySessionStore.instance;
    return Material(
      color: AppColors.card,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final homes = store.homes;
            final selectedId = this.selectedId();
            final allSelected = showAll && !homes.any((g) => g.id == selectedId);
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                if (showAll)
                  _Row(
                    icon: allSelected ? Icons.check_circle_rounded : Icons.apps_rounded,
                    iconColor: allSelected ? AppColors.accent : AppColors.textMuted,
                    title: 'Tất cả'.tr,
                    subtitle: 'Xem camera của mọi nơi'.tr,
                    bold: allSelected,
                    onTap: () => Navigator.pop(context, _PickAll()),
                  ),
                for (final g in homes)
                  _Row(
                    icon: g.id == selectedId ? Icons.check_circle_rounded : Icons.home_outlined,
                    iconColor: g.id == selectedId ? AppColors.accent : AppColors.textMuted,
                    title: gatewayLabel(g),
                    subtitle: g.ip.isEmpty ? null : g.address,
                    bold: g.id == selectedId,
                    trailing: !showAll && g.id == selectedId && store.connecting
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        : null,
                    onTap: () => Navigator.pop(context, _PickGateway(g)),
                  ),
                Divider(height: 12, color: AppColors.divider),
                _Row(
                  icon: Icons.router_outlined,
                  iconColor: AppColors.textSecondary,
                  title: 'Quản lý thiết bị'.tr,
                  trailing: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  onTap: () => Navigator.pop(context, _OpenDevices()),
                ),
                _Row(
                  icon: Icons.add_rounded,
                  iconColor: AppColors.accent,
                  title: 'Thêm Gateway'.tr,
                  titleColor: AppColors.accent,
                  onTap: () => Navigator.pop(context, _AddGateway()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final bool bold;
  final Widget? trailing;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.titleColor,
    this.bold = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: titleColor ?? AppColors.textPrimary,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                      )),
                  if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
