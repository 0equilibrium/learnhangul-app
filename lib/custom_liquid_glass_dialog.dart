import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomLiquidGlassDialog extends StatefulWidget {
  const CustomLiquidGlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.onDismiss,
    this.showCloseButton = false,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final VoidCallback? onDismiss;
  final bool showCloseButton;

  @override
  State<CustomLiquidGlassDialog> createState() =>
      _CustomLiquidGlassDialogState();
}

class _CustomLiquidGlassDialogState extends State<CustomLiquidGlassDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    await _animationController.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              margin: const EdgeInsets.symmetric(
                horizontal: 0.0,
                vertical: 40.0,
              ),
              padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.85)
                    : const Color(0xffF1F2F4),
                borderRadius: const BorderRadius.all(Radius.circular(34.0)),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 56.0,
                    offset: const Offset(0, 28),
                    spreadRadius: 14,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 110.0,
                    offset: const Offset(0, 60),
                    spreadRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (widget.title != null)
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        26.0,
                        20.0,
                        26.0,
                        12.0,
                      ),
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.08,
                          color: isDarkMode
                              ? Colors.white
                              : CupertinoColors.label,
                        ),
                        child: widget.title!,
                      ),
                    ),
                  if (widget.content != null)
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          26.0,
                          widget.title != null ? 0.0 : 12.0,
                          26.0,
                          0.0,
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontSize: 16.0,
                            fontFamily: 'AppleSDGothicNeo',
                            color: isDarkMode
                                ? Colors.grey[300]
                                : Colors.grey[600],
                            letterSpacing: -0.5,
                            height: 1.4,
                          ),
                          child: widget.content!,
                        ),
                      ),
                    ),
                  if (widget.actions != null && widget.actions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        20.0,
                        16.0,
                        16.0,
                      ),
                      child: widget.actions!.length == 1
                          ? widget.actions!.first
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.actions!.map((action) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: action,
                                );
                              }).toList(),
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
}

class CustomLiquidGlassDialogAction extends StatelessWidget {
  const CustomLiquidGlassDialogAction({
    super.key,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.isConfirmationBlue = false,
    this.onPressed,
    required this.child,
  });

  final bool isDefaultAction;
  final bool isDestructiveAction;
  final bool isConfirmationBlue;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CupertinoThemeData theme = CupertinoTheme.of(context);
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final isDisabled = onPressed == null;

    final Color textColor = isDisabled
        ? (isDarkMode ? Colors.grey[600]! : Colors.grey[400]!)
        : isDestructiveAction
        ? const Color(0xffFF002E)
        : isDefaultAction
        ? theme.primaryColor
        : isDarkMode
        ? Colors.white
        : theme.textTheme.textStyle.color!;

    final Color? backgroundColor = isConfirmationBlue && !isDisabled
        ? const Color(0xFF008AFF)
        : null;

    final double borderWidth = 1.0;
    final Color borderColor = isConfirmationBlue && !isDisabled
        ? const Color(0xFF00FFFF)
        : Colors.transparent;
    final Border border = Border.all(color: borderColor, width: borderWidth);

    final Color containerColor =
        backgroundColor ??
        (isDarkMode ? const Color(0xff282A2B) : const Color(0xffE2E2E6));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(26),
        border: border,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
        onPressed: onPressed,
        child: DefaultTextStyle(
          style: TextStyle(
            color: isConfirmationBlue && !isDisabled
                ? (isDarkMode ? Colors.black : Colors.white)
                : textColor,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'AppleSDGothicNeo',
          ),
          child: child,
        ),
      ),
    );
  }
}
