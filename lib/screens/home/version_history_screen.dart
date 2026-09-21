import 'package:flutter/material.dart';

import '../../data/app_release_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';

class _KindStyle {
  final String label;
  final IconData icon;
  final Color color;
  final Color tint;

  const _KindStyle(this.label, this.icon, this.color, this.tint);
}

final Map<ReleaseNoteKind, _KindStyle> _kindStyles = {
  ReleaseNoteKind.newFeature: _KindStyle(
      'Tính năng mới', Icons.auto_awesome_rounded, AppColors.info, Color(0xFFEAF1FF)),
  ReleaseNoteKind.improvement: _KindStyle(
      'Cải tiến', Icons.trending_up_rounded, AppColors.success, Color(0xFFE6F7F0)),
  ReleaseNoteKind.fix: _KindStyle(
      'Sửa lỗi', Icons.check_circle_outline_rounded, AppColors.warning, Color(0xFFFDF1DE)),
  ReleaseNoteKind.note: _KindStyle(
      'Lưu ý đặc biệt', Icons.error_outline_rounded, AppColors.danger, Color(0xFFFDEAEC)),
};

class VersionHistoryScreen extends StatefulWidget {
  const VersionHistoryScreen({super.key});

  @override
  State<VersionHistoryScreen> createState() => _VersionHistoryScreenState();
}

class _VersionHistoryScreenState extends State<VersionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    AppReleaseStore.instance.fetchReleases();
  }

  Widget _buildBody(AppReleaseStore store) {
    if (store.releases.isEmpty) {
      if (store.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (store.error != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(store.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: store.fetchReleases,
                  child: Text('Thử lại'.tr),
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Text('Chưa có bản cập nhật nào'.tr,
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
      );
    }

    return RefreshIndicator(
      onRefresh: store.fetchReleases,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: store.releases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _VersionListTile(store.releases[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppReleaseStore.instance,
      builder: (context, _) {
        final store = AppReleaseStore.instance;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lịch sử phiên bản'.tr,
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${store.releases.length} ${'bản cập nhật gần đây'.tr}',
                                style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _buildBody(store)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VersionListTile extends StatelessWidget {
  final AppVersion version;

  const _VersionListTile(this.version);

  @override
  Widget build(BuildContext context) {
    final counts = <ReleaseNoteKind, int>{};
    for (final s in version.sections) {
      counts[s.kind] = (counts[s.kind] ?? 0) + s.items.length;
    }

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VersionDetailScreen(version: version)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: version.isLatest ? const Color(0xFFFDEAEC) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      version.version,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: version.isLatest ? AppColors.accentSecondary : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      version.buildLabel.toUpperCase(),
                      style: TextStyle(
                          fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${'Phiên bản'.tr} ${version.version}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        if (version.isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDEAEC),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('MỚI NHẤT'.tr,
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentSecondary, letterSpacing: 0.2)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(version.dateLabel, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(version.teaser.tr,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: counts.entries.map((e) {
                        final style = _kindStyles[e.key]!;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: style.tint, borderRadius: BorderRadius.circular(7)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(style.icon, size: 11, color: style.color),
                              const SizedBox(width: 4),
                              Text('${e.value} ${style.label.tr.toLowerCase()}',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: style.color)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class VersionDetailScreen extends StatelessWidget {
  final AppVersion version;

  const VersionDetailScreen({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${'Phiên bản'.tr} ${version.version}',
                                  style: TextStyle(
                                      color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                              if (version.isLatest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text('MỚI NHẤT'.tr,
                                      style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accentSecondary, letterSpacing: 0.2)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${version.buildLabel} · ${version.dateLabel}',
                              style: TextStyle(
                                  fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  for (final section in version.sections) _SectionBlock(section),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final ReleaseSection section;

  const _SectionBlock(this.section);

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    final style = _kindStyles[section.kind]!;

    if (section.kind == ReleaseNoteKind.note) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: style.tint, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(style.icon, size: 16, color: style.color),
            const SizedBox(width: 9),
            Expanded(
              child: Text(section.items.map((i) => i.tr).join(' '),
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textPrimary)),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color: style.tint, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Icon(style.icon, size: 13, color: style.color),
              ),
              const SizedBox(width: 7),
              Text(style.label.tr.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: style.color, letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < section.items.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: i == 0 ? Colors.transparent : AppColors.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(style.icon, size: 15, color: style.color),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(section.items[i].tr,
                        style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
