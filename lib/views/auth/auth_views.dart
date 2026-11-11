import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../main_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/auth_widgets.dart';

/// Membuka beranda utama aplikasi (MainShell) dan menghapus riwayat halaman auth.
void openHome(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainShell()),
    (_) => false,
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final c = context.read<AuthController>();
    final emailText = email.text.trim();
    final passText = password.text.trim();

    if (emailText.isEmpty || passText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi wajib diisi.')),
      );
      return;
    }

    final ok = await c.login(email: emailText, password: passText);
    if (!mounted) return;

    if (ok) {
      openHome(context);
    } else if (c.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(c.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        children: [
          const AuthHeader(
            title: 'Selamat datang kembali',
            subtitle: 'Masuk untuk melanjutkan perjalanan belajar bahasa isyaratmu.',
          ),
          const SizedBox(height: 27),
          AuthField(
            label: 'Email atau Username',
            hint: 'Masukkan email atau username',
            icon: Icons.alternate_email_rounded,
            controller: email,
          ),
          Consumer<AuthController>(
            builder: (_, c, __) => AuthField(
              label: 'Kata Sandi',
              hint: 'Masukkan kata sandi',
              icon: Icons.lock_outline_rounded,
              controller: password,
              password: !c.showPassword,
              suffix: IconButton(
                onPressed: c.togglePasswordVisibility,
                icon: Icon(
                  c.showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: muted,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPage()),
              ),
              child: Text(
                'Lupa kata sandi?',
                style: AppTextStyles.labelXSmall.copyWith(color: pink, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Consumer<AuthController>(
            builder: (_, c, __) => GradientButton(
              text: c.isLoading ? 'Memproses...' : 'Masuk',
              onTap: c.isLoading ? null : submit,
            ),
          ),
          const SizedBox(height: 24),
          FooterText(
            prefix: 'Belum punya akun? ',
            action: 'Daftar Sekarang',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool accepted = false;
  bool show = false;

  @override
  void dispose() {
    for (final c in [name, username, email, password, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> submit() async {
    final c = context.read<AuthController>();
    final nameText = name.text.trim();
    final userText = username.text.trim().toLowerCase();
    final emailText = email.text.trim();
    final passText = password.text.trim();
    final confirmText = confirmation.text.trim();

    if (nameText.length < 3) {
      _message('Nama lengkap minimal 3 karakter.');
      return;
    }
    if (userText.isEmpty) {
      _message('Username wajib diisi.');
      return;
    }
    if (!RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(userText)) {
      _message('Username 3-20 karakter, hanya huruf, angka, titik, atau garis bawah.');
      return;
    }
    if (emailText.isEmpty) {
      _message('Email wajib diisi.');
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(emailText)) {
      _message('Format email tidak valid.');
      return;
    }
    if (passText.isEmpty) {
      _message('Kata sandi wajib diisi.');
      return;
    }
    if (passText.length < 8) {
      _message('Kata sandi minimal 8 karakter.');
      return;
    }
    if (passText != confirmText) {
      _message('Konfirmasi kata sandi tidak cocok.');
      return;
    }
    if (!accepted) {
      _message('Anda harus menyetujui Syarat & Ketentuan.');
      return;
    }

    final ok = await c.register(
      email: emailText,
      password: passText,
      name: nameText,
      username: userText,
    );
    if (!mounted) return;

    if (!ok) {
      if (c.errorMessage != null) _message(c.errorMessage!);
      return;
    }

    if (c.isLoggedIn) {
      openHome(context);
      return;
    }

    // Supabase meminta konfirmasi email: jangan buka beranda tanpa session.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cek Email'),
        content: const Text(
          'Pendaftaran berhasil. Klik tautan verifikasi di email kamu, lalu masuk.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      back: true,
      onBack: _navigateBack,
      child: Column(
        children: [
          const AuthHeader(
            title: 'Mulai perjalanan isyaratmu',
            subtitle: 'Bergabung bersama ribuan pembelajar bahasa isyarat di seluruh Indonesia!',
          ),
          const SizedBox(height: 22),
          AuthField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap',
            icon: Icons.person_outline_rounded,
            controller: name,
          ),
          AuthField(
            label: 'Username',
            hint: 'Masukkan username',
            icon: Icons.alternate_email_rounded,
            controller: username,
          ),
          AuthField(
            label: 'Email',
            hint: 'Masukkan email',
            icon: Icons.mail_outline_rounded,
            controller: email,
          ),
          AuthField(
            label: 'Kata Sandi (min. 8 karakter)',
            hint: 'Masukkan kata sandi',
            icon: Icons.lock_outline_rounded,
            controller: password,
            password: !show,
            suffix: IconButton(
              onPressed: () => setState(() => show = !show),
              icon: Icon(
                show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: muted,
              ),
            ),
          ),
          AuthField(
            label: 'Konfirmasi Kata Sandi',
            hint: 'Masukkan ulang kata sandi',
            icon: Icons.lock_outline_rounded,
            controller: confirmation,
            password: !show,
            suffix: IconButton(
              onPressed: () => setState(() => show = !show),
              icon: Icon(
                show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: muted,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => accepted = !accepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  accepted ? Icons.check_box : Icons.check_box_outline_blank,
                  color: pink,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi Sign.L.',
                    style: AppTextStyles.labelXSmall.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Consumer<AuthController>(
            builder: (_, c, __) => GradientButton(
              text: c.isLoading ? 'Memproses...' : 'Buat akun',
              onTap: c.isLoading ? null : submit,
            ),
          ),
          const SizedBox(height: 20),
          FooterText(
            prefix: 'Sudah punya akun? ',
            action: 'Masuk',
            onTap: _navigateBack,
          ),
        ],
      ),
    );
  }
}

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final email = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<void> submit() async {
    final c = context.read<AuthController>();
    final emailText = email.text.trim();

    if (emailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email wajib diisi.')),
      );
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(emailText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid.')),
      );
      return;
    }

    final ok = await c.sendResetLink(emailText);
    if (!mounted) return;

    if (!ok) {
      if (c.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(c.errorMessage!)),
        );
      }
      return;
    }

    // Jangan langsung membuka ResetPage. Reset hanya boleh setelah
    // pengguna mengklik tautan recovery yang dikirim ke email.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cek Email'),
        content: const Text(
          'Tautan reset sudah dikirim. Buka email kamu dan klik tautan tersebut untuk membuat kata sandi baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      back: true,
      onBack: _navigateBack,
      child: Column(
        children: [
          const AuthHeader(
            title: 'Lupa Kata Sandi?',
            subtitle: 'Tenang, masukkan email terdaftar kamu dan kami siapkan tautan untuk membuat kata sandi baru.',
          ),
          const SizedBox(height: 28),
          AuthField(
            label: 'Email Terdaftar',
            hint: 'Masukkan email terdaftar',
            icon: Icons.mail_outline_rounded,
            controller: email,
          ),
          Consumer<AuthController>(
            builder: (_, c, __) => GradientButton(
              text: c.isLoading ? 'Mengirim...' : 'Kirim tautan reset',
              onTap: c.isLoading ? null : submit,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.orangeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡', style: AppTextStyles.bodyLarge.copyWith(fontSize: 17)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tips Praktis\nCek folder Spam atau Promosi jika tautan belum masuk dalam 2 menit.',
                    style: AppTextStyles.labelXSmall.copyWith(color: AppColors.textPrimary, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          FooterText(
            prefix: 'Ingat kata sandimu? ',
            action: 'Kembali ke Masuk',
            onTap: _navigateBack,
          ),
        ],
      ),
    );
  }
}

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool show = false;

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<void> submit() async {
    final c = context.read<AuthController>();
    final passText = password.text.trim();
    final confirmText = confirmation.text.trim();

    if (passText.isEmpty || confirmText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi baru dan konfirmasi wajib diisi.')),
      );
      return;
    }
    if (passText.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi baru minimal 8 karakter.')),
      );
      return;
    }
    if (passText != confirmText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok.')),
      );
      return;
    }

    final ok = await c.resetPassword(password: passText, confirmation: confirmText);
    if (!mounted) return;

    if (ok) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Berhasil!', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Kata sandi kamu sudah berhasil diperbarui. Silakan masuk atau lanjutkan ke beranda.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              ),
              child: const Text('Ke Halaman Masuk'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => openHome(context),
              child: const Text('Ke Beranda'),
            ),
          ],
        ),
      );
    } else if (c.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(c.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      back: true,
      onBack: _navigateBack,
      child: Column(
        children: [
          const AuthHeader(
            title: 'Buat Kata Sandi Baru',
            subtitle: 'Gunakan kata sandi yang kuat dan mudah kamu ingat.',
          ),
          const SizedBox(height: 28),
          AuthField(
            label: 'Kata Sandi Baru (min. 8 karakter)',
            hint: 'Masukkan kata sandi baru',
            icon: Icons.lock_outline_rounded,
            controller: password,
            password: !show,
            suffix: IconButton(
              onPressed: () => setState(() => show = !show),
              icon: Icon(
                show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 16,
              ),
            ),
          ),
          AuthField(
            label: 'Konfirmasi Kata Sandi',
            hint: 'Masukkan ulang kata sandi baru',
            icon: Icons.lock_outline_rounded,
            controller: confirmation,
            password: !show,
          ),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8E8F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: pink, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Gunakan minimal 8 karakter, kombinasi huruf dan angka.',
                    style: AppTextStyles.labelXSmall.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Consumer<AuthController>(
            builder: (_, c, __) => GradientButton(
              text: c.isLoading ? 'Menyimpan...' : 'Simpan Kata Sandi  ✓',
              onTap: c.isLoading ? null : submit,
            ),
          ),
        ],
      ),
    );
  }
}
