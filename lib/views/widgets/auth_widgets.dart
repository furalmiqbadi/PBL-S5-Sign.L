import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const pink = AppColors.primary;
const purple = AppColors.secondary;
const ink = AppColors.textPrimary;
const muted = AppColors.textSecondary;

/// Path logo aplikasi. Taruh file gambar logo di lokasi ini.
const String kLogoAsset = 'assets/images/logo.png';

/// Tulisan merek "Sign.L": "Sign." gelap, "L" biru seperti warna logo.
class SignWordmark extends StatelessWidget {
  final double fontSize;
  const SignWordmark({super.key, this.fontSize = 28});

  @override
  Widget build(BuildContext context) => Text.rich(
        const TextSpan(children: [
          TextSpan(text: 'Sign.', style: TextStyle(color: ink)),
          TextSpan(text: 'L', style: TextStyle(color: pink)),
        ]),
        style: AppTextStyles.titleLarge.copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.1),
      );
}

/// Logo aplikasi. [showText] menambahkan [SignWordmark] di bawah logo.
class SignLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const SignLogo({super.key, this.size = 66, this.showText = true});

  Widget _fallback() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: pink, borderRadius: BorderRadius.circular(size * .28)),
      child:
          Icon(Icons.back_hand_rounded, color: Colors.white, size: size * .55));

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(kLogoAsset,
            width: size,
            height: size,
            fit: BoxFit.contain,
            semanticLabel: 'Logo Sign.L',
            errorBuilder: (_, __, ___) => _fallback()),
        if (showText) ...[
          const SizedBox(height: 8),
          SignWordmark(fontSize: size * .28),
        ],
      ]);
}

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool back;
  final VoidCallback? onBack;
  const AuthScaffold(
      {super.key, required this.child, this.back = false, this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, back ? 64 : 32, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: child,
                  ),
                ),
              ),
              // Diletakkan paling akhir agar berada di atas ScrollView dan selalu
              // menerima tap, termasuk saat dijalankan di Flutter Web.
              if (back)
                Positioned(
                  top: 8,
                  left: 12,
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Material(
                          color: AppColors.surfaceMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onBack ?? () => Navigator.maybePop(context),
                            borderRadius: BorderRadius.circular(14),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeader({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Column(children: [
        const SignLogo(size: 104),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: muted, height: 1.5),
        ),
      ]);
}

class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool password;
  final Widget? suffix;
  final TextEditingController? controller;
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.password = false,
    this.suffix,
    this.controller,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: password,
              style: AppTextStyles.bodyMedium.copyWith(color: ink),
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: Icon(icon, size: 20, color: pink),
                suffixIcon: suffix,
              ),
            ),
          ],
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const PrimaryButton({super.key, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary : AppColors.textMuted,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: pink.withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: .24),
            highlightColor: Colors.white.withValues(alpha: .12),
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String text;
  const DividerWithText({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(color: muted),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      );
}

class GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  const GoogleButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: AppColors.surface,
          foregroundColor: ink,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Lanjutkan dengan Google',
              style: AppTextStyles.labelLarge.copyWith(
                color: ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class FooterText extends StatelessWidget {
  final String prefix;
  final String action;
  final VoidCallback onTap;
  const FooterText({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prefix, style: AppTextStyles.bodySmall.copyWith(color: muted)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            splashColor: pink.withValues(alpha: .16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Text(
                action,
                style: AppTextStyles.bodySmall.copyWith(
                  color: pink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
