import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Button variant for different visual styles
enum ButtonVariant {
  /// Standard liquid glass style
  standard,

  /// Confirmation / primary action
  confirmation,

  /// Destructive red action
  destructive,
}

/// Lightweight, self-contained Liquid Glass button helpers.
///
/// This file intentionally avoids depending on an external `AppColors`
/// utility. Instead it uses `Theme.of(context)` to pick sensible colors
/// so it works with the app's `ThemeData` (including custom theme
/// extensions).
class LiquidGlassButtons {
  LiquidGlassButtons._();

  // Local constants
  static const double _kButtonSizeStandard = 44.0;
  static const double _kButtonSizeLarge = 52.0;
  static const double _kButtonIconSize = 20.0;
  static const double _kBorderWidthAccent = 2.0;
  static const double _kBorderRadiusRound = 28.0;
  static const double _kButtonPaddingHorizontal = 16.0;

  // ------------------------- Icon Button -------------------------
  static Widget circularIconButton(
    BuildContext context, {
    VoidCallback? onPressed,
    IconData? icon,
    ButtonVariant variant = ButtonVariant.standard,
    bool isBackgroundBright = false,
    double? size,
    @Deprecated('Use variant parameter instead') bool? isConfirmationBlue,
  }) {
    final effectiveVariant = (isConfirmationBlue == true)
        ? ButtonVariant.confirmation
        : variant;

    final buttonSize = size ?? _kButtonSizeStandard;
    final decoration = _buildButtonDecoration(
      context,
      variant: effectiveVariant,
      isBackgroundBright: isBackgroundBright,
      borderRadius: buttonSize / 2,
    );

    // Compute a glassColor similar to the text button so visual effect matches
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final primary = theme.colorScheme.primary;
    Color glassColor;
    switch (effectiveVariant) {
      case ButtonVariant.confirmation:
        glassColor = primary.withOpacity(0.12);
        break;
      case ButtonVariant.destructive:
        glassColor = isBackgroundBright
            ? theme.colorScheme.surface.withOpacity(0.7)
            : (isLight ? const Color(0x33FFFFFF) : const Color(0x1AFFFFFF));
        break;
      case ButtonVariant.standard:
        glassColor = isBackgroundBright
            ? theme.colorScheme.surface.withOpacity(0.7)
            : (isLight ? const Color(0x33FFFFFF) : const Color(0x1AFFFFFF));
    }

    final content = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed ?? () => Navigator.pop(context),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: decoration,
        child: Center(
          child: Icon(
            icon ?? CupertinoIcons.left_chevron,
            size: _kButtonIconSize,
            color: _getIconColor(context, effectiveVariant),
          ),
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
        shape: LiquidRoundedRectangle(borderRadius: buttonSize / 2),
        child: content,
      ),
    );
  }

  // ------------------------- Text Buttons -------------------------
  static Widget circularTextButton(
    BuildContext context, {
    VoidCallback? onPressed,
    String? text,
    ButtonVariant variant = ButtonVariant.standard,
    bool isBackgroundBright = false,
    double? maxWidth,
    bool isEnabled = true,
    bool largeText = false,
    @Deprecated('Use variant parameter') bool? isConfirmationBlue,
    @Deprecated('Use variant parameter') bool? isRed,
  }) {
    final effectiveVariant = _resolveVariant(
      variant: variant,
      isConfirmationBlue: isConfirmationBlue,
      isRed: isRed,
    );

    return _buildTextButton(
      context,
      text: text,
      onPressed: onPressed,
      variant: effectiveVariant,
      isBackgroundBright: isBackgroundBright,
      minWidth: _kButtonSizeStandard,
      maxWidth: maxWidth,
      isEnabled: isEnabled,
      largeText: largeText,
    );
  }

  static Widget circularTextButtonWide(
    BuildContext context, {
    VoidCallback? onPressed,
    String? text,
    ButtonVariant variant = ButtonVariant.standard,
    bool isBackgroundBright = false,
    bool isEnabled = true,
    bool largeText = false,
  }) {
    return circularTextButton(
      context,
      text: text,
      onPressed: onPressed,
      variant: variant,
      isBackgroundBright: isBackgroundBright,
      maxWidth: 124.0,
      isEnabled: isEnabled,
      largeText: largeText,
    );
  }

  @Deprecated('Use circularTextButton with isEnabled parameter')
  static Widget circularTextButtonDeactivatable(
    BuildContext context, {
    VoidCallback? onPressed,
    String? text,
    ButtonVariant variant = ButtonVariant.standard,
    bool isBackgroundBright = false,
    bool isEnabled = true,
    bool largeText = false,
    bool? isConfirmationBlue,
    bool? isRed,
  }) {
    return circularTextButton(
      context,
      text: text,
      onPressed: onPressed,
      variant: variant,
      isBackgroundBright: isBackgroundBright,
      isEnabled: isEnabled,
      largeText: largeText,
      isConfirmationBlue: isConfirmationBlue,
      isRed: isRed,
    );
  }

  // ------------------------- Multi-Icon Buttons -------------------------
  static Widget dualIconButton(
    BuildContext context, {
    required IconData firstIcon,
    required VoidCallback onFirstPressed,
    required IconData secondIcon,
    required VoidCallback onSecondPressed,
    bool isBackgroundBright = false,
    double? size,
  }) {
    final btnSize = size ?? _kButtonSizeLarge;

    return _buildMultiIconButton(
      context,
      icons: [firstIcon, secondIcon],
      onPressedCallbacks: [onFirstPressed, onSecondPressed],
      isBackgroundBright: isBackgroundBright,
      buttonSize: btnSize,
    );
  }

  static Widget tripleIconButton(
    BuildContext context, {
    required IconData firstIcon,
    required VoidCallback onFirstPressed,
    required IconData secondIcon,
    required VoidCallback onSecondPressed,
    required IconData thirdIcon,
    required VoidCallback onThirdPressed,
    bool isBackgroundBright = false,
    double? size,
  }) {
    final btnSize = size ?? _kButtonSizeStandard;

    return _buildMultiIconButton(
      context,
      icons: [firstIcon, secondIcon, thirdIcon],
      onPressedCallbacks: [onFirstPressed, onSecondPressed, onThirdPressed],
      isBackgroundBright: isBackgroundBright,
      buttonSize: btnSize,
    );
  }

  static Widget quadrupleIconButton(
    BuildContext context, {
    required IconData firstIcon,
    required VoidCallback onFirstPressed,
    required IconData secondIcon,
    required VoidCallback onSecondPressed,
    required IconData thirdIcon,
    required VoidCallback onThirdPressed,
    required IconData fourthIcon,
    required VoidCallback onFourthPressed,
    bool isBackgroundBright = false,
    double? size,
    Widget? firstIconWidget,
    Widget? secondIconWidget,
    Widget? thirdIconWidget,
  }) {
    final btnSize = size ?? _kButtonSizeStandard;

    return _buildMultiIconButton(
      context,
      icons: [firstIcon, secondIcon, thirdIcon, fourthIcon],
      onPressedCallbacks: [
        onFirstPressed,
        onSecondPressed,
        onThirdPressed,
        onFourthPressed,
      ],
      customWidgets: [firstIconWidget, secondIconWidget, thirdIconWidget, null],
      isBackgroundBright: isBackgroundBright,
      buttonSize: btnSize,
    );
  }

  // ------------------------- Private helpers -------------------------
  static BoxDecoration _buildButtonDecoration(
    BuildContext context, {
    required ButtonVariant variant,
    required bool isBackgroundBright,
    required double borderRadius,
  }) {
    final theme = Theme.of(context);
    switch (variant) {
      case ButtonVariant.confirmation:
        final primary = theme.colorScheme.primary;
        return BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: primary.withValues(alpha: 0.12),
          border: Border.all(color: primary, width: _kBorderWidthAccent),
        );
      case ButtonVariant.destructive:
        return _liquidGlassBoxDecoration(
          context,
          isBackgroundBright: isBackgroundBright,
          borderRadius: borderRadius,
        );
      case ButtonVariant.standard:
        return _liquidGlassBoxDecoration(
          context,
          isBackgroundBright: isBackgroundBright,
          borderRadius: borderRadius,
        );
    }
  }

  static Color _getIconColor(BuildContext context, ButtonVariant variant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case ButtonVariant.confirmation:
        return isDark ? Colors.black : Colors.white;
      case ButtonVariant.destructive:
        return CupertinoColors.systemRed;
      case ButtonVariant.standard:
        return isDark ? Colors.white : Colors.black;
    }
  }

  static ButtonVariant _resolveVariant({
    required ButtonVariant variant,
    bool? isConfirmationBlue,
    bool? isRed,
  }) {
    if (isConfirmationBlue == true) return ButtonVariant.confirmation;
    if (isRed == true) return ButtonVariant.destructive;
    return variant;
  }

  static Widget _buildTextButton(
    BuildContext context, {
    required String? text,
    required VoidCallback? onPressed,
    required ButtonVariant variant,
    required bool isBackgroundBright,
    required double minWidth,
    double? maxWidth,
    required bool isEnabled,
    required bool largeText,
  }) {
    final effectiveVariant = isEnabled ? variant : ButtonVariant.standard;
    final decorationWithRadius = _buildButtonDecoration(
      context,
      variant: effectiveVariant,
      isBackgroundBright: isBackgroundBright,
      borderRadius: _kBorderRadiusRound,
    );

    Color textColor;
    if (!isEnabled) {
      final disabled = Theme.of(context).disabledColor;
      textColor = disabled.withOpacity(0.8);
    } else {
      textColor = _getIconColor(context, effectiveVariant);
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isEnabled ? (onPressed ?? () => Navigator.pop(context)) : null,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: _kButtonPaddingHorizontal),
        constraints: maxWidth != null
            ? BoxConstraints(minWidth: minWidth, maxWidth: maxWidth)
            : BoxConstraints(minWidth: minWidth),
        height: _kButtonSizeStandard,
        decoration: decorationWithRadius,
        child: Text(
          text ?? '편집',
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: largeText ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  static Widget _buildMultiIconButton(
    BuildContext context, {
    required List<IconData> icons,
    required List<VoidCallback> onPressedCallbacks,
    List<Widget?>? customWidgets,
    required bool isBackgroundBright,
    required double buttonSize,
  }) {
    assert(icons.length == onPressedCallbacks.length);

    return UnconstrainedBox(
      child: IntrinsicWidth(
        child: Container(
          height: buttonSize,
          decoration: _liquidGlassBoxDecoration(
            context,
            isBackgroundBright: isBackgroundBright,
            borderRadius: _kBorderRadiusRound,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(icons.length, (index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPressedCallbacks[index],
                child: SizedBox(
                  width: buttonSize,
                  height: buttonSize,
                  child: Center(
                    child:
                        customWidgets?[index] ??
                        Icon(
                          icons[index],
                          size: _kButtonIconSize,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  static BoxDecoration _liquidGlassBoxDecoration(
    BuildContext context, {
    required bool isBackgroundBright,
    required double borderRadius,
  }) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final isLight = theme.brightness == Brightness.light;
    final outline = isBackgroundBright
        ? theme.colorScheme.onSurface.withOpacity(0.12)
        : (isLight
              ? Colors.white.withOpacity(0.4)
              : Colors.white.withOpacity(0.03));
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: isBackgroundBright
          ? surface.withOpacity(0.7)
          : (isLight ? const Color(0x33FFFFFF) : const Color(0x1AFFFFFF)),
      border: Border.all(color: outline, width: 2.0),
    );
  }
}

@Deprecated('Use LiquidGlassButtons.circularIconButton instead')
Widget liquidGlassCircularIconButton(
  BuildContext context, {
  VoidCallback? onPressed,
  IconData? icon,
  bool? isBackgroundBright,
  bool? isRed,
  bool? isYellow,
  bool? isBlue,
  bool? isConfirmationBlue,
  double? size,
}) {
  return LiquidGlassButtons.circularIconButton(
    context,
    onPressed: onPressed,
    icon: icon,
    isBackgroundBright: isBackgroundBright ?? false,
    isConfirmationBlue: isConfirmationBlue,
    size: size,
  );
}
