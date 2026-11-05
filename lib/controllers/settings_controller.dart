// ============================================================
// CONTROLLER LAYER (Thin Controller): memegang state Pengaturan
// dan mendelegasikan penyimpanan ke SettingsService.
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsController extends ChangeNotifier {
  final SettingsService _service;
  AppSettings _settings = const AppSettings();

  SettingsController({SettingsService? service})
      : _service = service ?? SettingsService();

  // --- Getter untuk View ---
  AppSettings get settings => _settings;

  /// Jam pengingat dalam format "18:00 WIB".
  String get reminderLabel {
    final h = _settings.reminderHour.toString().padLeft(2, '0');
    final m = _settings.reminderMinute.toString().padLeft(2, '0');
    return '$h:$m WIB';
  }

  String get languageLabel =>
      _settings.language == 'en' ? 'English' : 'Bahasa Indonesia';

  // --- Load & simpan ---
  Future<void> load() async {
    _settings = await _service.load();
    notifyListeners();
  }

  /// Update state dulu (UI langsung berubah), baru simpan ke storage.
  Future<void> _update(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _service.save(next);
  }

  /// Getaran ringan sebagai umpan balik, hanya jika haptic aktif.
  void _feedback() {
    if (_settings.haptic) HapticFeedback.selectionClick();
  }

  // --- Aksi yang dipanggil View ---
  Future<void> setDialect(String v) => _update(_settings.copyWith(dialect: v));

  Future<void> setMirrorMode(bool v) {
    _feedback();
    return _update(_settings.copyWith(mirrorMode: v));
  }

  Future<void> setDailyReminder(bool v) {
    _feedback();
    return _update(_settings.copyWith(dailyReminder: v));
  }

  Future<void> setReminderTime(int hour, int minute) => _update(
      _settings.copyWith(reminderHour: hour, reminderMinute: minute));

  Future<void> setStreakReminder(bool v) {
    _feedback();
    return _update(_settings.copyWith(streakReminder: v));
  }

  Future<void> setTextSize(TextSizeOption v) =>
      _update(_settings.copyWith(textSize: v));

  Future<void> setHaptic(bool v) {
    // Beri getaran saat dinyalakan supaya user langsung merasakannya.
    if (v) HapticFeedback.mediumImpact();
    return _update(_settings.copyWith(haptic: v));
  }

  Future<void> setLanguage(String v) =>
      _update(_settings.copyWith(language: v));

  /// Kembalikan semua preferensi ke default.
  Future<void> reset() => _update(const AppSettings());
}