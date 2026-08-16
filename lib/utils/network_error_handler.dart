import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();
bool _isShowingNetworkError = false;

void showNetworkErrorDialog() {
  final context = globalNavigatorKey.currentContext;
  if (context == null || _isShowingNetworkError) return;

  _isShowingNetworkError = true;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update_alt_rounded, color: Colors.blueAccent),
            SizedBox(width: 10),
            Text('Thông báo hệ thống', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Ứng dụng đang được cập nhật. Không thể kết nối tới máy chủ lúc này. Vui lòng thử lại sau!',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isShowingNetworkError = false;
              Navigator.of(context).pop();
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      );
    },
  ).then((_) {
    _isShowingNetworkError = false;
  });
}
