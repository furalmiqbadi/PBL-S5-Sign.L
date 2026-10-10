import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'views/home/materi_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'views/auth/auth_views.dart';

import 'controllers/chat_controller.dart';
import 'controllers/notification_controller.dart';
import 'views/main_shell.dart';
import 'views/theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: const SignLApp(),
    ),
  );
}

class SignLanguageApp extends StatelessWidget {
  const SignLanguageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
      ],
      child: MaterialApp(
        title: 'Sign.L',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainShell(),
      ),
    const primary = Color(0xFFC40083);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sign.L',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: const Color(0xFFFFF7FC),
        textTheme: GoogleFonts.nunitoTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFF0FA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFF6D5EC))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: primary, width: 1.3)),
          hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFB9A8B7)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// Backward-compatible name for the default Flutter widget test.
class MyApp extends SignLApp {
  const MyApp({super.key});
}
