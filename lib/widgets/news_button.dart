import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../screens/home/tabs/news_tab.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

/// Header shortcut to the News page, styled like [NotificationBellButton].
class NewsButton extends StatelessWidget {
  const NewsButton({super.key});

  Future<void> _open(BuildContext context) async {
    // Pause header-tab video tiles while News covers them.
    AppState.isVideoGridActive.value = false;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewsTab()));
    AppState.isVideoGridActive.value = true;
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Tin tức'.tr,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _open(context),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(Icons.article_outlined, color: AppColors.textPrimary, size: 26),
          ),
        ),
      ),
    );
  }
}
