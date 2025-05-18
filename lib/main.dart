import 'package:flutter/material.dart';
import 'package:funflags/config/app_theme.dart';
import 'package:funflags/presentation/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelers Flag Quiz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomePage(),
    );
  }
}
