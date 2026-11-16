import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/settings_controller.dart';
import 'services/auth_recovery.dart';
import 'services/supabase_config.dart';
import 'views/auth/auth_recovery_listener.dart';
import 'views/auth/auth_views.dart';
import 'views/main_shell.dart';
import 'views/theme/app_colors.dart';
import 'views/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Deteksi tautan reset kata sandi sebelum Supabase membersihkan parameter URL.
  final openedFromRecovery = await AuthRecovery.detectInitialRecovery();

  // Inisialisasi Supabase bila konfigurasi Project URL & Anon Key sudah diisi
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Supabase] Gagal inisialisasi: $e');
    }
  }

  runApp(SignLApp(openedFromRecovery: openedFromRecovery));
}

/// Root aplikasi Sign.L.
///
/// Menyediakan seluruh controller lewat [MultiProvider] dan menampilkan
/// [LoginPage] sebagai titik awal (atau [MainShell] bila sudah login).
class SignLApp extends StatelessWidget {
  final Widget? home;

  /// `true` bila aplikasi dibuka dari tautan reset kata sandi.
  final bool openedFromRecovery;

  const SignLApp({
    super.key,
    this.home,
    this.openedFromRecovery = false,
  });

  Widget _determineInitialHome() {
    if (home != null) return home!;
    if (openedFromRecovery) return const ResetPage();
    try {
      if (Supabase.instance.client.auth.currentSession != null) {
        return const MainShell();
      }
    } catch (_) {}
    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(
          create: (_) => NotificationController(),
        ),
        ChangeNotifierProvider(create: (_) => ProfileController()),
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
          return _SessionSync(
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(base * scale)),
              child: child!,
            ),
          );
        },
        home: AuthRecoveryListener(
          initiallyOpened: openedFromRecovery,
          child: _determineInitialHome(),
        ),
      ),
    );
  }
}

/// Menjaga data chat dan notifikasi mengikuti akun Supabase yang aktif.
class _SessionSync extends StatefulWidget {
  const _SessionSync({required this.child});

  final Widget child;

  @override
  State<_SessionSync> createState() => _SessionSyncState();
}

class _SessionSyncState extends State<_SessionSync> {
  StreamSubscription<AuthState>? _authSub;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());
  }

  void _startSync() {
    try {
      final auth = Supabase.instance.client.auth;
      _authSub = auth.onAuthStateChange.listen(_handleAuthState);
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        _syncUser(currentUser.id);
      }
    } catch (_) {
      // Supabase tidak tersedia saat unit/widget test atau konfigurasi belum ada.
    }
  }

  void _handleAuthState(AuthState state) {
    if (!mounted) return;
    if (state.event == AuthChangeEvent.signedOut || state.session == null) {
      _userId = null;
      context.read<ChatController>().reset();
      context.read<NotificationController>().reset();
      context.read<ProfileController>().reset();
      return;
    }

    final userId = state.session!.user.id;
    if (state.event == AuthChangeEvent.initialSession ||
        state.event == AuthChangeEvent.signedIn ||
        userId != _userId) {
      _syncUser(userId);
    }
  }

  void _syncUser(String userId) {
    if (!mounted || _userId == userId) return;
    _userId = userId;
    final chat = context.read<ChatController>();
    final notifications = context.read<NotificationController>();
    chat.loadRooms();
    notifications.load(force: true);
    context.read<ProfileController>().load(force: true);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Nama lama agar widget test bawaan Flutter tetap kompatibel.
class MyApp extends SignLApp {
  const MyApp({super.key, super.home});
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
