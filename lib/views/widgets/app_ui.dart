import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared visual radii and spacing tokens aligned with Material Design 3
/// while keeping Sign.L's soft, friendly surface language.
class AppRadii {
  AppRadii._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double dialog = 28;
  static const double pill = 999;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}

enum AppSnackType { info, success, warning, error }

/// Displays a consistent Material Design 3 floating snackbar with a semantic icon.
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.info,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  // Warna aksen memakai token brand; latar memakai `textPrimary` (navy gelap)
  // agar snackbar tetap punya kontras tinggi tanpa warna literal baru.
  final (IconData icon, Color accent, Color bg) = switch (type) {
    AppSnackType.success => (
        Icons.check_circle_rounded,
        AppColors.secondary,
        AppColors.textPrimary,
      ),
    AppSnackType.warning => (
        Icons.warning_amber_rounded,
        AppColors.tertiary,
        AppColors.textPrimary,
      ),
    AppSnackType.error => (
        Icons.error_rounded,
        AppColors.danger,
        AppColors.textPrimary,
      ),
    AppSnackType.info => (
        Icons.info_rounded,
        AppColors.info,
        AppColors.textPrimary,
      ),
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: BorderSide(color: accent.withValues(alpha: 0.28)),
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: accent,
                onPressed: onAction,
              )
            : null,
        content: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Shows a Material Design 3 confirmation or informational dialog with a
/// cohesive icon header, clear typography hierarchy, and 48dp action buttons.
Future<bool?> showAppDialog(
  BuildContext context, {
  required String title,
  String? message,
  Widget? content,
  IconData? icon,
  Color iconColor = AppColors.primary,
  Color? iconBackground,
  String confirmLabel = 'Oke',
  String cancelLabel = 'Batal',
  bool showCancel = true,
  bool isDestructive = false,
  bool barrierDismissible = true,
  bool centerHeader = false,
}) {
  final effectiveAccent = isDestructive ? AppColors.danger : iconColor;
  final effectiveIconBg = iconBackground ??
      (isDestructive
          ? AppColors.dangerSoft
          : effectiveAccent.withValues(alpha: 0.12));

  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.dialog),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerHeader
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(icon, color: effectiveAccent, size: 24),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  title,
                  textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null && message.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign:
                        centerHeader ? TextAlign.center : TextAlign.start,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                if (content != null) ...[
                  const SizedBox(height: 14),
                  content,
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (showCancel) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          child: Text(cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                          backgroundColor: isDestructive
                              ? AppColors.danger
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Shows a polished modal bottom sheet with drag handle, optional header,
/// keyboard inset support, and SafeArea handling.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext sheetContext) builder,
  String? title,
  String? subtitle,
  IconData? icon,
  Color iconColor = AppColors.primary,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool isDismissible = true,
  bool showCloseButton = true,
  EdgeInsetsGeometry contentPadding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.dialog),
              ),
              boxShadow: AppShadows.floating,
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                      ),
                    ),
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                        child: Row(
                          children: [
                            if (icon != null) ...[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle != null &&
                                      subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (showCloseButton)
                              AppIconButton(
                                icon: Icons.close_rounded,
                                tooltip: 'Tutup',
                                onPressed: () => Navigator.pop(sheetContext),
                                backgroundColor: AppColors.surfaceMuted,
                                borderColor: Colors.transparent,
                                size: 40,
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                    ] else
                      const SizedBox(height: 6),
                    Flexible(
                      child: Padding(
                        padding: contentPadding,
                        child: builder(sheetContext),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Consistent elevated-outlined Material 3 card with InkWell ripple support.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final double borderWidth;
  final List<BoxShadow>? shadows;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.gradient,
    this.borderColor,
    this.borderRadius = AppRadii.xl,
    this.borderWidth = 1,
    this.shadows = AppShadows.card,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    // Kartu memakai permukaan putih bersih dengan garis tepi tipis agar tetap
    // tegas di atas latar bergradasi. Varian `gradient` disediakan untuk
    // kebutuhan khusus, tetapi secara aturan desain gradasi merek hanya
    // dipakai tombol tengah navbar. Saat memakai gradien, `color` diabaikan.
    final decoration = gradient != null
        ? BoxDecoration(
            gradient: gradient,
            borderRadius: radius,
            boxShadow: shadows,
          )
        : BoxDecoration(
            color: color ?? AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? AppColors.border,
              width: borderWidth,
            ),
            boxShadow: shadows,
          );

    return Container(
      margin: margin,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              )
            : Padding(
                padding: padding,
                child: child,
              ),
      ),
    );
  }
}

/// Action button melayang untuk aksi utama halaman.
///
/// Memakai `primary` solid, bukan gradasi merek: sesuai `docs/prd/design.md`
/// gradasi hanya dipakai tombol tengah navbar.
class AppFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Tampilkan versi redup (mis. batas soal tercapai) tanpa mematikan tap,
  /// agar pengguna tetap mendapat pesan penjelasan.
  final bool muted;

  const AppFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final aktif = onPressed != null && !muted;
    final radius = BorderRadius.circular(AppRadii.md);
    return Container(
      decoration: BoxDecoration(
        color: aktif ? AppColors.primary : AppColors.textMuted,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: (aktif ? AppColors.primary : AppColors.textMuted)
                .withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.textOnPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.labelLarge
                      .copyWith(color: AppColors.textOnPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accessible icon button preserving at least a 48x48 touch area.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final double borderRadius;
  final bool showBadge;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = 44,
    this.iconSize = 20,
    this.borderRadius = AppRadii.md,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    Widget button = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: backgroundColor ?? AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: borderColor ?? AppColors.border,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? AppColors.textPrimary,
                  ),
                  if (showBadge)
                    Positioned(
                      top: 9,
                      right: 9,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: backgroundColor ?? AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Pill filter/choice chip with consistent M3 height, subtle outline, and ripple.
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color selectedColor;

  const AppChoiceChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.selectedColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.pill);
    return Material(
      color: isSelected ? selectedColor : AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? selectedColor : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tonal pill badge for roles, levels, XP rewards, and category tags.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action tile for modal bottom sheets matching M3 list styling.
class AppSheetOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color? iconBackground;
  final Color? titleColor;
  final Widget? trailing;
  final bool isSelected;
  final VoidCallback onTap;

  const AppSheetOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor = AppColors.primary,
    this.iconBackground,
    this.titleColor,
    this.trailing,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.md);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color:
            isSelected ? iconColor.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: isSelected
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.28),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBackground ?? iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: titleColor ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      size: 20,
                      color: isSelected ? iconColor : AppColors.textMuted,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
