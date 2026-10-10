import 'package:flutter/material.dart';

const pink = Color(0xFFC40083);
const purple = Color(0xFF9825B4);
const ink = Color(0xFF302036);
const muted = Color(0xFF826D80);

class SignLogo extends StatelessWidget {
  final double size;
  const SignLogo({super.key, this.size = 66});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: size, height: size, decoration: BoxDecoration(gradient: const LinearGradient(colors: [pink, purple]), borderRadius: BorderRadius.circular(size * .24), boxShadow: const [BoxShadow(color: Color(0x332C1234), blurRadius: 8, offset: Offset(0, 4))]), child: Icon(Icons.back_hand_rounded, color: Colors.white, size: size * .55)),
        const SizedBox(height: 4),
        Text('Sign.L', style: TextStyle(fontSize: size * .19, fontWeight: FontWeight.w900, color: pink)),
      ]);
}

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final bool back;
  final VoidCallback? onBack;
  const AuthScaffold({super.key, required this.child, this.back = false, this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Stack(children: [
        Positioned(top: -35, right: -25, child: Container(width: 110, height: 110, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x22F1B4DD)))),
        SingleChildScrollView(padding: EdgeInsets.fromLTRB(22, back ? 56 : 30, 22, 24), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: child))),
        // Diletakkan paling akhir agar berada di atas ScrollView dan selalu
        // menerima tap, termasuk saat dijalankan di Flutter Web.
        if (back)
          Positioned(
            top: 10,
            left: 16,
            child: Material(
              color: const Color(0xFFFFE7F8),
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
  Widget build(BuildContext context) => Column(children: [const SignLogo(), const SizedBox(height: 18), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: ink)), const SizedBox(height: 6), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: muted, height: 1.45))]);
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
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 6), TextField(controller: controller, obscureText: password, style: const TextStyle(fontSize: 11), decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 15, color: pink), suffixIcon: suffix))]));
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
            gradient: enabled ? const LinearGradient(colors: [pink, purple]) : const LinearGradient(colors: [Color(0xFFCEB6C8), Color(0xFFBDA9B9)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: enabled ? const [BoxShadow(color: Color(0x332B0020), blurRadius: 5, offset: Offset(0, 3))] : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withValues(alpha: .24),
            highlightColor: Colors.white.withValues(alpha: .12),
            child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
          ),
        ),
      ),
    );
  }
}

class DividerWithText extends StatelessWidget { final String text; const DividerWithText({super.key, required this.text}); @override Widget build(BuildContext context) => Row(children: [const Expanded(child: Divider(color: Color(0xFFF0D5E8))), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(text, style: const TextStyle(fontSize: 9, color: muted))), const Expanded(child: Divider(color: Color(0xFFF0D5E8)))]); }
class GoogleButton extends StatelessWidget { final VoidCallback onTap; const GoogleButton({super.key, required this.onTap}); @override Widget build(BuildContext context) => OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 43), overlayColor: pink, side: const BorderSide(color: Color(0xFFF2D9EB)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))), child: const Text('🇬   Lanjutkan dengan Google', style: TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w700))); }
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
        Text(prefix, style: const TextStyle(fontSize: 10, color: muted)),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            splashColor: pink.withValues(alpha: .16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Text(action, style: const TextStyle(fontSize: 10, color: pink, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }
}
