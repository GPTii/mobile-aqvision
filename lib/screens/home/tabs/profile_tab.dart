import 'package:flutter/material.dart';

import '../../../widgets/coming_soon_view.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(
      icon: Icons.person_rounded,
      title: 'Hồ sơ cá nhân',
      subtitle: 'Thông tin tài khoản và cài đặt cá nhân\nsẽ hiển thị tại đây.',
    );
  }
}
