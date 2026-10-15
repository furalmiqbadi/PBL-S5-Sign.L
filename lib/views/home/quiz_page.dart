import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class _Soal {
  final String target;
  final List<String> pilihan;
  const _Soal(this.target, this.pilihan);
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Huruf yang dipakai untuk soal (10 soal). Sesuaikan dengan gambar yang kamu punya.
  static const List<String> _hurufList = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'
  ];

  late List<_Soal> _soal;
  int _index = 0;
  int? _selected; 
  bool _checked = false;
  int _benar = 0;
  int _hearts = 5;
  int _xp = 0;

  @override
  void initState() {
    super.initState();
    _buatSoal();
  }

  void _buatSoal() {
    final rnd = Random();
    final targets = List<String>.from(_hurufList)..shuffle(rnd);
    _soal = targets.map((t) {
      final lain = List<String>.from(_hurufList)..remove(t);
      lain.shuffle(rnd);
      final pilihan = [t, ...lain.take(3)]..shuffle(rnd);
      return _Soal(t, pilihan);
    }).toList();
    _index = 0;
    _selected = null;
    _checked = false;
    _benar = 0;
    _hearts = 5;
    _xp = 0;
  }

  _Soal get _current => _soal[_index];
  bool get _jawabanBenar =>
      _selected != null && _current.pilihan[_selected!] == _current.target;

  String _imgPath(String huruf) =>
      'assets/images/kuis${huruf.toLowerCase()}.jpg';

  void _periksa() {
    if (_selected == null || _checked) return;
    setState(() {
      _checked = true;
      if (_jawabanBenar) {
        _benar++;
        _xp += 10;
      } else {
        _hearts--;
      }
    });
  }

  void _lanjut() {
    final habis = _hearts <= 0;
    final terakhir = _index >= _soal.length - 1;
    if (habis || terakhir) {
      _tampilHasil();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _checked = false;
    });
  }

  void _tampilHasil() {
    final lulus = _benar >= (_soal.length * 0.6).ceil();
    final String pesan = lulus
        ? 'Hebat! Kamu sudah menguasai alfabet BISINDO.'
        : (_hearts <= 0
            ? 'Nyawa habis, coba lagi ya.'
            : 'Minimal benar ${(_soal.length * 0.6).ceil()} dari ${_soal.length} soal untuk lulus.');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Kartu utama
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 44),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lulus ? 'Lulus!' : 'Belum Lulus',
                    style: TextStyle(
                      color: lulus ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pesan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _statBox(
                        const Icon(Icons.check_circle,
                            color: AppColors.primary, size: 22),
                        'BENAR',
                        '$_benar/${_soal.length}',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      _statBox(
                        _svgIcon(
                            'assets/images/diamond_fix.svg', 22, AppColors.secondary),
                        'DIAMOND',
                        '$_xp',
                        AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      _statBox(
                        _svgIcon(
                            'assets/images/heart_fix.svg', 22, AppColors.danger),
                        'HATI',
                        '$_hearts',
                        AppColors.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (lulus)
                    _gradientButton('Selesai', () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    })
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(
                                    color: AppColors.border, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Selesai',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _gradientButton('Ulangi', () {
                            Navigator.pop(ctx);
                            setState(_buatSoal);
                          }),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Ikon bulat di atas kartu
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: lulus ? AppColors.brandGradient : null,
                color: lulus ? null : AppColors.textSecondary,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                lulus ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: Colors.white,
                size: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ikon SVG yang di-tint sesuai [color] agar konsisten dengan token tema.
  Widget _svgIcon(String asset, double size, Color color) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _statBox(Widget icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton(String label, VoidCallback onTap) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildTargetCard(),
                    const SizedBox(height: 16),
                    _buildOptionsGrid(),
                    const SizedBox(height: 20),
                    if (_checked) _buildFeedback(),
                    _buildActionButton(),
                    const SizedBox(height: 12),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: LinearProgressIndicator(
                value: (_index + (_checked ? 1 : 0)) / _soal.length,
                minHeight: 12,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _svgIcon('assets/images/heart_fix.svg', 18, AppColors.danger),
          const SizedBox(width: 4),
          Text('$_hearts',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          _svgIcon('assets/images/diamond_fix.svg', 18, AppColors.secondary),
          const SizedBox(width: 4),
          Text('$_xp',
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Text(
                'ALFABET BISINDO',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pertanyaan ${_index + 1} dari ${_soal.length}',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Manakah gestur tangan untuk huruf:',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.27,
            letterSpacing: -0.55,
          ),
        ),
      ],
    );
  }

  Widget _buildTargetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HURUF TARGET',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '"${_current.target}"',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.volume_up, color: AppColors.primary),
              onPressed: () {
                // TODO: putar audio huruf
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid() {
    final pilihan = _current.pilihan;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pilihan.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, i) {
        final huruf = pilihan[i];
        final bool selected = _selected == i;
        final bool isCorrect = huruf == _current.target;

        // Warna border/badge sesuai status
        Color accent = Colors.transparent;
        if (_checked) {
          if (isCorrect) {
            accent = AppColors.success;
          } else if (selected) {
            accent = AppColors.danger;
          }
        } else if (selected) {
          accent = AppColors.primary;
        }
        final bool aktif = accent != Colors.transparent;

        return GestureDetector(
          onTap: _checked ? null : () => setState(() => _selected = i),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(width: 2, color: accent),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _imgPath(huruf),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.border,
                      child: const Icon(Icons.pan_tool_alt_outlined,
                          color: AppColors.textSecondary, size: 40),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 4,
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: aktif ? accent : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        // Label A-D sesuai posisi, bukan huruf aslinya
                        String.fromCharCode(65 + i),
                        style: TextStyle(
                          color: aktif ? Colors.white : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (aktif)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _checked && !isCorrect ? Icons.close : Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback() {
    final benar = _jawabanBenar;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (benar ? AppColors.success : AppColors.danger)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(benar ? Icons.check_circle : Icons.cancel,
              color: benar ? AppColors.success : AppColors.danger),
          const SizedBox(width: 8),
          if (benar) ...[
            _svgIcon('assets/images/diamond_fix.svg', 14, AppColors.secondary),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              benar
                  ? 'Benar! +10'
                  : 'Kurang tepat. Jawaban yang benar ditandai hijau.',
              style: TextStyle(
                color: benar ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final bool bisaPeriksa = _selected != null;
    final bool terakhir = _index >= _soal.length - 1;
    final String label = !_checked
        ? 'Periksa Jawaban'
        : (terakhir || _hearts <= 0 ? 'Lihat Hasil' : 'Lanjut');

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _checked ? _lanjut : (bisaPeriksa ? _periksa : null),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
        SizedBox(width: 6),
        Text(
          'Bahasa Isyarat Indonesia (BISINDO)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
