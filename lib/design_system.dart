import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:learnhangul/liquid_glass_buttons.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

const Color seedColor = Color(0xFFEF476F);
const Color accentColor = Color(0xFFFFC857);

class LearnHangulPalette extends ThemeExtension<LearnHangulPalette> {
  const LearnHangulPalette({
    required this.background,
    required this.surface,
    required this.elevatedSurface,
    required this.outline,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final Color background;
  final Color surface;
  final Color elevatedSurface;
  final Color outline;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  factory LearnHangulPalette.light() {
    return const LearnHangulPalette(
      background: Color(0xFFF5F5F7),
      surface: Color(0xFFF8F8F8),
      elevatedSurface: Color(0xFFFFFFFF),
      outline: Color(0x1A000000),
      primaryText: Colors.black,
      secondaryText: Color(0xFF2E2E2E),
      mutedText: Color(0xFF6E6E73),
      success: Color(0xFF2DCA72),
      warning: Colors.blue,
      danger: Color(0xFFEF476F),
      info: Color(0xFF569AFD),
    );
  }

  factory LearnHangulPalette.dark() {
    return const LearnHangulPalette(
      background: Colors.black,
      surface: Color(0xFF121212),
      elevatedSurface: Color(0xFF1E1E1E),
      outline: Color(0x33FFFFFF),
      primaryText: Colors.white,
      secondaryText: Color(0xFFE5E5EA),
      mutedText: Color(0xFF8E8E93),
      success: Color(0xFF2DCA72),
      warning: Colors.blue,
      danger: Color(0xFFF5556D),
      info: Color(0xFFA6C5FF),
    );
  }

  @override
  LearnHangulPalette copyWith({
    Color? background,
    Color? surface,
    Color? elevatedSurface,
    Color? outline,
    Color? primaryText,
    Color? secondaryText,
    Color? mutedText,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return LearnHangulPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      outline: outline ?? this.outline,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      mutedText: mutedText ?? this.mutedText,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  LearnHangulPalette lerp(ThemeExtension<LearnHangulPalette>? other, double t) {
    if (other is! LearnHangulPalette) return this;
    return LearnHangulPalette(
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      elevatedSurface:
          Color.lerp(elevatedSurface, other.elevatedSurface, t) ??
          elevatedSurface,
      outline: Color.lerp(outline, other.outline, t) ?? outline,
      primaryText: Color.lerp(primaryText, other.primaryText, t) ?? primaryText,
      secondaryText:
          Color.lerp(secondaryText, other.secondaryText, t) ?? secondaryText,
      mutedText: Color.lerp(mutedText, other.mutedText, t) ?? mutedText,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      info: Color.lerp(info, other.info, t) ?? info,
    );
  }
}

class LearnHangulTextStyles extends ThemeExtension<LearnHangulTextStyles> {
  const LearnHangulTextStyles({
    required this.hero,
    required this.heading,
    required this.subtitle,
    required this.body,
    required this.label,
    required this.caption,
  });

  final TextStyle hero;
  final TextStyle heading;
  final TextStyle subtitle;
  final TextStyle body;
  final TextStyle label;
  final TextStyle caption;

  factory LearnHangulTextStyles.fromPalette(LearnHangulPalette palette) {
    return LearnHangulTextStyles(
      hero: TextStyle(
        fontSize: 42,
        height: 1.1,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w700,
        color: palette.primaryText,
      ),
      heading: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: palette.primaryText,
      ),
      subtitle: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
        color: palette.secondaryText,
      ),
      body: TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: palette.primaryText,
      ),
      label: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: palette.primaryText,
      ),
      caption: TextStyle(
        fontSize: 13,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: palette.mutedText,
      ),
    );
  }

  @override
  LearnHangulTextStyles copyWith({
    TextStyle? hero,
    TextStyle? heading,
    TextStyle? subtitle,
    TextStyle? body,
    TextStyle? label,
    TextStyle? caption,
  }) {
    return LearnHangulTextStyles(
      hero: hero ?? this.hero,
      heading: heading ?? this.heading,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      label: label ?? this.label,
      caption: caption ?? this.caption,
    );
  }

  @override
  LearnHangulTextStyles lerp(
    ThemeExtension<LearnHangulTextStyles>? other,
    double t,
  ) {
    if (other is! LearnHangulTextStyles) return this;
    return LearnHangulTextStyles(
      hero: TextStyle.lerp(hero, other.hero, t) ?? hero,
      heading: TextStyle.lerp(heading, other.heading, t) ?? heading,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t) ?? subtitle,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      label: TextStyle.lerp(label, other.label, t) ?? label,
      caption: TextStyle.lerp(caption, other.caption, t) ?? caption,
    );
  }
}

class LearnHangulTheme {
  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final palette = brightness == Brightness.light
        ? LearnHangulPalette.light()
        : LearnHangulPalette.dark();
    final textStyles = LearnHangulTextStyles.fromPalette(palette);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        background: palette.background,
        surface: palette.surface,
      ),
      scaffoldBackgroundColor: palette.background,
      textTheme: _buildTextTheme(textStyles),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.primaryText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textStyles.heading,
      ),
      cardTheme: CardThemeData(
        color: palette.elevatedSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: palette.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textStyles.heading,
        contentTextStyle: textStyles.body,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.elevatedSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentTextStyle: textStyles.body.copyWith(color: palette.primaryText),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        iconColor: palette.secondaryText,
        textColor: palette.primaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: seedColor,
        scaffoldBackgroundColor: palette.background,
      ),
      extensions: [palette, textStyles],
    );
    return base;
  }

  static TextTheme _buildTextTheme(LearnHangulTextStyles typography) {
    return TextTheme(
      displayLarge: typography.hero,
      headlineMedium: typography.heading,
      titleLarge: typography.subtitle,
      bodyLarge: typography.body,
      bodyMedium: typography.body,
      labelLarge: typography.label,
      labelSmall: typography.caption,
    );
  }

  static LearnHangulPalette paletteOf(BuildContext context) {
    final palette = Theme.of(context).extension<LearnHangulPalette>();
    assert(
      palette != null,
      'LearnHangulPalette is missing from Theme extensions',
    );
    return palette!;
  }

  static LearnHangulTextStyles typographyOf(BuildContext context) {
    final typography = Theme.of(context).extension<LearnHangulTextStyles>();
    assert(
      typography != null,
      'LearnHangulTextStyles is missing from Theme extensions',
    );
    return typography!;
  }
}

enum LiquidGlassButtonVariant { primary, secondary, ghost, success, danger }

class LiquidGlassButton extends StatelessWidget {
  const LiquidGlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LiquidGlassButtonVariant.primary,
    this.expand = true,
    this.leading,
    this.trailing,
    this.labelStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final LiquidGlassButtonVariant variant;
  final bool expand;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = variant == LiquidGlassButtonVariant.primary
        ? palette.primaryText
        : variant == LiquidGlassButtonVariant.success
        ? palette.success
        : variant == LiquidGlassButtonVariant.danger
        ? palette.danger
        : palette.secondaryText;
    final labelWidget = Text(
      label,
      textAlign: expand ? TextAlign.center : TextAlign.start,
      style: typography.label
          .copyWith(
            color: textColor.withOpacity(onPressed == null ? 0.5 : 1.0),
            fontSize: 16,
          )
          .merge(labelStyle),
    );

    final borderColor = variant == LiquidGlassButtonVariant.success
        ? palette.success
        : variant == LiquidGlassButtonVariant.danger
        ? palette.danger
        : (isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.4));

    final glassColor = variant == LiquidGlassButtonVariant.success
        ? palette.success.withOpacity(0.12)
        : variant == LiquidGlassButtonVariant.danger
        ? palette.danger.withOpacity(0.12)
        : (isDark ? const Color(0x1AFFFFFF) : const Color(0x33FFFFFF));

    final content = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: glassColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(36),
        ),
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: expand
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            if (expand)
              Expanded(child: labelWidget)
            else
              Flexible(child: labelWidget),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );

    return LiquidGlassLayer(
      settings: LiquidGlassSettings(
        thickness: 5,
        glassColor: glassColor,
        lightIntensity: 1.5,
      ),
      child: LiquidGlass(
        shape: LiquidRoundedRectangle(borderRadius: 28.0),
        child: content,
      ),
    );
  }
}

enum LearnHangulDialogVariant { info, success, warning, danger }

class LearnHangulDialogAction {
  const LearnHangulDialogAction({
    required this.label,
    this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
}

class LearnHangulDialog extends StatelessWidget {
  const LearnHangulDialog({
    super.key,
    required this.title,
    required this.message,
    this.variant = LearnHangulDialogVariant.info,
    this.actions = const [],
  });

  final String title;
  final String message;
  final LearnHangulDialogVariant variant;
  final List<LearnHangulDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final accent = _accentForVariant(palette);

    final actionWidgets = actions.isEmpty
        ? [
            LiquidGlassButton(
              label: '확인',
              variant: LiquidGlassButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]
        : actions
              .map(
                (action) => LiquidGlassButton(
                  label: action.label,
                  variant: action.isPrimary
                      ? LiquidGlassButtonVariant.primary
                      : LiquidGlassButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    action.onTap?.call();
                  },
                ),
              )
              .toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_iconForVariant(), color: accent),
            ),
            const SizedBox(height: 16),
            Text(title, style: typography.heading),
            const SizedBox(height: 8),
            Text(
              message,
              style: typography.body.copyWith(color: palette.secondaryText),
            ),
            const SizedBox(height: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actionWidgets.length; i++) ...[
                  if (i != 0) const SizedBox(height: 12),
                  actionWidgets[i],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForVariant() {
    switch (variant) {
      case LearnHangulDialogVariant.success:
        return Icons.check_rounded;
      case LearnHangulDialogVariant.warning:
        return Icons.warning_amber_rounded;
      case LearnHangulDialogVariant.danger:
        return Icons.error_outline_rounded;
      case LearnHangulDialogVariant.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _accentForVariant(LearnHangulPalette palette) {
    switch (variant) {
      case LearnHangulDialogVariant.success:
        return palette.success;
      case LearnHangulDialogVariant.warning:
        return palette.warning;
      case LearnHangulDialogVariant.danger:
        return palette.danger;
      case LearnHangulDialogVariant.info:
        return palette.info;
    }
  }
}

enum LearnHangulSnackTone { neutral, success, warning, danger }

class LearnHangulSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    LearnHangulSnackTone tone = LearnHangulSnackTone.neutral,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final background = _toneColor(palette, tone);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: typography.body.copyWith(color: palette.background),
          ),
          backgroundColor: background,
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  textColor: palette.background,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }

  static Color _toneColor(
    LearnHangulPalette palette,
    LearnHangulSnackTone tone,
  ) {
    switch (tone) {
      case LearnHangulSnackTone.success:
        return palette.success;
      case LearnHangulSnackTone.warning:
        return palette.warning;
      case LearnHangulSnackTone.danger:
        return palette.danger;
      case LearnHangulSnackTone.neutral:
        return palette.secondaryText;
    }
  }
}

enum LearnHangulNoticeType { info, success, warning }

class LearnHangulNotice extends StatelessWidget {
  const LearnHangulNotice({
    super.key,
    required this.title,
    required this.message,
    this.type = LearnHangulNoticeType.info,
  });

  final String title;
  final String message;
  final LearnHangulNoticeType type;

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final color = _color(palette);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(), color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: typography.label.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: typography.body.copyWith(color: palette.secondaryText),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    switch (type) {
      case LearnHangulNoticeType.success:
        return Icons.celebration_outlined;
      case LearnHangulNoticeType.warning:
        return Icons.warning_amber_rounded;
      case LearnHangulNoticeType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _color(LearnHangulPalette palette) {
    switch (type) {
      case LearnHangulNoticeType.success:
        return palette.success;
      case LearnHangulNoticeType.warning:
        return palette.warning;
      case LearnHangulNoticeType.info:
        return palette.info;
    }
  }
}

enum LearnHangulListTileVariant { primary, danger }

class LearnHangulListTile extends StatelessWidget {
  const LearnHangulListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.variant = LearnHangulListTileVariant.primary,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final LearnHangulListTileVariant variant;

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final background = variant == LearnHangulListTileVariant.danger
        ? palette.danger.withOpacity(0.08)
        : palette.elevatedSurface;
    final borderColor = variant == LearnHangulListTileVariant.danger
        ? palette.danger.withOpacity(0.3)
        : palette.outline;

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(
          title,
          style: typography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: variant == LearnHangulListTileVariant.danger
                ? palette.danger
                : palette.primaryText,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, style: typography.caption),
        trailing:
            trailing ??
            Icon(Icons.chevron_right_rounded, color: palette.secondaryText),
      ),
    );
  }
}

class LearnHangulSurface extends StatelessWidget {
  const LearnHangulSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.backgroundColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    if (onTap == null) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? palette.elevatedSurface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: palette.outline),
          boxShadow: [
            BoxShadow(
              color: palette.primaryText.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: child,
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor ?? palette.elevatedSurface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: palette.outline),
          boxShadow: [
            BoxShadow(
              color: palette.primaryText.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class LearnHangulAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LearnHangulAppBar(
    this.title, {
    super.key,
    this.showLeading = true,
    this.trailing,
  });

  final String title;
  final bool showLeading;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);

    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      actionsPadding: const EdgeInsetsDirectional.only(end: 16),
      toolbarHeight: 77,
      leadingWidth: 77,
      centerTitle: true,
      backgroundColor: palette.background,
      foregroundColor: palette.primaryText,
      elevation: 0,
      title: Text(title, style: typography.heading.copyWith(fontSize: 20)),
      leading: showLeading
          ? Container(
              width: 77,
              height: 77,
              alignment: Alignment.center,
              child: LiquidGlassButtons.circularIconButton(
                context,
                onPressed: () => Navigator.of(context).pop(),
                // Use Cupertino chevron instead of Material arrow
                icon: CupertinoIcons.left_chevron,
                isBackgroundBright: false,
              ),
            )
          : null,
      actions: trailing == null ? null : [trailing!],
    );
  }
}
