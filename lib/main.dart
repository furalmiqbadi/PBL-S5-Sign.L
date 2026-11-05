import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/settings_controller.dart';
import 'services/supabase_config.dart';
import 'views/auth/auth_views.dart';
import 'views/main_shell.dart';
import 'views/theme/app_colors.dart';
import 'views/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase bila konfigurasi Project URL & Anon Key sudah diisi
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('[Supabase] Gagal inisialisasi: $e');
    }
  }

  runApp(const SignLApp());
}

/// Root aplikasi Sign.L.
///
/// Menyediakan seluruh controller lewat [MultiProvider] dan menampilkan
/// [LoginPage] sebagai titik awal (atau [MainShell] bila sudah login).
class SignLApp extends StatelessWidget {
  final Widget? home;

  const SignLApp({super.key, this.home});

  Widget _determineInitialHome() {
    if (home != null) return home!;
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
        ChangeNotifierProvider(create: (_) => ChatController()..loadRooms()),
        ChangeNotifierProvider(
          create: (_) => NotificationController()..load(),
        ),
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
        home: _determineInitialHome(),
      ),
    );
  }
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
