import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/friend_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/settings_controller.dart';
import 'services/auth_recovery.dart';
import 'services/auth_service.dart';
import 'services/secure_session_storage.dart';
import 'services/session_bootstrap.dart';
import 'services/supabase_config.dart';
import 'views/admin/admin_panel_page.dart';
import 'views/auth/auth_recovery_listener.dart';
import 'views/auth/auth_views.dart';
import 'views/main_shell.dart';
import 'views/theme/app_colors.dart';
import 'views/theme/app_theme.dart';
import 'views/widgets/auth_widgets.dart' show SignLogo;

/// Kunci sesi bawaan supabase_flutter di `SharedPreferences`. Dipakai sekali
/// agar sesi pengguna versi sebelumnya ikut pindah ke penyimpanan terenkripsi.
String get _kunciSesiLama =>
    'sb-${Uri.parse(SupabaseConfig.supabaseUrl).host.split('.').first}-auth-token';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Deteksi tautan reset kata sandi sebelum Supabase membersihkan parameter URL.
  final openedFromRecovery = await AuthRecovery.detectInitialRecovery();
  final recoveryError = AuthRecovery.initialErrorMessage;

  // Inisialisasi Supabase bila konfigurasi Project URL & Anon Key sudah diisi
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
        // "Save login" ala Instagram: sesi disimpan terenkripsi di perangkat
        // (Android Keystore / iOS Keychain) dan dipulihkan otomatis saat
        // aplikasi dibuka lagi, tanpa perlu masuk ulang.
        authOptions: FlutterAuthClientOptions(
          persistSession: true,
          autoRefreshToken: true,
          localStorage: SecureSessionStorage(
            legacyKey: _kunciSesiLama,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Supabase] Gagal inisialisasi: $e');
    }
  }

  runApp(SignLApp(
    openedFromRecovery: openedFromRecovery,
    recoveryError: recoveryError,
  ));
}

/// Root aplikasi Sign.L.
///
/// Menyediakan seluruh controller lewat [MultiProvider] dan menampilkan
/// [LoginPage] sebagai titik awal (atau [MainShell] bila sudah login).
class SignLApp extends StatelessWidget {
  final Widget? home;

  /// `true` bila aplikasi dibuka dari tautan reset kata sandi.
  final bool openedFromRecovery;

  /// Pesan bila tautan reset ditolak Supabase (`?error=...`).
  final String? recoveryError;

  const SignLApp({
    super.key,
    this.home,
    this.openedFromRecovery = false,
    this.recoveryError,
  });

  Widget _determineInitialHome() {
    if (home != null) return home!;
    if (openedFromRecovery) return const ResetPage();
    try {
      // Sesi tersimpan diperiksa dulu (masih berlaku / perlu refresh);
      // selama memeriksa, aplikasi menampilkan layar tunggu singkat.
      if (Supabase.instance.client.auth.currentSession != null) {
        return const _SessionGate();
      }
    } catch (_) {}
    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Chat & notifikasi dimuat setelah layar utama tampil (lihat
        // MainShell) supaya pembukaan aplikasi tidak menunggu jaringan.
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => FriendController()),
        // `..load()` membaca preferensi tersimpan (mis. ukuran teks) saat app dibuka.
        ChangeNotifierProvider(create: (_) => SettingsController()..load()),
      ],
      child: MaterialApp(
        title: 'Sign.L',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Matikan efek "karet" (stretch overscroll) bawaan Android 12+.
        scrollBehavior: const _NoStretchScrollBehavior(),
        // Ukuran teks dari halaman Pengaturan diterapkan ke seluruh aplikasi.
        builder: (context, child) {
          final scale = context.select<SettingsController, double>(
            (c) => c.settings.textSize.scale,
          );
          final base = MediaQuery.textScalerOf(context).scale(1);
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(base * scale)),
            child: child!,
          );
        },
        home: AuthRecoveryListener(
          initiallyOpened: openedFromRecovery,
          errorMessage: recoveryError,
          child: _determineInitialHome(),
        ),
      ),
    );
  }
}

/// Nama lama agar widget test bawaan Flutter tetap kompatibel.
class MyApp extends SignLApp {
  const MyApp({super.key, super.home});
}

/// Memeriksa sesi tersimpan sebelum beranda dibuka ("save login" ala Instagram).
///
/// Selama memeriksa, layar tunggu singkat ditampilkan. Sesi yang masih berlaku
/// (atau hanya gagal diperbarui karena jaringan) langsung masuk ke
/// [_SessionLanding]; sesi yang tidak ada atau ditolak server menuju
/// [LoginPage].
class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  bool? _masuk; // null = masih memeriksa

  @override
  void initState() {
    super.initState();
    _periksa();
  }

  Future<void> _periksa() async {
    final status = await SessionBootstrap.periksa();
    if (!mounted) return;
    setState(() => _masuk = status == StatusSesi.masuk);
  }

  @override
  Widget build(BuildContext context) {
    final masuk = _masuk;
    if (masuk == null) {
      return const _WaitScreen();
    }
    return masuk ? const _SessionLanding() : const LoginPage();
  }
}

/// Layar tunggu diwarnai latar aplikasi, dipakai gate sesi dan pembacaan role.
class _WaitScreen extends StatelessWidget {
  const _WaitScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SignLogo(size: 72, showText: false),
            SizedBox(height: 20),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menentukan halaman awal saat sesi Supabase sudah aktif.
///
/// Role dibaca dari tabel `profiles`: `admin` langsung dibuka ke
/// [AdminPanelPage], selain itu ke [MainShell].
class _SessionLanding extends StatefulWidget {
  const _SessionLanding();

  @override
  State<_SessionLanding> createState() => _SessionLandingState();
}

class _SessionLandingState extends State<_SessionLanding> {
  bool _isAdmin = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().fetchRole();
    if (!mounted) return;
    setState(() {
      _isAdmin = role == 'admin';
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _WaitScreen();
    return _isAdmin ? const AdminPanelPage() : const MainShell();
  }
}

/// Perilaku scroll tanpa efek "karet" (stretch overscroll) di Android.
class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return GlowingOverscrollIndicator(
      axisDirection: details.direction,
      color: AppColors.primary,
      child: child,
    );
  }
}
