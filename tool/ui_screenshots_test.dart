// Renders screens to PNG for design review (no device needed):
//   flutter test tool/ui_screenshots_test.dart
// Output: build/ui_shots/<name>.png at 390x844 @3x (iPhone 14-ish).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/app_theme_store.dart';
import 'package:mobile/data/camera_store.dart';
import 'package:mobile/screens/home/home_shell.dart';
import 'package:mobile/screens/account_info_screen.dart';
import 'package:mobile/screens/auth/login_screen.dart';
import 'package:mobile/screens/cloud_storage_screen.dart';
import 'package:mobile/screens/devices/demo_gateway_data.dart';
import 'package:mobile/screens/devices/gateway_detail_screen.dart';
import 'package:mobile/screens/edit_account_screen.dart';
import 'package:mobile/screens/gallery_screen.dart';
import 'package:mobile/screens/home/camera_detail_screen.dart';
import 'package:mobile/screens/home/groups_screen.dart';
import 'package:mobile/screens/home/record_list_screen.dart';
import 'package:mobile/screens/home/version_history_screen.dart';
import 'package:mobile/screens/notifications_screen.dart';
import 'package:mobile/screens/service_package_screen.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

String get _flutterRoot => Platform.environment['FLUTTER_ROOT']!;

Future<void> _loadFonts() async {
  final dir = '$_flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final f in ['roboto-regular', 'roboto-medium', 'roboto-bold', 'roboto-black', 'roboto-light']) {
    final file = File('$dir/$f.ttf');
    if (file.existsSync()) roboto.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$dir/materialicons-regular.otf').readAsBytesSync())));
  await icons.load();
}

final _boundary = GlobalKey();

Future<void> pumpApp(WidgetTester tester, Widget screen, {bool dark = false}) async {
  AppColors.updateTheme(dark);
  await tester.pumpWidget(const SizedBox()); // drop old state so colours rebuild
  await tester.pumpWidget(RepaintBoundary(
    key: _boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.accent, brightness: dark ? Brightness.dark : Brightness.light),
        fontFamily: 'Roboto',
        // Transparent app bars sit on the page gradient (AppBackground).
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          titleTextStyle: TextStyle(
              fontFamily: 'Roboto', color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(390, 844), devicePixelRatio: 3, padding: EdgeInsets.only(top: 47, bottom: 34)),
        child: screen,
      ),
    ),
  ));
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = _boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/ui_shots/$name.png')..createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> shoot(WidgetTester tester, String name, Widget screen, {bool dark = false}) async {
  await pumpApp(tester, screen, dark: dark);
  await capture(tester, name);
}

void seedCameras() {
  Camera cam(String id, String name, List<String> groups, {bool online = true}) => Camera(
        id: id,
        name: name,
        cameraCode: 'cam$id',
        type: 'Camera Dome',
        ipAddress: '192.168.1.1$id',
        location: '',
        groupIds: groups,
        online: online,
        lastSeen: '15:0$id',
      );
  CameraStore.instance.debugSeed(
    groups: [CameraGroup(id: 'g1', name: 'Phòng khách'), CameraGroup(id: 'g2', name: 'Cổng chính')],
    cameras: [
      cam('1', 'Cam phòng khách', ['g1']),
      cam('2', 'Cam bếp', ['g1']),
      cam('3', 'Cam hành lang', ['g1'], online: false),
      cam('4', 'Cổng trước', ['g2']),
    ],
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
  });

  testWidgets('screens', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await AppThemeStore.instance.setLanguage('vi');
    seedCameras();

    for (final dark in [false, true]) {
      final sfx = dark ? '_dark' : '';
      await pumpApp(tester, const HomeShell(), dark: dark);
      await capture(tester, 'home$sfx');
      for (final (label, name) in [('Camera', 'camera'), ('Thiết bị', 'devices'), ('Cài đặt', 'settings')]) {
        await tester.tap(find.text(label).last);
        await settle(tester);
        await capture(tester, '$name$sfx');
      }
    }
    // Let periodic timers (clock, polling) run out before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });

  testWidgets('sub screens', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await AppThemeStore.instance.setLanguage('vi');
    seedCameras();

    final screens = <String, Widget>{
      'sub_login': const LoginScreen(),
      'sub_account': const AccountInfoScreen(),
      'sub_edit_account': const EditAccountScreen(),
      'sub_cloud': const CloudStorageScreen(),
      'sub_package': const ServicePackageScreen(),
      'sub_notifications': const NotificationsScreen(),
      'sub_versions': const VersionHistoryScreen(),
      'sub_groups': const GroupsScreen(),
      'sub_gallery': const GalleryScreen(),
      'sub_camera_detail': const CameraDetailScreen(cameraId: '1'),
      'sub_recordings': const RecordingListScreen(cameraId: '1'),
      'sub_gateway': GatewayDetailScreen(gateway: DemoGateway.gateways.first),
    };
    for (final e in screens.entries) {
      try {
        await pumpApp(tester, e.value);
        tester.takeException();
        await capture(tester, e.key);
      } catch (err) {
        // ignore: avoid_print
        print('SHOT FAILED ${e.key}: $err');
      }
      tester.takeException();
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });
}
