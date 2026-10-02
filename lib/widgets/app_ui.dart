import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared building blocks of the app's visual style: a soft brand-tinted
/// page gradient, borderless rounded white cards, list rows with colourful
/// bare icons, and big bold page titles.

/// Full-screen page background (brand tint at the top fading to grey).
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.pageGradient),
      child: child,
    );
  }
}

/// Big bold page title with optional trailing actions, sitting directly on
/// the page gradient (no coloured header block).
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 14, 12, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Round icon button used in page headers (scan, add, settings…).
class AppHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final Widget? badge;

  const AppHeaderButton({super.key, required this.icon, this.onTap, this.tooltip, this.badge});

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 26, color: AppColors.textPrimary),
    );
    if (badge == null) return button;
    return Stack(clipBehavior: Clip.none, children: [
      button,
      Positioned(top: 6, right: 6, child: badge!),
    ]);
  }
}

/// Small red dot used as an "unread / new" marker.
class AppDot extends StatelessWidget {
  const AppDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
    );
  }
}

/// Borderless white rounded card. Children are stacked without dividers.
class AppCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const AppCard({super.key, required this.children, this.padding = const EdgeInsets.symmetric(vertical: 6)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Section title above a card ("Trải nghiệm", "Hệ thống"…).
class AppSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const AppSectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 22, 6, 10),
      child: Row(
        children: [
          Expanded(
            child:
                Text(text, style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// List row: bare colourful icon, bold title, optional grey subtitle,
/// trailing text / widget / chevron, optional red dot.
class AppListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailing;
  final bool showDot;
  final bool danger;
  final VoidCallback? onTap;

  const AppListTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailing,
    this.showDot = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 14, 12),
          child: Row(
            children: [
              Icon(icon, size: 26, color: danger ? AppColors.danger : iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: danger ? AppColors.danger : AppColors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, height: 1.35)),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                if (trailingText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 2),
                    child: Text(trailingText!,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, fontWeight: FontWeight.w500)),
                  ),
                if (showDot) const Padding(padding: EdgeInsets.only(left: 6, right: 2), child: AppDot()),
                if (!danger && onTap != null)
                  Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.textMuted.withValues(alpha: 0.7)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
