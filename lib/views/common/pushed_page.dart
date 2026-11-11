import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_screen_header.dart';

class PushedPage extends StatelessWidget {
  const PushedPage({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: AppScreenHeader(title: title),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
