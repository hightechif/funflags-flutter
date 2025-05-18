import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:funflags/config/app_theme.dart';
import 'package:funflags/presentation/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional - remove if you only want right side up
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight
    // Optional - remove if you only want right side up
  ]).then((_) {
    runApp(const MyApp());
  });
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
