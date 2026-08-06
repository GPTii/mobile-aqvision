import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/screens/home/camera_detail_screen.dart';
import 'package:mobile/screens/home/record_list_screen.dart';
import 'package:mobile/screens/home/tabs/camera_tab.dart';
import 'package:mobile/screens/home/tabs/home_tab.dart';

void main() {
  testWidgets('Shows the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RapidMediaApp());

    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
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

    await tester.pumpWidget(
      const MaterialApp(
        home: CameraDetailScreen(
          name: 'Cổng chính',
          location: 'Tầng 1 · Lối vào',
          online: true,
        ),
      ),
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
      const MaterialApp(home: RecordListScreen()),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
