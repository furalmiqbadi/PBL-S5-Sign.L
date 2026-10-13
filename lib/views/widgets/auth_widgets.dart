import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const pink = AppColors.primary;
const purple = AppColors.secondary;
const ink = AppColors.textPrimary;
const muted = AppColors.textSecondary;

class SignLogo extends StatelessWidget {
  final double size;
  const SignLogo({super.key, this.size = 66});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: size, height: size, decoration: BoxDecoration(gradient: const LinearGradient(colors: [pink, purple]), borderRadius: BorderRadius.circular(size * .24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 8, offset: const Offset(0, 4))]), child: Icon(Icons.back_hand_rounded, color: Colors.white, size: size * .55)),
        const SizedBox(height: 4),
        Text('Sign.L', style: AppTextStyles.labelMedium.copyWith(fontSize: size * .19, fontWeight: FontWeight.w900, color: pink)),
      ]);
}

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool back;
  final VoidCallback? onBack;
  const AuthScaffold({super.key, required this.child, this.back = false, this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Stack(children: [
        Positioned(top: -35, right: -25, child: Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.pinkSoft.withValues(alpha: 0.13)))),
        SingleChildScrollView(padding: EdgeInsets.fromLTRB(22, back ? 56 : 30, 22, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: child))),
        // Diletakkan paling akhir agar berada di atas ScrollView dan selalu
        // menerima tap, termasuk saat dijalankan di Flutter Web.
        if (back)
          Positioned(
            top: 10,
            left: 16,
            child: Material(
              color: AppColors.pinkSoft,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                onTap: onBack ?? () => Navigator.maybePop(context),
                customBorder: const CircleBorder(),
                splashColor: pink.withValues(alpha: .22),
                highlightColor: pink.withValues(alpha: .10),
                child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.arrow_back_rounded, size: 19, color: pink)),
              ),
            ),
          ),
      ])));
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeader({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(children: [const SignLogo(), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: AppTextStyles.headlineSmall.copyWith(fontSize: 22, fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5, height: 1.45))]);
}

class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool password;
  final Widget? suffix;
  final TextEditingController? controller;
  const AuthField({super.key, required this.label, required this.hint, required this.icon, this.password = false, this.suffix, this.controller});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTextStyles.labelXSmall.copyWith(fontSize: 10.5, fontWeight: FontWeight.w800)), const SizedBox(height: 6), TextField(controller: controller, obscureText: password, style: AppTextStyles.labelSmall.copyWith(color: ink), decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 15, color: pink), suffixIcon: suffix))]));
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const GradientButton({super.key, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? const LinearGradient(colors: [pink, purple]) : const LinearGradient(colors: [AppColors.textMuted, AppColors.textMuted]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: enabled ? [BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 5, offset: const Offset(0, 3))] : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withValues(alpha: .24),
            highlightColor: Colors.white.withValues(alpha: .12),
            child: Center(child: Text(text, style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
          ),
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget { final String text; const DividerWithText({super.key, required this.text}); @override Widget build(BuildContext context) => Row(children: [const Expanded(child: Divider(color: AppColors.border)), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(text, style: AppTextStyles.labelXSmall.copyWith(fontSize: 9, color: muted))), const Expanded(child: Divider(color: AppColors.border))]); }
class GoogleButton extends StatelessWidget { final VoidCallback onTap; const GoogleButton({super.key, required this.onTap}); @override Widget build(BuildContext context) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 43), overlayColor: pink, side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), child: Text('🇬   Lanjutkan dengan Google', style: AppTextStyles.labelSmall.copyWith(color: ink, fontWeight: FontWeight.w700))); }
class FooterText extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;
  const FooterText({super.key, required this.prefix, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(prefix, style: AppTextStyles.labelXSmall.copyWith(color: muted)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            splashColor: pink.withValues(alpha: .16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Text(action, style: AppTextStyles.labelXSmall.copyWith(color: pink, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }
}
