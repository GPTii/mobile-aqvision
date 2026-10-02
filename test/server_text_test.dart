import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/app_theme_store.dart';
import 'package:mobile/utils/server_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> lang(String code) => AppThemeStore.instance.setLanguage(code);

  test('camera offline alert follows the app language', () async {
    const title = 'Camera mất kết nối';
    const msg = 'Camera "cong-chinh" thuộc ứng dụng "live" đang offline.';

    await lang('vi');
    expect(localizeServerText(title), title);
    expect(localizeServerText(msg), msg);

    await lang('en');
    expect(localizeServerText(title), 'Camera disconnected');
    expect(localizeServerText(msg), 'Camera "cong-chinh" in app "live" is offline.');

    await lang('ko');
    expect(localizeServerText(msg), '앱 "live"의 카메라 "cong-chinh"이(가) 오프라인입니다.');
  });

  test('camera names with quotes / parentheses still match', () async {
    await lang('en');
    expect(localizeServerText('Camera "Kho (tầng 2)" (ứng dụng: live) đang mất kết nối.'),
        'Camera "Kho (tầng 2)" (app: live) has lost connection.');
    expect(localizeServerText('Camera "a.b*c" đã được kết nối lại thủ công.'),
        'Camera "a.b*c" was reconnected manually.');
  });

  test('unknown text is left alone', () async {
    await lang('en');
    expect(localizeServerText('Something new from the server'), 'Something new from the server');
    expect(localizeServerText(''), '');
  });
}
