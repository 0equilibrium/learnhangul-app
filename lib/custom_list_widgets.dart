import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Constants from reference project
const EdgeInsetsDirectional _kInsetGroupedDefaultHeaderMargin =
    EdgeInsetsDirectional.fromSTEB(32.0, 8.0, 32.0, 8.0);
const EdgeInsetsDirectional _kDefaultInsetGroupedRowsMargin =
    EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 10.0);
const EdgeInsetsDirectional _kDefaultInsetGroupedRowsMarginWithHeader =
    EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 10.0);
const BorderRadius _kDefaultInsetGroupedBorderRadius = BorderRadius.all(
  Radius.circular(26.0),
);
const double _kInsetDividerMargin = 16.0;
const double _kInsetAdditionalDividerMargin = 24.0;
const double _kInsetAdditionalDividerMarginWithoutLeading = 16.0;

enum CustomListSectionType { base, insetGrouped }

class CustomListSection extends StatelessWidget {
  const CustomListSection.insetGrouped({
    super.key,
    this.children,
    this.header,
    this.footer,
    EdgeInsetsGeometry? margin,
    this.backgroundColor = CupertinoColors.systemGroupedBackground,
    this.decoration,
    this.clipBehavior = Clip.hardEdge,
    this.dividerMargin = _kInsetDividerMargin,
    double? additionalDividerMargin,
    this.topMargin,
    bool hasLeading = true,
    this.separatorColor,
    this.isOnModal = false,
  }) : assert((children != null && children.length > 0) || header != null),
       type = CustomListSectionType.insetGrouped,
       hasLeading = hasLeading,
       additionalDividerMargin =
           additionalDividerMargin ??
           (hasLeading
               ? _kInsetAdditionalDividerMargin
               : _kInsetAdditionalDividerMarginWithoutLeading),
       margin =
           margin ??
           (header == null
               ? _kDefaultInsetGroupedRowsMargin
               : _kDefaultInsetGroupedRowsMarginWithHeader);

  final CustomListSectionType type;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry margin;
  final List<Widget>? children;
  final BoxDecoration? decoration;
  final Color backgroundColor;
  final Clip clipBehavior;
  final double dividerMargin;
  final double additionalDividerMargin;
  final double? topMargin;
  final Color? separatorColor;
  final bool hasLeading;
  final bool isOnModal;

  @override
  Widget build(BuildContext context) {
    final Color dividerColor =
        separatorColor ?? CupertinoColors.separator.resolveFrom(context);
    final double dividerHeight = 1.0 / MediaQuery.devicePixelRatioOf(context);

    final Widget shortDivider = Container(
      margin: EdgeInsetsDirectional.only(
        start: hasLeading ? 16.0 + 28.0 + 5.0 : 16.0,
      ),
      color: dividerColor,
      height: dividerHeight,
    );

    Widget? headerWidget;
    if (header != null) {
      headerWidget = DefaultTextStyle(
        style: TextStyle(
          fontSize: 17.0,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.8,
          fontFamily: 'AppleSDGothicNeo',
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF8D8D94)
              : const Color(0xFF85858C),
        ),
        child: header!,
      );
    }

    Widget? decoratedChildrenGroup;
    if (children != null && children!.isNotEmpty) {
      final List<Widget> childrenWithDividers = <Widget>[];

      children!.sublist(0, children!.length - 1).forEach((Widget widget) {
        childrenWithDividers.add(widget);
        childrenWithDividers.add(shortDivider);
      });

      childrenWithDividers.add(children!.last);

      decoratedChildrenGroup = DecoratedBox(
        decoration:
            decoration ??
            BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                decoration?.color ??
                    CupertinoColors.secondarySystemGroupedBackground,
                context,
              ),
              borderRadius: _kDefaultInsetGroupedBorderRadius,
            ),
        child: Column(children: childrenWithDividers),
      );

      decoratedChildrenGroup = Padding(
        padding: margin,
        child: clipBehavior == Clip.none
            ? decoratedChildrenGroup
            : ClipRRect(
                borderRadius: _kDefaultInsetGroupedBorderRadius,
                clipBehavior: clipBehavior,
                child: decoratedChildrenGroup,
              ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isOnModal
            ? Colors.transparent
            : CupertinoDynamicColor.resolve(backgroundColor, context),
      ),
      child: Column(
        children: <Widget>[
          if (headerWidget != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: _kInsetGroupedDefaultHeaderMargin,
                child: headerWidget,
              ),
            ),
          if (decoratedChildrenGroup != null) decoratedChildrenGroup,
        ],
      ),
    );
  }
}

// CustomListTile constants
const double _kLeadingSize = 28.0;
const double _kMinHeight = 57.0;
const EdgeInsetsDirectional _kPadding = EdgeInsetsDirectional.only(
  start: 16.0,
  end: 16.0,
  top: 0.0,
  bottom: 0.0,
);
const double _kLeadingToTitle = 8.0;

class CustomListTile extends StatefulWidget {
  const CustomListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.backgroundColorActivated,
    this.padding,
    this.leadingSize = _kLeadingSize,
    this.leadingToTitle = _kLeadingToTitle,
    this.isOnModal = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final FutureOr<void> Function()? onTap;
  final Color? backgroundColor;
  final Color? backgroundColorActivated;
  final EdgeInsetsGeometry? padding;
  final double leadingSize;
  final double leadingToTitle;
  final bool isOnModal;

  @override
  State<CustomListTile> createState() => _CustomListTileState();
}

class _CustomListTileState extends State<CustomListTile> {
  bool _tapped = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = CupertinoTheme.of(context).textTheme.textStyle;

    final Widget title = DefaultTextStyle(
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: widget.title,
    );

    final EdgeInsetsGeometry padding = widget.padding ?? _kPadding;

    Color? backgroundColor = widget.backgroundColor;
    if (widget.isOnModal) {
      backgroundColor = CupertinoColors.secondarySystemGroupedBackground
          .resolveFrom(context);
    } else if (_tapped) {
      backgroundColor =
          widget.backgroundColorActivated ??
          CupertinoColors.systemGrey4.resolveFrom(context);
    }

    final Widget child = Container(
      constraints: const BoxConstraints(
        minWidth: double.infinity,
        minHeight: _kMinHeight,
      ),
      decoration: BoxDecoration(color: backgroundColor),
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            if (widget.leading case final Widget leading) ...<Widget>[
              leading,
              SizedBox(width: widget.leadingToTitle),
            ] else
              SizedBox(height: widget.leadingSize),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  title,
                  if (widget.subtitle case final Widget subtitle)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: DefaultTextStyle(
                        style: textStyle.copyWith(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        child: subtitle,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );

    if (widget.onTap == null) {
      return child;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() {
        _tapped = true;
      }),
      onTapCancel: () => setState(() {
        _tapped = false;
      }),
      onTap: () async {
        await widget.onTap!();
        if (mounted) {
          setState(() {
            _tapped = false;
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
