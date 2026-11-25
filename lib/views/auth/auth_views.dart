import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../../services/saved_accounts_service.dart';
import '../admin/admin_panel_page.dart';
import '../main_shell.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_ui.dart';
import '../widgets/auth_widgets.dart';
import 'register_profile_page.dart';

/// Membuka beranda utama aplikasi (MainShell) dan menghapus riwayat halaman auth.
void openHome(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainShell()),
    (_) => false,
  );
}

/// Membuka panel admin atau beranda sesuai role akun yang sedang masuk.
Future<void> openSesuaiRole(BuildContext context) async {
  final isAdmin = await AuthService().fetchRole() == 'admin';
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => isAdmin ? const AdminPanelPage() : const MainShell(),
    ),
    (_) => false,
  );
}

/// Meminta konfirmasi lalu keluar dari akun dan kembali ke [LoginPage].
///
/// Dipakai tombol keluar di tab Profil, halaman Pengaturan, dan panel admin
/// supaya perilakunya sama di semua tempat.
Future<void> konfirmasiKeluar(
  BuildContext context, {
  String title = 'Keluar dari Akun?',
  String message = 'Kamu perlu masuk lagi untuk melanjutkan belajar.',
  String confirmLabel = 'Keluar',
}) async {
  final ok = await showAppDialog(
    context,
    icon: Icons.logout_rounded,
    title: title,
    message: message,
    cancelLabel: 'Batal',
    confirmLabel: confirmLabel,
    isDestructive: true,
  );
  if (ok != true || !context.mounted) return;

  await context.read<AuthController>().logout();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const AccountChooserPage()),
    (_) => false,
  );
}

class AccountChooserPage extends StatefulWidget {
  const AccountChooserPage({super.key});

  @override
  State<AccountChooserPage> createState() => _AccountChooserPageState();
}

class _AccountChooserPageState extends State<AccountChooserPage> {
  late Future<List<SavedAccount>> _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = context.read<AuthController>().savedAccounts();
  }

  Future<void> _switch(SavedAccount account) async {
    final controller = context.read<AuthController>();
    final ok = await controller.switchAccount(account);
    if (!mounted) return;
    if (!ok) {
      final message = controller.errorMessage ??
          'Sesi akun tidak tersedia. Silakan masuk lagi.';
      await controller.removeSavedAccount(account.email);
      if (!mounted) return;
      showAppSnackBar(context, message, type: AppSnackType.error);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(initialEmail: account.email),
        ),
      );
      return;
    }
    if (controller.isAdmin) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelPage()),
          (_) => false);
    } else {
      openHome(context);
    }
  }

  Future<void> _remove(SavedAccount account) async {
    await context.read<AuthController>().removeSavedAccount(account.email);
    if (mounted) {
      setState(
          () => _accounts = context.read<AuthController>().savedAccounts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: FutureBuilder<List<SavedAccount>>(
        future: _accounts,
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? const <SavedAccount>[];
          return Column(
            children: [
              const AuthHeader(
                title: 'Masuk ke Sign.L',
                subtitle: 'Pilih akun untuk melanjutkan belajar.',
              ),
              const SizedBox(height: 24),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Belum ada akun tersimpan.'),
                )
              else
                ...accounts.map((account) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: .12),
                          child: Text(
                            account.name.isEmpty
                                ? '?'
                                : account.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(account.name,
                            style: AppTextStyles.labelMedium),
                        subtitle: Text(account.email),
                        onTap: () => _switch(account),
                        trailing: PopupMenuButton<String>(
                          onSelected: (_) => _remove(account),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'remove', child: Text('Hapus akun')),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 12),
              PrimaryButton(
                text: 'Masuk dengan akun lain',
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginPage())),
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void initState() {
    super.initState();
    email.text = widget.initialEmail ?? '';
  }

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
      showAppSnackBar(
        context,
        'Email dan kata sandi wajib diisi.',
        type: AppSnackType.warning,
      );
      return;
    }

    final ok = await c.login(email: emailText, password: passText);
    if (!mounted) return;

    if (ok) {
      // Satu pintu login: role admin dibaca dari tabel profiles, lalu
      // diarahkan ke panel admin tanpa halaman login terpisah.
      if (c.isAdmin) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelPage()),
          (_) => false,
        );
      } else {
        openHome(context);
      }
    } else if (c.errorMessage != null) {
      showAppSnackBar(context, c.errorMessage!, type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        children: [
          const AuthHeader(
            title: 'Selamat datang kembali',
            subtitle:
                'Masuk untuk melanjutkan perjalanan belajar bahasa isyaratmu.',
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
                  c.showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
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
                style: AppTextStyles.labelXSmall
                    .copyWith(color: pink, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Consumer<AuthController>(
            builder: (_, c, __) => PrimaryButton(
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
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool accepted = false;
  bool show = false;

  @override
  void dispose() {
    for (final c in [username, email, password, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  void _message(String text, {AppSnackType type = AppSnackType.warning}) {
    showAppSnackBar(context, text, type: type);
  }

  Future<void> submit() async {
    final c = context.read<AuthController>();
    final userText = username.text.trim().toLowerCase();
    final emailText = email.text.trim();
    final passText = password.text.trim();
    final confirmText = confirmation.text.trim();

    if (!RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(userText)) {
      _message(
          'Username 3-20 karakter, hanya huruf, angka, titik, atau garis bawah.');
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(emailText)) {
      _message('Format email tidak valid.');
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
      username: userText,
    );
    if (!mounted) return;

    if (!ok) {
      if (c.errorMessage != null) {
        _message(c.errorMessage!, type: AppSnackType.error);
      }
      return;
    }

    if (c.isLoggedIn) {
      // Nama & foto profil dilengkapi di halaman berikutnya.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterProfilePage(username: userText),
        ),
        (_) => false,
      );
      return;
    }

    // Supabase meminta konfirmasi email: jangan buka beranda tanpa session.
    await showAppDialog(
      context,
      icon: Icons.mark_email_read_outlined,
      title: 'Cek Email Kamu',
      message:
          'Pendaftaran berhasil. Klik tautan verifikasi di email kamu, lalu masuk.',
      showCancel: false,
      confirmLabel: 'Mengerti',
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
            subtitle:
                'Cukup username, email, dan kata sandi. Nama serta foto profil diatur di langkah berikutnya.',
          ),
          const SizedBox(height: 22),
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
                show
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
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
                show
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: muted,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => accepted = !accepted),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      accepted
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: pink,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi Sign.L.',
                        style: AppTextStyles.bodySmall.copyWith(color: muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<AuthController>(
            builder: (_, c, __) => PrimaryButton(
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
      showAppSnackBar(
        context,
        'Email wajib diisi.',
        type: AppSnackType.warning,
      );
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(emailText)) {
      showAppSnackBar(
        context,
        'Format email tidak valid.',
        type: AppSnackType.warning,
      );
      return;
    }

    final ok = await c.sendResetLink(emailText);
    if (!mounted) return;

    if (!ok) {
      if (c.errorMessage != null) {
        showAppSnackBar(context, c.errorMessage!, type: AppSnackType.error);
      }
      return;
    }

    // Jangan langsung membuka ResetPage. Reset hanya boleh setelah
    // pengguna mengklik tautan recovery yang dikirim ke email.
    await showAppDialog(
      context,
      icon: Icons.mark_email_read_outlined,
      title: 'Cek Email Kamu',
      message:
          'Tautan reset sudah dikirim. Buka email kamu dan klik tautan tersebut untuk membuat kata sandi baru.',
      showCancel: false,
      confirmLabel: 'Mengerti',
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
            subtitle:
                'Tenang, masukkan email terdaftar kamu dan kami siapkan tautan untuk membuat kata sandi baru.',
          ),
          const SizedBox(height: 28),
          AuthField(
            label: 'Email Terdaftar',
            hint: 'Masukkan email terdaftar',
            icon: Icons.mail_outline_rounded,
            controller: email,
          ),
          Consumer<AuthController>(
            builder: (_, c, __) => PrimaryButton(
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
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tips Praktis\nCek folder Spam atau Promosi jika tautan belum masuk dalam 2 menit.',
                    style: AppTextStyles.labelXSmall
                        .copyWith(color: AppColors.textPrimary, height: 1.5),
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
      showAppSnackBar(
        context,
        'Kata sandi baru dan konfirmasi wajib diisi.',
        type: AppSnackType.warning,
      );
      return;
    }
    if (passText.length < 8) {
      showAppSnackBar(
        context,
        'Kata sandi baru minimal 8 karakter.',
        type: AppSnackType.warning,
      );
      return;
    }
    if (passText != confirmText) {
      showAppSnackBar(
        context,
        'Konfirmasi kata sandi tidak cocok.',
        type: AppSnackType.warning,
      );
      return;
    }

    final ok =
        await c.resetPassword(password: passText, confirmation: confirmText);
    if (!mounted) return;

    if (ok) {
      final goHome = await showAppDialog(
        context,
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        iconBackground: AppColors.successSoft,
        title: 'Kata Sandi Diperbarui',
        message:
            'Kata sandi kamu sudah berhasil diperbarui. Silakan masuk atau lanjutkan ke beranda.',
        cancelLabel: 'Halaman Masuk',
        confirmLabel: 'Ke Beranda',
        barrierDismissible: false,
      );
      if (!mounted) return;
      if (goHome == true) {
        openHome(context);
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    } else if (c.errorMessage != null) {
      showAppSnackBar(context, c.errorMessage!, type: AppSnackType.error);
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
                show
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
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
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.info, size: 19),
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
            builder: (_, c, __) => PrimaryButton(
              text: c.isLoading ? 'Menyimpan...' : 'Simpan Kata Sandi',
              onTap: c.isLoading ? null : submit,
            ),
          ),
        ],
      ),
    );
  }
}
