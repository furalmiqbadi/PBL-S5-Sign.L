import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import '../widgets/app_screen_header.dart';

class PushedPage extends StatelessWidget {
  const PushedPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: AppScreenHeader(title: title, actions: actions),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
