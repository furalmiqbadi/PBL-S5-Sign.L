import 'package:flutter/material.dart';

import 'views/main_shell.dart';

void main() {
  runApp(const SignLApp());
}

class SignLApp extends StatelessWidget {
  const SignLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sign.L',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC2185B)),
      ),
      home: const MainShell(),
    );
  }
}
