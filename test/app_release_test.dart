import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/app_release_store.dart';

void main() {
  // Shape of one element of `GET /api/v1/app-releases` → `data`.
  final json = <String, dynamic>{
    'version': '1.0.9',
    'buildNumber': 10,
    'releasedAt': '2026-08-28T05:00:00.000Z',
    'teaser': 'Sửa lỗi ghi hình.',
    'sections': [
      {
        'kind': 'improvement',
        'items': ['Tab Báo cáo hiển thị ngay dữ liệu đã tải lần trước.'],
      },
      {
        'kind': 'fix',
        'items': ['Sửa lỗi A.', 'Sửa lỗi B.'],
      },
      {
        'kind': 'note',
        'items': ['Khuyến nghị cập nhật.'],
      },
      // A kind this app version does not know must be skipped, not crash.
      {
        'kind': 'brand_new_kind',
        'items': ['x'],
      },
      // Empty sections are dropped.
      {'kind': 'new_feature', 'items': <String>[]},
    ],
  };

  test('AppVersion.fromJson maps the server payload', () {
    final v = AppVersion.fromJson(json, isLatest: true);

    expect(v.version, '1.0.9');
    expect(v.buildLabel, 'Build 10');
    expect(v.isLatest, isTrue);
    expect(v.teaser.vi, 'Sửa lỗi ghi hình.');
    expect(v.name, 'AQPConnect-1.0.9-release');
    expect(v.sections.map((s) => s.kind).toList(), [
      ReleaseNoteKind.improvement,
      ReleaseNoteKind.fix,
      ReleaseNoteKind.note,
    ]);
    expect(v.sections[1].items.map((t) => t.vi), ['Sửa lỗi A.', 'Sửa lỗi B.']);
    expect(v.releasedAt.toUtc(), DateTime.utc(2026, 8, 28, 5));
  });

  test('AppVersion.fromJson tolerates missing fields', () {
    final v = AppVersion.fromJson({'version': '2.0.0'});

    expect(v.version, '2.0.0');
    expect(v.buildNumber, 0);
    expect(v.sections, isEmpty);
    expect(v.teaser.vi, '');
  });
}
