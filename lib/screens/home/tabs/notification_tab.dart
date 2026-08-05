import 'package:flutter/material.dart';

import '../../../widgets/coming_soon_view.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      icon: Icons.notifications_rounded,
      title: 'Thông báo',
      subtitle: 'Cảnh báo chuyển động, mất kết nối và\nsự kiện hệ thống sẽ hiển thị tại đây.',
    );
  }
}
