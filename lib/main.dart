import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/settings_controller.dart';
import 'views/auth/auth_views.dart';
import 'views/theme/app_colors.dart';
import 'views/theme/app_theme.dart';

void main() {
  runApp(const SignLApp());
}

/// Root aplikasi Sign.L.
///
/// Menyediakan seluruh controller lewat [MultiProvider] dan menampilkan
/// [LoginPage] sebagai titik awal. Setelah autentikasi (masih mock, belum
/// terhubung database) user diarahkan ke kerangka utama `MainShell`.
class SignLApp extends StatelessWidget {
  const SignLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
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
        home: const LoginPage(),
      ),
    );
  }
}

/// Nama lama agar widget test bawaan Flutter tetap kompatibel.
class MyApp extends SignLApp {
  const MyApp({super.key});
}

/// Perilaku scroll tanpa efek "karet" (stretch overscroll) di Android.
///
/// Secara default Flutter 3.x memakai [StretchingOverscrollIndicator] pada
/// Android 12+, sehingga konten terlihat melar seperti karet lalu memantul
/// saat mencapai ujung daftar. Kita ganti dengan indikator glow agar scroll
/// terasa normal dan tidak ada distorsi.
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