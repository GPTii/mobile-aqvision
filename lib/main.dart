import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const RapidMediaApp());
}

class RapidMediaApp extends StatelessWidget {
  const RapidMediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidMedia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
