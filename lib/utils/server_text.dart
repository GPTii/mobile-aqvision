import 'app_strings.dart';

/// Server-generated notification messages (html5stream `alertWorker.ts`,
/// `api/system/alerts`, `api/proxies`) arrive already rendered in Vietnamese
/// with the camera name baked in. Each template here is also a key in
/// [AppStrings], so a matching message is re-rendered in the app language.
const _templates = [
  // worker/alertWorker.ts
  'Camera "{cam}" thuộc ứng dụng "{app}" đang offline.',
  'Camera "{cam}" thuộc ứng dụng "{app}" đã online trở lại.',
  // api/system/alerts/route.ts
  'Camera "{cam}" (ứng dụng: {app}) đang mất kết nối.',
  'Camera "{cam}" (ứng dụng: {app}) đã được ngắt kết nối thủ công.',
  'Camera "{cam}" (ứng dụng: {app}) đã được thêm vào hệ thống.',
  'Camera "{cam}" (ứng dụng: {app}) đang hoạt động (vừa được kết nối lại hoặc cập nhật).',
  // api/proxies
  'Camera "{cam}" đã được thêm vào hệ thống với trạng thái {status}.',
  'Camera "{cam}" đã bị xóa khỏi hệ thống.',
  'Camera "{cam}" đã bị ngắt kết nối thủ công.',
  'Camera "{cam}" đã được kết nối lại thủ công.',
];

final _placeholder = RegExp(r'\{(\w+)\}');

final List<(String, RegExp, List<String>)> _compiled = [
  for (final t in _templates)
    (
      t,
      RegExp('^${t.split(_placeholder).map(RegExp.escape).join('(.+?)')}\$'),
      [for (final m in _placeholder.allMatches(t)) m.group(1)!],
    ),
];

/// Translates a notification title / message coming from the server.
/// Unknown text is returned unchanged.
String localizeServerText(String text) {
  final s = text.trim();
  if (s.isEmpty) return text;
  for (final (template, re, names) in _compiled) {
    final m = re.firstMatch(s);
    if (m == null) continue;
    return template.trArgs({
      for (var i = 0; i < names.length; i++) names[i]: m.group(i + 1),
    });
  }
  return s.tr;
}
