import 'package:flutter/material.dart';

class IsiMateriBottomBar extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onCamera;
  final VoidCallback onNext;
  final bool isFirst;
  final bool isLast;

  const IsiMateriBottomBar({
    super.key,
    required this.onPrevious,
    required this.onCamera,
    required this.onNext,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: const BoxDecoration(
        color: Color(0xF2FCF9F8),
        border: Border(top: BorderSide(color: Color(0xFFF0EDEC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: isFirst ? 0.4 : 1,
              child: _outlineButton(
                label: 'Sebelumnya',
                fg: const Color(0xFF8639B4),
                onTap: isFirst ? () {} : onPrevious,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _outlineButton(
              label: 'Coba Foto',
              fg: const Color(0xFFDD2A7B),
              onTap: onCamera,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onNext,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFDD2A7B),
                      Color(0xFFB5005F),
                      Color(0xFF8639B4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3FDD2A7B),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isLast ? 'Selesai' : 'Lanjut',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0x4CFFD9E2),
          border: Border.all(color: const Color(0x33DD2A7B), width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}