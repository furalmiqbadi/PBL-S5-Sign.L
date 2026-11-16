import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import 'auth_views.dart';

/// Mendengarkan event `PASSWORD_RECOVERY` dari Supabase dan membuka
/// [ResetPage] saat pengguna mengklik tautan reset di email.
///
/// Event ini penting untuk tautan yang diterima saat aplikasi sudah berjalan
/// (mis. deep link di Android/iOS). Untuk tautan yang membuka aplikasi dari
/// keadaan tertutup, lihat [AuthRecovery.detectInitialRecovery].
class AuthRecoveryListener extends StatefulWidget {
  final Widget child;

  /// `true` bila [ResetPage] sudah ditampilkan sebagai halaman awal.
  final bool initiallyOpened;

  const AuthRecoveryListener({
    super.key,
    required this.child,
    this.initiallyOpened = false,
  });

  @override
  State<AuthRecoveryListener> createState() => _AuthRecoveryListenerState();
}

class _AuthRecoveryListenerState extends State<AuthRecoveryListener> {
  StreamSubscription<AuthState>? _subscription;
  late bool _opened = widget.initiallyOpened;

  @override
  void initState() {
    super.initState();
    _subscription = AuthService().authStateChanges?.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _openResetPage();
      }
    });
  }

  void _openResetPage() {
    if (_opened) return;
    _opened = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ResetPage()),
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
