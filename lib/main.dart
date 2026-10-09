import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/chat_controller.dart';
import 'controllers/notification_controller.dart';
import 'views/main_shell.dart';
import 'views/theme/app_theme.dart';

void main() {
  runApp(const SignLApp());
}

class SignLApp extends StatelessWidget {
  const SignLApp({super.key});

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
    );
  }
}
