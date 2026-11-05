// ============================================================
// SERVICE LAYER: baca/tulis preferensi ke SharedPreferences.
// Tidak boleh menyimpan state UI (itu tugas Controller).
// ============================================================
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  // --- Key penyimpanan ---
  static const _kDialect = 'settings_dialect';
  static const _kMirror = 'settings_mirror';
  static const _kDaily = 'settings_daily_reminder';
  static const _kHour = 'settings_reminder_hour';
  static const _kMinute = 'settings_reminder_minute';
  static const _kStreak = 'settings_streak_reminder';
  static const _kTextSize = 'settings_text_size';
  static const _kHaptic = 'settings_haptic';
  static const _kLanguage = 'settings_language';

  /// Membaca semua preferensi. Jika storage gagal (mis. saat test tanpa
  /// plugin), app tetap jalan dengan nilai default.
  Future<AppSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      const d = AppSettings();
      return AppSettings(
        dialect: p.getString(_kDialect) ?? d.dialect,
        mirrorMode: p.getBool(_kMirror) ?? d.mirrorMode,
        dailyReminder: p.getBool(_kDaily) ?? d.dailyReminder,
        reminderHour: p.getInt(_kHour) ?? d.reminderHour,
        reminderMinute: p.getInt(_kMinute) ?? d.reminderMinute,
        streakReminder: p.getBool(_kStreak) ?? d.streakReminder,
        textSize: TextSizeOption.fromName(p.getString(_kTextSize)),
        haptic: p.getBool(_kHaptic) ?? d.haptic,
        language: p.getString(_kLanguage) ?? d.language,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  /// Menyimpan semua preferensi sekaligus.
  Future<void> save(AppSettings s) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kDialect, s.dialect);
      await p.setBool(_kMirror, s.mirrorMode);
      await p.setBool(_kDaily, s.dailyReminder);
      await p.setInt(_kHour, s.reminderHour);
      await p.setInt(_kMinute, s.reminderMinute);
      await p.setBool(_kStreak, s.streakReminder);
      await p.setString(_kTextSize, s.textSize.name);
      await p.setBool(_kHaptic, s.haptic);
      await p.setString(_kLanguage, s.language);
    } catch (_) {
      // Abaikan: preferensi tetap berlaku selama sesi berjalan.
    }
  }
}