import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';

enum ReleaseNoteKind { newFeature, improvement, fix, note }

class ReleaseSection {
  final ReleaseNoteKind kind;
  final List<String> items;

  const ReleaseSection(this.kind, this.items);
}

class AppVersion {
  final String version;
  final String build;
  final String date;
  final String teaser;
  final bool isLatest;
  final List<ReleaseSection> sections;

  const AppVersion({
    required this.version,
    required this.build,
    required this.date,
    required this.teaser,
    required this.sections,
    this.isLatest = false,
  });
}

/// Ordered newest-first. Update this list whenever `pubspec.yaml`'s version
/// bumps — nothing reads it automatically from the build number.
const List<AppVersion> kAppVersionHistory = [
  AppVersion(
    version: '1.1.0',
    build: 'Build 12',
    date: '4 tháng 9, 2026',
    teaser: 'Đổi tab Hồ sơ thành Cài đặt, thêm chế độ tối, đa ngôn ngữ và thư viện ảnh.',
    isLatest: true,
    sections: [
      ReleaseSection(ReleaseNoteKind.newFeature, [
        'Đổi tab "Hồ sơ" thành "Cài đặt" — thiết kế lại toàn bộ bố cục, phân nhóm rõ ràng, gọn gàng và dễ dùng hơn hẳn.',
        'Thêm chế độ giao diện Sáng / Tối, đổi được ngay trong app.',
        'Thêm chuyển đổi ngôn ngữ Tiếng Việt / English.',
        'Thêm Thư viện ảnh để xem lại các ảnh đã chụp từ camera.',
        'Thêm mục Thông tin doanh nghiệp trong Tài khoản & bảo mật — nhập và lưu lại được ngay trong app.',
      ]),
      ReleaseSection(ReleaseNoteKind.improvement, [
        'Tab Báo cáo hỗ trợ đổi sang tiếng Anh (trước đây chỉ có tiếng Việt).',
        'Màn "Gói dịch vụ" thiết kế lại gọn gàng, dễ nhìn hơn, nút Nâng cấp gói rõ ràng hơn.',
        'Chỉnh sửa thông tin cá nhân chuyển từ cửa sổ nhỏ sang trang riêng để chứa được nhiều thông tin hơn.',
        'Mục "Nhật ký" hiện sẵn số phiên bản đang dùng, không cần bấm vào mới biết.',
      ]),
    ],
  ),
  AppVersion(
    version: '1.0.10',
    build: 'Build 11',
    date: '28 tháng 8, 2026',
    teaser: 'Thêm màn hình Lịch sử phiên bản ngay trong Hồ sơ.',
    sections: [
      ReleaseSection(ReleaseNoteKind.newFeature, [
        'Thêm màn hình "Lịch sử phiên bản" trong Hồ sơ — xem nhanh các bản cập nhật, tính năng mới và lỗi đã sửa ngay trong app, không cần hỏi lại đội kỹ thuật.',
      ]),
    ],
  ),
  AppVersion(
    version: '1.0.9',
    build: 'Build 10',
    date: '28 tháng 8, 2026',
    teaser: 'Sửa lỗi ghi hình, chụp ảnh camera và hiển thị dung lượng Cloud.',
    sections: [
      ReleaseSection(ReleaseNoteKind.improvement, [
        'Tab Báo cáo hiển thị ngay dữ liệu dung lượng đã tải lần trước ngay khi vừa mở tab, không phải chờ trắng màn hình mỗi lần vào.',
      ]),
      ReleaseSection(ReleaseNoteKind.fix, [
        'Nút "Chụp" trên camera trực tiếp trước đây không lưu được ảnh nào — nay chụp và lưu ảnh thật, có xem trước và xác nhận Lưu / Xoá.',
        'Sửa thông báo sai "Phiên ghi hình hết hạn, hãy đăng nhập lại" xuất hiện dù tài khoản vẫn đang đăng nhập bình thường.',
        'Sửa lỗi mục "Camera chiếm nhiều dung lượng nhất" luôn hiển thị 0 MB dù camera đã có dữ liệu ghi hình thật.',
      ]),
      ReleaseSection(ReleaseNoteKind.note, [
        'Khuyến nghị cập nhật cho các thiết bị đang gặp lỗi khi nhấn ghi hình hoặc chụp ảnh camera.',
      ]),
    ],
  ),
  AppVersion(
    version: '1.0.5',
    build: 'Build 8',
    date: '19 tháng 8, 2026',
    teaser: 'Thêm yêu cầu nâng cấp gói ngay trong app, ổn định kết nối camera.',
    sections: [
      ReleaseSection(ReleaseNoteKind.newFeature, [
        'Thêm luồng gửi yêu cầu nâng cấp gói dịch vụ ngay trong app, có thể kèm lời nhắn.',
        'Trang Hồ sơ hiển thị thông tin gói dịch vụ và dung lượng lưu trữ đang dùng.',
      ]),
      ReleaseSection(ReleaseNoteKind.improvement, [
        'Khoá xoay màn hình dọc để thao tác ổn định hơn khi xem camera.',
        'Tinh gọn tab Báo cáo: gộp về tổng quan hệ thống và dung lượng Cloud, bớt rối mắt.',
        'Cải thiện độ ổn định khi xem camera trực tiếp qua WebRTC.',
      ]),
      ReleaseSection(ReleaseNoteKind.fix, [
        'Sửa lỗi phát lại video HLS bị gián đoạn ở một số camera.',
        'Sửa lỗi truy cập file ghi hình khi kết nối qua máy chủ proxy.',
        'Sửa một số lỗi hiển thị ở màn hình chi tiết camera.',
      ]),
    ],
  ),
];

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

class VersionHistoryScreen extends StatelessWidget {
  const VersionHistoryScreen({super.key});

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
                          Text(
                            'Lịch sử phiên bản'.tr,
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${kAppVersionHistory.length} ${'bản cập nhật gần đây'.tr}',
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: kAppVersionHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _VersionListTile(kAppVersionHistory[i]),
              ),
            ),
          ],
        ),
      ),
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
                      version.build.toUpperCase(),
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
                    Text(version.date.tr, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
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
                          Text('${version.build} · ${version.date.tr}',
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
