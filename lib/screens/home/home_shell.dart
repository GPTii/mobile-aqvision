import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'tabs/camera_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/notification_tab.dart';
import 'tabs/report_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _tabs = [
    HomeTab(),
    CameraTab(),
    NotificationTab(),
    ReportTab(),
  ];

  static const _navItems = [
    _NavItemData(icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: 'Trang chủ'),
    _NavItemData(icon: Icons.videocam_rounded, outlineIcon: Icons.videocam_outlined, label: 'Camera'),
    _NavItemData(icon: Icons.notifications_rounded, outlineIcon: Icons.notifications_outlined, label: 'Thông báo'),
    _NavItemData(icon: Icons.bar_chart_rounded, outlineIcon: Icons.bar_chart_outlined, label: 'Báo cáo'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData outlineIcon;
  final String label;

  const _NavItemData({required this.icon, required this.outlineIcon, required this.label});
}

/// Flush, edge-to-edge bottom navigation bar — no floating card, no side
/// margins, and its background extends all the way into the bottom safe
/// area so there's no gap below it either.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final selected = index == currentIndex;
              return Expanded(
                child: _NavItem(
                  data: items[index],
                  selected: selected,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.data, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(selected ? data.icon : data.outlineIcon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              data.label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
