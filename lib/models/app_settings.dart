// ============================================================
// MODEL LAYER: data murni preferensi pengguna.
// Tidak ada logika UI, storage, atau Firebase di sini.
// ============================================================

/// Pilihan ukuran teks aplikasi. [scale] dikalikan ke text scale sistem.
enum TextSizeOption {
  small('Kecil', 0.9),
  standard('Standar', 1.0),
  large('Besar', 1.15);

  final String label;
  final double scale;
  const TextSizeOption(this.label, this.scale);

  /// Dipakai saat membaca dari storage; fallback ke "Standar" bila tidak valid.
  static TextSizeOption fromName(String? name) => TextSizeOption.values
      .firstWhere((o) => o.name == name, orElse: () => TextSizeOption.standard);
}

/// Seluruh preferensi yang bisa diatur di halaman Pengaturan.
class AppSettings {
  /// Dialek isyarat utama: 'BISINDO' atau 'SIBI'.
  final String dialect;
  final bool mirrorMode;
  final bool dailyReminder;
  final int reminderHour;
  final int reminderMinute;
  final bool streakReminder;
  final TextSizeOption textSize;
  final bool haptic;

  /// Kode bahasa antarmuka: 'id' atau 'en'.
  final String language;

  const AppSettings({
    this.dialect = 'BISINDO',
    this.mirrorMode = true,
    this.dailyReminder = true,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.streakReminder = true,
    this.textSize = TextSizeOption.standard,
    this.haptic = true,
    this.language = 'id',
  });

  AppSettings copyWith({
    String? dialect,
    bool? mirrorMode,
    bool? dailyReminder,
    int? reminderHour,
    int? reminderMinute,
    bool? streakReminder,
    TextSizeOption? textSize,
    bool? haptic,
    String? language,
  }) {
    return AppSettings(
      dialect: dialect ?? this.dialect,
      mirrorMode: mirrorMode ?? this.mirrorMode,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      streakReminder: streakReminder ?? this.streakReminder,
      textSize: textSize ?? this.textSize,
      haptic: haptic ?? this.haptic,
      language: language ?? this.language,
    );
  }
}