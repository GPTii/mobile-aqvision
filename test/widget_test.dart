import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/data/camera_store.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/notifications_screen.dart';
import 'package:mobile/screens/home/camera_detail_screen.dart';
import 'package:mobile/screens/home/record_list_screen.dart';
import 'package:mobile/screens/home/tabs/camera_tab.dart';
import 'package:mobile/screens/home/tabs/home_tab.dart';
import 'package:mobile/screens/home/tabs/profile_tab.dart';

void main() {
  testWidgets('Shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RapidMediaApp());

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Logging in with the demo account opens the home shell', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RapidMediaApp());

    await tester.enterText(find.byType(TextFormField).first, 'admin');
    await tester.enterText(find.byType(TextFormField).last, 'admin');
    await tester.tap(find.text('Đăng nhập').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Camera'), findsWidgets);
    expect(find.text('Báo cáo'), findsWidgets);
    expect(find.text('Hồ sơ'), findsWidgets);
  });

  testWidgets('Home tab does not overflow on a narrow screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: HomeTab()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Camera tab does not overflow on a narrow screen in grid or list view', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: CameraTab()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Toggle to list view and back.
    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Camera detail screen does not overflow on a narrow screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cameraId = CameraStore.instance.cameras.first.id;

    await tester.pumpWidget(
      MaterialApp(home: CameraDetailScreen(cameraId: cameraId)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Record list screen does not overflow on a narrow screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: RecordingListScreen(cameraId: 'test')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile tab does not overflow on a narrow screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ProfileTab()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Notifications screen does not overflow on a narrow screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: NotificationsScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Notification bell on Camera tab opens the notifications screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CameraTab()));
    await tester.pumpAndSettle();

    // Two of the seeded notifications start unread.
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Thông báo'), findsOneWidget);
    expect(find.text('Cài đặt cảnh báo'), findsOneWidget);

    await tester.tap(find.text('Đánh dấu đã đọc'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNothing);
  });

  testWidgets('Adding a camera from the Camera tab shows it in the list', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CameraTab()));
    await tester.pumpAndSettle();

    // Switch to list view so the new camera's name is visible.
    await tester.tap(find.byIcon(Icons.view_list_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm camera'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm camera mới'), findsOneWidget, reason: 'form sheet should be open');

    // Fields in order: Tên camera, Camera ID, Địa chỉ IP, Vị trí lắp đặt.
    // Camera ID and IP come pre-filled with suggested values; only the name
    // and installation location need to be entered for the form to validate.
    final formFields = find.byType(TextFormField);
    await tester.enterText(formFields.at(0), 'Camera Kiểm Thử');
    await tester.enterText(formFields.at(3), 'Góc test tự động');

    final saveButton = find.text('Thêm camera');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Thêm camera mới'), findsNothing, reason: 'form sheet should be closed');

    // The new camera is appended at the end of the (lazily built) list, so
    // scroll it into view before asserting it rendered correctly.
    await tester.scrollUntilVisible(
      find.text('Camera Kiểm Thử'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Camera Kiểm Thử'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
