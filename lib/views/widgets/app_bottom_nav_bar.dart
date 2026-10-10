import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// URL foto profil dummy yang dipakai bila pengguna belum memasang foto.
///
/// Ganti dengan URL foto/aset milik aplikasi Anda. Bila perangkat sedang
/// offline, [AppBottomNavBar] otomatis memakai ikon orang sebagai cadangan.
const String kDummyAvatarUrl = 'https://i.pravatar.cc/200?img=47';

/// Satu tujuan navigasi pada [AppBottomNavBar].
///
/// Tiga mode pemakaian:
/// * **Item ikon material** — isi [icon] & [activeIcon]; ikon bertukar saat
///   aktif dan [label] (bila diisi) muncul di bawahnya.
/// * **Item ikon SVG** — isi [svgAsset] dengan path aset SVG. Warnanya otomatis
///   mengikuti warna aktif/nonaktif navbar (di-tint).
/// * **Item foto profil** — kosongkan [icon] & [svgAsset]; isi [imageUrl]
///   dengan foto pengguna. Bila [imageUrl] null, dipakai [kDummyAvatarUrl].
///   Item foto profil tidak menampilkan label.
@immutable
class AppNavItem {
  /// Ikon saat item tidak aktif (biasanya varian *outline*).
  /// Kosongkan bila item ini berupa foto profil atau memakai [svgAsset].
  final IconData? icon;

  /// Ikon saat item aktif (biasanya varian *filled/rounded*).
  /// Kosongkan bila item ini berupa foto profil atau memakai [svgAsset].
  final IconData? activeIcon;

  /// Path aset SVG (mis. `assets/images/komunitas.svg`).
  ///
  /// Bila diisi, ikon dirender dari SVG dan diwarnai otomatis mengikuti
  /// warna aktif/nonaktif. SVG sebaiknya memakai satu warna solid (mis.
  /// `fill="#000"`) agar hasil tint rapi.
  final String? svgAsset;

  /// Teks yang muncul di bawah ikon saat item aktif.
  /// `null` berarti item tidak pernah menampilkan label.
  final String? label;

  /// URL foto profil bulat. Hanya dipakai pada item foto profil
  /// (yaitu saat [icon] dan [svgAsset] kosong).
  final String? imageUrl;

  const AppNavItem({
    this.icon,
    this.activeIcon,
    this.svgAsset,
    this.label,
    this.imageUrl,
  });

  /// True bila item ini dirender sebagai foto profil, bukan ikon.
  bool get isAvatar => icon == null && svgAsset == null;
}

/// Palet warna navbar. Ubah nilainya agar sesuai tema aplikasi.
@immutable
class NavBarPalette {
  final Color barColor;
  final Color inactiveColor;
  final Color activeColor;
  final Color centerGradientStart;
  final Color centerGradientEnd;

  const NavBarPalette({
    this.barColor = Colors.white,
    this.inactiveColor = const Color(0xFF3B2231),
    this.activeColor = const Color(0xFFC2185B),
    this.centerGradientStart = const Color(0xFFF57C00),
    this.centerGradientEnd = const Color(0xFFD81B60),
  });
}

/// Bottom navigation bar dengan tombol utama melayang di tengah.
///
/// Menyediakan **5 tujuan navigasi** dalam urutan visual:
/// `[item0] [item1] (tengah) [item2] [item3]`.
/// Tombol tengah berada pada indeks visual **2** dan juga merupakan tujuan
/// navigasi (bukan aksi terpisah), sehingga navbar ini setara dengan
/// 5-tab bottom bar.
///
/// Perilaku:
/// * Item ikon bertukar ke [AppNavItem.activeIcon] dan menampilkan labelnya
///   saat aktif.
/// * Item foto profil menampilkan avatar bulat dan **tanpa label**.
/// * Tombol tengah menampilkan labelnya hanya saat ditekan.
///
/// Widget ini murni UI (tanpa state bisnis), sehingga aman dipakai ulang di
/// halaman mana pun.
///
/// Contoh (5 tab: Beranda, Kuis, Materi, Komunitas, Profil):
/// ```dart
/// AppBottomNavBar(
///   items: const [
///     AppNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Beranda'),
///     AppNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Kuis'),
///     AppNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble_rounded, label: 'Komunitas'),
///     AppNavItem(imageUrl: userPhotoUrl), // foto profil, tanpa label
///   ],
///   selectedIndex: _index,               // 0..4 (2 = tengah), -1 bila tidak ada
///   onSelect: (i) => setState(() => _index = i),
///   onCenterTap: () => setState(() => _index = 2),
///   centerIcon: Icons.menu_book_rounded,
///   centerLabel: 'Materi',
/// )
/// ```
class AppBottomNavBar extends StatelessWidget {
  /// Tepat 4 item untuk slot kiri/kanan. Tombol tengah terpisah dan menempati
  /// indeks visual 2.
  final List<AppNavItem> items;

  /// Indeks tujuan yang aktif dalam urutan visual (0..4), dengan 2 = tombol
  /// tengah. Gunakan -1 bila tidak ada yang aktif.
  final int selectedIndex;

  /// Dipanggil saat salah satu tujuan ditekan (menerima indeks visual 0..4).
  final ValueChanged<int> onSelect;

  /// Dipanggil saat tombol tengah ditekan.
  final VoidCallback onCenterTap;

  final IconData centerIcon;

  /// Teks pada tombol tengah. Tampil saat ditekan, dan permanen saat aktif.
  final String centerLabel;

  /// Warna navbar; ganti untuk menyesuaikan tema aplikasi.
  final NavBarPalette palette;

  /// Gaya teks label item aktif. Berguna bila ingin memakai font kustom
  /// (mis. `GoogleFonts.nunito(fontWeight: FontWeight.w800)`).
  final TextStyle? labelStyle;

  /// Foto profil yang dipakai bila [AppNavItem.imageUrl] null.
  final String dummyAvatarUrl;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCenterTap,
    this.centerIcon = Icons.add_rounded,
    this.centerLabel = 'Aksi',
    this.palette = const NavBarPalette(),
    this.labelStyle,
    this.dummyAvatarUrl = kDummyAvatarUrl,
  }) : assert(items.length == 4, 'AppBottomNavBar memerlukan tepat 4 item');

  /// Indeks visual tombol tengah.
  static const int centerIndex = 2;

  static const double _barHeight = 68;
  static const double _centerSize = 66;
  static const double _overhang = 26;

  @override
  Widget build(BuildContext context) {
    // Ruang aman bawah (notch/gesture bar) agar bar tidak tertutup.
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _overhang + _barHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Permukaan bar (putih, sudut atas membulat, bayangan halus).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _barHeight + bottomInset,
              decoration: BoxDecoration(
                color: palette.barColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
            ),
          ),

          // Baris item. Slot tengah sengaja dikosongkan untuk tombol melayang.
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            height: _barHeight,
            child: Row(
              children: [
                _buildItem(0, 0),
                _buildItem(1, 1),
                const Expanded(child: SizedBox()),
                _buildItem(2, 3),
                _buildItem(3, 4),
              ],
            ),
          ),

          // Tombol tengah yang menonjol ke atas bar (tujuan indeks visual 2).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _CenterButton(
                icon: centerIcon,
                label: centerLabel,
                size: _centerSize,
                startColor: palette.centerGradientStart,
                endColor: palette.centerGradientEnd,
                isSelected: selectedIndex == centerIndex,
                activeColor: palette.activeColor,
                onTap: onCenterTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [slot] = posisi pada baris (0..3), [destIndex] = indeks visual tujuan.
  Widget _buildItem(int slot, int destIndex) {
    return Expanded(
      child: _NavItemButton(
        item: items[slot],
        isSelected: destIndex == selectedIndex,
        activeColor: palette.activeColor,
        inactiveColor: palette.inactiveColor,
        labelStyle: labelStyle,
        dummyAvatarUrl: dummyAvatarUrl,
        onTap: () => onSelect(destIndex),
      ),
    );
  }
}

class _NavItemButton extends StatefulWidget {
  final AppNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final TextStyle? labelStyle;
  final String dummyAvatarUrl;
  final VoidCallback onTap;

  const _NavItemButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.dummyAvatarUrl,
    required this.onTap,
    this.labelStyle,
  });

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isSelected ? widget.activeColor : widget.inactiveColor;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.item.isAvatar
              ? _buildAvatar()
              : _buildIconItem(color),
        ),
      ),
    );
  }

  /// Item foto profil: avatar bulat, tanpa label.
  Widget _buildAvatar() {
    final url = widget.item.imageUrl ?? widget.dummyAvatarUrl;
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.isSelected
                ? widget.activeColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            url,
            width: 30,
            height: 30,
            fit: BoxFit.cover,
            // Cadangan bila foto gagal dimuat (mis. offline).
            errorBuilder: (_, __, ___) => Container(
              width: 30,
              height: 30,
              color: widget.inactiveColor.withValues(alpha: 0.15),
              child: Icon(Icons.person, size: 20, color: widget.inactiveColor),
            ),
          ),
        ),
      ),
    );
  }

  /// Item ikon: ikon bertukar saat aktif + label opsional.
  ///
  /// Saat tidak aktif, label disembunyikan sehingga ikon berada tepat di
  /// tengah bar. Saat aktif, label muncul dan mendorong ikon naik untuk
  /// memberi ruang di bawahnya.
  Widget _buildIconItem(Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: _buildLeadingIcon(color),
        ),
        if (widget.item.label != null)
          // Tinggi slot label dianimasikan: 0 saat tidak aktif (ikon di
          // tengah), membesar saat aktif (ikon bergeser naik).
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: widget.isSelected
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: 16,
                      child: Text(
                        widget.item.label!,
                        style: widget.labelStyle ??
                            TextStyle(
                              color: widget.activeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                      ),
                    ),
                  )
                : const SizedBox(width: 0, height: 0),
          ),
      ],
    );
  }

  /// Ikon utama item: dari SVG (di-tint) bila [AppNavItem.svgAsset] diisi,
  /// selain itu memakai ikon Material yang bertukar saat aktif.
  Widget _buildLeadingIcon(Color color) {
    final svgAsset = widget.item.svgAsset;
    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset,
        key: const ValueKey<String>('nav-svg'),
        width: 26,
        height: 26,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(
      widget.isSelected
          ? (widget.item.activeIcon ?? widget.item.icon)
          : widget.item.icon,
      key: ValueKey<bool>(widget.isSelected),
      color: color,
      size: 26,
    );
  }
}

class _CenterButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final double size;
  final Color startColor;
  final Color endColor;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _CenterButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.startColor,
    required this.endColor,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  State<_CenterButton> createState() => _CenterButtonState();
}

class _CenterButtonState extends State<_CenterButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Label tampil saat tombol aktif (tab tengah terpilih) atau sedang ditekan.
    final showLabel = widget.isSelected || _pressed;

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Cincin penanda saat tab tengah aktif.
              border: Border.all(
                color: widget.isSelected
                    ? widget.activeColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.startColor, widget.endColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.endColor.withValues(alpha: 0.40),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 24),
                  // Teks muncul saat tab aktif atau saat tombol ditekan.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: showLabel
                        ? Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : const SizedBox(width: 0, height: 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
