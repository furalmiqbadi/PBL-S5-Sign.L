import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/notification_controller.dart';
import 'views/auth/auth_views.dart';
import 'views/theme/app_theme.dart';

void main() {
  runApp(const SignLApp());
}

/// Root aplikasi Sign.L.
///
/// Menyediakan controller aplikasi lewat [MultiProvider] dan menampilkan
/// [LoginPage] sebagai titik awal. Setelah autentikasi (masih mock, belum
/// terhubung database) user diarahkan ke kerangka utama `MainShell`.
class SignLApp extends StatelessWidget {
  const SignLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
      ],
      child: MaterialApp(
        title: 'Sign.L',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginPage(),
      ),
    );
  }
}
