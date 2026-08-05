import 'package:flutter/material.dart';

import '../../../widgets/coming_soon_view.dart';

class ReportTab extends StatelessWidget {
  const ReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      icon: Icons.bar_chart_rounded,
      title: 'Báo cáo',
      subtitle: 'Thống kê hoạt động camera và\nbáo cáo sự cố sẽ hiển thị tại đây.',
    );
  }
}
