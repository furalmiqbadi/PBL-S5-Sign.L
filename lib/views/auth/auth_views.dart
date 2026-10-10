import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class BlankHomePage extends StatelessWidget {
  const BlankHomePage({super.key});
  @override
  Widget build(BuildContext context) => PopScope<void>(
        canPop: false,
        // Beranda masih kosong, jadi tombol back mengembalikan user
        // ke halaman login sebagai titik awal aplikasi.
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        },
        child: const Scaffold(body: SizedBox.expand()),
      );
}

void openHome(BuildContext context) => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const BlankHomePage()), (_) => false);

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState() => _LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(); final password = TextEditingController();
  @override void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> submit() async { final c = context.read<AuthController>(); await c.login(email: email.text, password: password.text); if (mounted) openHome(context); }
  @override Widget build(BuildContext context) => AuthScaffold(child: Column(children: [
    const AuthHeader(title: 'Selamat Datang Kembali! 👋', subtitle: 'Masuk untuk melanjutkan perjalanan belajar bahasa isyaratmu.'), const SizedBox(height: 27),
    AuthField(label: 'Email atau Username', hint: 'cth. budi@gmail.com atau budi', icon: Icons.alternate_email_rounded, controller: email),
    Consumer<AuthController>(builder: (_, c, __) => AuthField(label: 'Kata Sandi', hint: 'Masukkan kata sandi', icon: Icons.lock_outline_rounded, controller: password, password: !c.showPassword, suffix: IconButton(onPressed: c.togglePasswordVisibility, icon: Icon(c.showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16, color: muted)))),
    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPage())), child: const Text('Lupa kata sandi?', style: TextStyle(fontSize: 10, color: pink, fontWeight: FontWeight.w800)))),
    Consumer<AuthController>(builder: (_, c, __) => GradientButton(text: c.isLoading ? 'Memproses...' : 'Masuk  →', onTap: c.isLoading ? null : submit)), const DividerWithText(text: 'atau masuk dengan'),
    GoogleButton(onTap: () => openHome(context)), const SizedBox(height: 22), FooterText(prefix: 'Belum punya akun? ', action: 'Daftar Sekarang', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()))),
  ]));
}

class RegisterPage extends StatefulWidget { const RegisterPage({super.key}); @override State<RegisterPage> createState() => _RegisterPageState(); }
class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController(); final username = TextEditingController(); final email = TextEditingController(); final password = TextEditingController(); final confirmation = TextEditingController(); bool accepted = false; bool show = false;
  @override void dispose() { for (final c in [name, username, email, password, confirmation]) { c.dispose(); } super.dispose(); }
  Future<void> submit() async { if (!accepted) { _message('Setujui Syarat & Ketentuan terlebih dahulu.'); return; } final c = context.read<AuthController>(); await c.register(email: email.text, password: password.text); if (mounted) openHome(context); }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override Widget build(BuildContext context) => AuthScaffold(back: true, onBack: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false), child: Column(children: [
    const AuthHeader(title: 'Mulai Perjalanan Isyaratmu ✋', subtitle: 'Bergabung bersama ribuan pembelajar bahasa isyarat di seluruh Indonesia!'), const SizedBox(height: 22),
    AuthField(label: 'Nama Lengkap', hint: 'cth. Budi Pratama', icon: Icons.person_outline_rounded, controller: name), AuthField(label: 'Username', hint: 'cth. budi_isyarat', icon: Icons.alternate_email_rounded, controller: username), AuthField(label: 'Email', hint: 'cth. budi@gmail.com', icon: Icons.mail_outline_rounded, controller: email),
    AuthField(label: 'Kata Sandi', hint: 'BelajarBisa24!', icon: Icons.lock_outline_rounded, controller: password, password: !show, suffix: IconButton(onPressed: () => setState(() => show = !show), icon: Icon(show ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16))), AuthField(label: 'Konfirmasi Kata Sandi', hint: 'Ulangi kata sandi', icon: Icons.lock_outline_rounded, controller: confirmation, password: !show),
    InkWell(onTap: () => setState(() => accepted = !accepted), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(accepted ? Icons.check_box : Icons.check_box_outline_blank, color: pink, size: 16), const SizedBox(width: 6), const Expanded(child: Text('Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi Sign.L.', style: TextStyle(fontSize: 10, color: muted)))])), const SizedBox(height: 16),
    Consumer<AuthController>(builder: (_, c, __) => GradientButton(text: 'Buat Akun  ✨', onTap: c.isLoading ? null : submit)), const DividerWithText(text: 'atau daftar dengan'), GoogleButton(onTap: () => openHome(context)), const SizedBox(height: 18), FooterText(prefix: 'Sudah punya akun? ', action: 'Masuk', onTap: () => Navigator.pop(context)),
  ]));
}

class ForgotPage extends StatefulWidget { const ForgotPage({super.key}); @override State<ForgotPage> createState() => _ForgotPageState(); }
class _ForgotPageState extends State<ForgotPage> {
  final email = TextEditingController();
  @override void dispose() { email.dispose(); super.dispose(); }
  Future<void> submit() async { final c = context.read<AuthController>(); await c.sendResetLink(email.text); if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPage())); }
  @override Widget build(BuildContext context) => AuthScaffold(back: true, onBack: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false), child: Column(children: [
    const AuthHeader(title: 'Lupa Kata Sandi?', subtitle: 'Tenang, masukkan email terdaftar kamu dan kami siapkan tautan untuk membuat kata sandi baru.'), const SizedBox(height: 28), AuthField(label: 'Email Terdaftar', hint: 'cth. budi@gmail.com', icon: Icons.mail_outline_rounded, controller: email),
    Consumer<AuthController>(builder: (_, c, __) => GradientButton(text: c.isLoading ? 'Mengirim...' : 'Kirim Tautan Reset  ✈', onTap: c.isLoading ? null : submit)), const SizedBox(height: 16), Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFFFF0D9), borderRadius: BorderRadius.circular(12)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('💡', style: TextStyle(fontSize: 17)), SizedBox(width: 8), Expanded(child: Text('Tips Praktis\nCek folder Spam atau Promosi jika tautan belum masuk dalam 2 menit.', style: TextStyle(fontSize: 10, color: ink, height: 1.5)))])), const SizedBox(height: 25), FooterText(prefix: 'Ingat kata sandimu? ', action: 'Kembali ke Masuk', onTap: () => Navigator.pop(context)),
  ]));
}

class ResetPage extends StatefulWidget { const ResetPage({super.key}); @override State<ResetPage> createState() => _ResetPageState(); }
class _ResetPageState extends State<ResetPage> {
  final password = TextEditingController(); final confirmation = TextEditingController(); bool show = false;
  @override void dispose() { password.dispose(); confirmation.dispose(); super.dispose(); }
  Future<void> submit() async { if (password.text != confirmation.text || password.text.length < 8) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 8 karakter dan harus sama.'))); return; } final c = context.read<AuthController>(); await c.resetPassword(password: password.text, confirmation: confirmation.text); if (mounted) showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Berhasil!'), content: const Text('Kata sandi kamu sudah diperbarui.'), actions: [TextButton(onPressed: () => openHome(context), child: const Text('Ke Beranda'))])); }
  @override Widget build(BuildContext context) => AuthScaffold(back: true, onBack: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false), child: Column(children: [
    const AuthHeader(title: 'Buat Kata Sandi Baru', subtitle: 'Gunakan kata sandi yang kuat dan mudah kamu ingat.'), const SizedBox(height: 28), AuthField(label: 'Kata Sandi Baru', hint: 'Minimal 8 karakter', icon: Icons.lock_outline_rounded, controller: password, password: !show, suffix: IconButton(onPressed: () => setState(() => show = !show), icon: Icon(show ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 16))), AuthField(label: 'Konfirmasi Kata Sandi', hint: 'Ulangi kata sandi baru', icon: Icons.lock_outline_rounded, controller: confirmation, password: !show),
    Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFF8E8F5), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.shield_outlined, color: pink, size: 19), SizedBox(width: 9), Expanded(child: Text('Gunakan minimal 8 karakter, kombinasi huruf dan angka.', style: TextStyle(fontSize: 10, color: muted)))])), const SizedBox(height: 20), Consumer<AuthController>(builder: (_, c, __) => GradientButton(text: c.isLoading ? 'Menyimpan...' : 'Simpan Kata Sandi  ✓', onTap: c.isLoading ? null : submit)),
  ]));
}
