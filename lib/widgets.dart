import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'design_system.dart';
import 'models.dart';
import 'utils.dart';
import 'liquid_glass_buttons.dart';

Future<void> showCharacterDetails(
  BuildContext context,
  HangulCharacter character,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CharacterDetailSheet(character: character),
  );
}

class HangulTabContent extends StatelessWidget {
  const HangulTabContent({
    super.key,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.practiceIdeas,
    required this.sections,
    this.correctCounts = const {},
  });

  final String heroTitle;
  final String heroSubtitle;
  final List<String> practiceIdeas;
  final List<HangulSection> sections;
  final Map<String, int> correctCounts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _LearningHeroCard(
          title: heroTitle,
          subtitle: heroSubtitle,
          practiceIdeas: practiceIdeas,
        ),
        const SizedBox(height: 24),
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HangulSectionCard(
              section: section,
              onCharacterTap: (character) =>
                  showCharacterDetails(context, character),
              correctCounts: correctCounts,
            ),
          ),
      ],
    );
  }
}

class _LearningHeroCard extends StatelessWidget {
  const _LearningHeroCard({
    required this.title,
    required this.subtitle,
    required this.practiceIdeas,
  });

  final String title;
  final String subtitle;
  final List<String> practiceIdeas;

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          colors: [seedColor.withOpacity(0.95), accentColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.danger.withOpacity(0.3),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: typography.hero.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: typography.body.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 16),
          ...practiceIdeas.map(
            (idea) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      idea,
                      style: typography.body.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HangulSectionCard extends StatelessWidget {
  const HangulSectionCard({
    super.key,
    required this.section,
    required this.onCharacterTap,
    this.correctCounts = const {},
    this.isLocked = false,
    this.isMastered = false,
    this.unlockThreshold = kRowUnlockThreshold,
    this.onLockedTap,
    this.isDense = false,
    this.showHeader = true,
  });

  final HangulSection section;
  final ValueChanged<HangulCharacter> onCharacterTap;
  final Map<String, int> correctCounts;
  final bool isLocked;
  final bool isMastered;
  final int unlockThreshold;
  final VoidCallback? onLockedTap;
  final bool isDense;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final statusLabel = isMastered ? '완료' : '';
    final statusColor = isMastered
        ? palette.success
        : (isLocked ? palette.secondaryText : palette.info);
    // Use tile corner radius for overlay clipping (keep visual rhythm with tiles)

    final double outerVerticalPadding = isDense ? 0.0 : 4.0;
    final double headerToTilesSpacing = isDense ? 0.0 : 8.0;
    final double overlayHorizontalPadding = isDense
        ? 0.0
        : _HangulSectionPadding.defaultHorizontal;
    final double overlayVerticalPadding = isDense
        ? 0.0
        : _HangulSectionPadding.defaultVertical;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: outerVerticalPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: typography.subtitle),
                      if (section.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          section.description,
                          style: typography.caption.copyWith(
                            color: palette.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (statusLabel.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _StatusPill(label: statusLabel, color: statusColor),
                ],
              ],
            ),
          ),
        if (showHeader) SizedBox(height: headerToTilesSpacing),
        Stack(
          children: [
            // Keep paddings in sync with the overlay's positioning below
            _HangulSectionPadding(
              horizontal: overlayHorizontalPadding,
              vertical: overlayVerticalPadding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 4.0;
                  const runSpacing = 6.0;
                  const minTileWidth = 64.0;
                  final availableWidth = constraints.maxWidth;
                  final count = availableWidth <= minTileWidth
                      ? 1
                      : (availableWidth + spacing) ~/ (minTileWidth + spacing);
                  final numPerRow = count < 1 ? 1 : count;
                  final tileWidth =
                      (availableWidth - (numPerRow - 1) * spacing) / numPerRow;
                  // Make tiles square by using equal height and width
                  final tileHeight = tileWidth;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: runSpacing,
                    alignment: WrapAlignment.start,
                    children: [
                      for (final character in section.characters)
                        SizedBox(
                          width: tileWidth,
                          child: _HangulCharacterTile(
                            character: character,
                            onTap: onCharacterTap,
                            correctCount: correctCounts[character.symbol] ?? 0,
                            width: tileWidth,
                            height: tileHeight,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (isLocked)
              // Position the locked overlay so it matches the section padding.
              // This prevents the overlay from touching the screen edges and
              // ensures it doesn't overflow the visible tile area.
              Positioned(
                left: overlayHorizontalPadding,
                right: overlayHorizontalPadding,
                top: overlayVerticalPadding,
                bottom: overlayVerticalPadding,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    _HangulCharacterTile.cornerRadius,
                  ),
                  child: Material(
                    color: palette.elevatedSurface.withOpacity(0.92),
                    child: InkWell(
                      onTap: onLockedTap,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final typography = LearnHangulTheme.typographyOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: typography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HangulCharacterTile extends StatelessWidget {
  const _HangulCharacterTile({
    required this.character,
    required this.onTap,
    required this.correctCount,
    this.width,
    this.height,
  });

  static const double cornerRadius = 8.0;

  final HangulCharacter character;
  final ValueChanged<HangulCharacter> onTap;
  final int correctCount;
  final double? width;
  final double? height;

  /// Calculate button background color based on correct count.
  /// 0 -> current surface color
  /// 7+ -> 100% blue (#2196F3)
  /// 1-6 -> proportional blend between surface and blue
  /// Note: text color threshold is lowered to 5 elsewhere so text becomes
  /// white starting at 5 corrects while background interpolation remains 7-step.
  Color _getBackgroundColor(Color surfaceColor, Color blueColor) {
    if (correctCount == 0) {
      return surfaceColor;
    }

    // Calculate progress: each step from 1-7 is 1/7 (≈14.3%)
    // At 7+, we're at 100%
    final progress = (correctCount / 7).clamp(0.0, 1.0);

    // Interpolate between surface color and blue
    return Color.lerp(surfaceColor, blueColor, progress) ?? surfaceColor;
  }

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);

    final backgroundColor = _getBackgroundColor(
      palette.surface,
      palette.warning,
    );

    // 한글 문자와 로마자 표기는 항상 기본 색상 유지
    // Make text white starting at 5 correct answers (visual tweak).
    final textColor = correctCount >= 5 ? Colors.white : palette.primaryText;
    final captionColor = correctCount >= 5
        ? Colors.white.withOpacity(0.8)
        : palette.mutedText;

    final double tileSize = width ?? height ?? 72.0;
    final double contentFontSize = 18.0;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => onTap(character),
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            _HangulCharacterTile.cornerRadius,
          ),
          border: Border.all(color: palette.outline),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$correctCount',
                  key: Key('correct-${character.symbol}'),
                  style: typography.caption.copyWith(
                    color: captionColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          character.symbol,
                          key: Key('symbol-${character.symbol}'),
                          style: TextStyle(
                            fontSize: contentFontSize * 1.3,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (character.romanization.isNotEmpty)
                          Text(
                            character.romanization,
                            textAlign: TextAlign.center,
                            style: typography.caption.copyWith(
                              color: captionColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The tile corner radius is defined as a static field on the tile class so other
// widgets can match it for visual consistency.

/// Internal helper to keep the same padding values for section rows and their
/// overlay so both the unlocked and locked states visually match.
class _HangulSectionPadding extends StatelessWidget {
  static const double defaultHorizontal = 6.0;
  static const double defaultVertical = 8.0;

  const _HangulSectionPadding({
    Key? key,
    required this.child,
    this.horizontal = defaultHorizontal,
    this.vertical = defaultVertical,
  }) : super(key: key);

  final Widget child;
  final double horizontal;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: child,
    );
  }
}

class CharacterDetailSheet extends StatefulWidget {
  const CharacterDetailSheet({required this.character});

  final HangulCharacter character;

  @override
  State<CharacterDetailSheet> createState() => _CharacterDetailSheetState();
}

class _CharacterDetailSheetState extends State<CharacterDetailSheet> {
  late FlutterTts _flutterTts;

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('ko-KR');
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speakCharacter() async {
    await _flutterTts.speak(widget.character.name);
  }

  Future<void> _speakExampleRaw(String raw) async {
    final trimmed = raw.trim();
    final match = RegExp(r'^[^\s(]+').firstMatch(trimmed);
    final term = match != null ? match.group(0)! : trimmed;
    if (term.isEmpty) return;
    await _flutterTts.speak(term);
  }

  Widget _buildExampleRichFromRaw(BuildContext context, String raw) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final text = raw.trim();

    // Try to split into base + (romanization, meaning)
    final parenStart = text.indexOf('(');
    String base = text;
    String parenContent = '';
    if (parenStart >= 0) {
      base = text.substring(0, parenStart).trim();
      final parenEnd = text.lastIndexOf(')');
      if (parenEnd > parenStart) {
        parenContent = text.substring(parenStart + 1, parenEnd).trim();
      } else {
        parenContent = text.substring(parenStart + 1).trim();
      }
    }

    if (parenContent.isEmpty) {
      return Text(text, style: typography.body);
    }

    // Split paren content by first comma: romanization, meaning
    final parts = parenContent.split(',');
    final romanization = parts.isNotEmpty ? parts[0].trim() : '';
    final meaning = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    final List<TextSpan> spans = [];
    if (base.isNotEmpty) {
      spans.add(
        TextSpan(
          text: base + ' ',
          style: typography.body.copyWith(color: palette.primaryText),
        ),
      );
    }

    // Put romanization outside parentheses, and meaning inside parentheses
    if (romanization.isNotEmpty) {
      spans.add(
        TextSpan(
          text: romanization + ' ',
          style: typography.body.copyWith(color: palette.warning),
        ),
      );
    }

    if (meaning.isNotEmpty) {
      spans.add(
        TextSpan(
          text: '(' + meaning + ')',
          style: typography.body.copyWith(color: palette.primaryText),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textScaleFactor: MediaQuery.textScaleFactorOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.85)
            : const Color(0xffF1F2F4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
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
            offset: const Offset(0, -28),
            spreadRadius: 14,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 32,
              bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: palette.outline),
                      ),
                      child: Center(
                        child: Text(
                          widget.character.symbol,
                          style: typography.hero,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(widget.character.name, style: typography.heading),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.character.romanization,
                          style: typography.body.copyWith(color: palette.info),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: palette.info,
                        ),
                        onPressed: _speakCharacter,
                        tooltip: '발음 듣기',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '예시 단어',
                        style: typography.caption.copyWith(
                          fontSize: 14.0,
                          color: palette.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildExampleRichFromRaw(
                                  context,
                                  widget.character.example,
                                ),
                                if (widget.character.secondExample != null) ...[
                                  const SizedBox(height: 8),
                                  _buildExampleRichFromRaw(
                                    context,
                                    widget.character.secondExample!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.volume_up_rounded,
                                  color: palette.info,
                                ),
                                onPressed: () =>
                                    _speakExampleRaw(widget.character.example),
                                tooltip: '예시 단어 발음 듣기',
                              ),
                              if (widget.character.secondExample != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    color: palette.info,
                                  ),
                                  onPressed: () => _speakExampleRaw(
                                    widget.character.secondExample!,
                                  ),
                                  tooltip: '예시 단어 발음 듣기',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Top-right close button (liquid style)
          Positioned(
            top: 12,
            right: 12,
            child: LiquidGlassButtons.circularIconButton(
              context,
              icon: Icons.close,
              onPressed: () => Navigator.pop(context),
              size: 44.0,
            ),
          ),
        ],
      ),
    );
  }
}
