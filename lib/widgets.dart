import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';
import 'premium_voice_dialog.dart';

import 'design_system.dart';
import 'package:learnhangul/l10n/app_localizations.dart';
import 'models.dart';
import 'utils.dart';
import 'liquid_glass_buttons.dart';

Future<void> showCharacterDetails(
  BuildContext context,
  HangulCharacter character,
) async {
  // Fetch device screen corner radii and print for debugging each time
  final ScreenRadius? screenRadius = await ScreenCornerRadius.get();
  if (!context.mounted) return;
  // Print so developers can see the detected radii when a tile is tapped.
  // Print field values explicitly so logs are readable instead of "Instance of 'ScreenRadius'".
  if (screenRadius == null) {
    debugPrint('ScreenCornerRadius: null');
  } else {
    debugPrint(
      'ScreenCornerRadius: topLeft=${screenRadius.topLeft}, topRight=${screenRadius.topRight}, bottomLeft=${screenRadius.bottomLeft}, bottomRight=${screenRadius.bottomRight}',
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        CharacterDetailSheet(character: character, screenRadius: screenRadius),
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
          colors: [seedColor.withValues(alpha: 0.95), accentColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.danger.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.85),
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
                    color: palette.elevatedSurface.withValues(alpha: 0.92),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
  /// 4+ -> 100% of the max color
  /// 1-3 -> proportional blend between surface and the max color
  /// Note: text color becomes light (white) starting at 4 corrects.
  Color _getBackgroundColor(Color surfaceColor, Color blueColor) {
    if (correctCount == 0) return surfaceColor;

    // For counts 1..3 interpolate proportionally; 4 or more -> full color.
    final progress = (correctCount.clamp(0, 4) / 4).clamp(0.0, 1.0);
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
    // Make text light (white) starting at 4 correct answers (visual tweak).
    final bool isMaxStage = correctCount >= 4;
    final textColor = isMaxStage ? Colors.white : palette.primaryText;
    final captionColor = isMaxStage
        ? Colors.white.withValues(alpha: 0.8)
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
    required this.child,
    this.horizontal = defaultHorizontal,
    this.vertical = defaultVertical,
  });

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
  const CharacterDetailSheet({
    super.key,
    required this.character,
    this.screenRadius,
  });

  final HangulCharacter character;
  final ScreenRadius? screenRadius;

  @override
  State<CharacterDetailSheet> createState() => _CharacterDetailSheetState();
}

class _CharacterDetailSheetState extends State<CharacterDetailSheet> {
  late FlutterTts _flutterTts;

  // Hangul composition tables for building consonant+'ㅡ' syllables
  static const List<String> _initials = [
    'ㄱ',
    'ㄲ',
    'ㄴ',
    'ㄷ',
    'ㄸ',
    'ㄹ',
    'ㅁ',
    'ㅂ',
    'ㅃ',
    'ㅅ',
    'ㅆ',
    'ㅇ',
    'ㅈ',
    'ㅉ',
    'ㅊ',
    'ㅋ',
    'ㅌ',
    'ㅍ',
    'ㅎ',
  ];

  static const List<String> _medials = [
    'ㅏ',
    'ㅐ',
    'ㅑ',
    'ㅒ',
    'ㅓ',
    'ㅔ',
    'ㅕ',
    'ㅖ',
    'ㅗ',
    'ㅘ',
    'ㅙ',
    'ㅚ',
    'ㅛ',
    'ㅜ',
    'ㅝ',
    'ㅞ',
    'ㅟ',
    'ㅠ',
    'ㅡ',
    'ㅢ',
    'ㅣ',
  ];

  // composite final symbols where we don't show the pronunciation button
  static const List<String> _compositeFinals = [
    'ㄳ',
    'ㄵ',
    'ㄶ',
    'ㄺ',
    'ㄻ',
    'ㄼ',
    'ㄽ',
    'ㄾ',
    'ㄿ',
    'ㅀ',
    'ㅄ',
  ];

  String _composeSyllable(String initial, String medial) {
    final L = _initials.indexOf(initial);
    final V = _medials.indexOf(medial);
    if (L < 0 || V < 0) return initial + medial;
    final sIndex = 0xAC00 + (L * 21 + V) * 28; // TIndex = 0
    return String.fromCharCode(sIndex);
  }

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _configureTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _configureTts() async {
    try {
      await _flutterTts.setLanguage('ko-KR');
    } catch (_) {}
  }

  Future<void> _speakCharacter() async {
    try {
      final ok = await showPremiumVoiceCheckDialog(context);
      if (!ok) return;

      if (widget.character.type == HangulCharacterType.vowel) {
        // vowels: speak the vowel syllable/name (e.g. '아', '외')
        await _flutterTts.speak(widget.character.name);
      } else {
        // consonants: skip composite finals
        final sym = widget.character.symbol;
        if (_compositeFinals.contains(sym)) return;
        // compose consonant + 'ㅡ' syllable (e.g. ㅅ -> 스)
        final syllable = _composeSyllable(sym, 'ㅡ');
        await _flutterTts.speak(syllable);
      }
    } catch (_) {}
  }

  Future<void> _speakExampleRaw(String raw) async {
    final trimmed = raw.trim();
    final match = RegExp(r'^[^\s(]+').firstMatch(trimmed);
    final term = match != null ? match.group(0)! : trimmed;
    if (term.isEmpty) return;
    try {
      final ok = await showPremiumVoiceCheckDialog(context);
      if (!ok) return;
      await _flutterTts.speak(term);
    } catch (_) {}
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
          text: '$base ',
          style: typography.body.copyWith(color: palette.primaryText),
        ),
      );
    }

    // Put romanization outside parentheses, and meaning inside parentheses
    if (romanization.isNotEmpty) {
      spans.add(
        TextSpan(
          text: '$romanization ',
          style: typography.body.copyWith(color: palette.warning),
        ),
      );
    }

    if (meaning.isNotEmpty) {
      spans.add(
        TextSpan(
          text: '($meaning)',
          style: typography.body.copyWith(color: palette.primaryText),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      textScaler: MediaQuery.textScalerOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 100, bottom: 5, right: 5, left: 5),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withValues(alpha: 0.85)
            : const Color(0xffF1F2F4),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(34),
          topRight: const Radius.circular(34),
          bottomLeft: Radius.circular((widget.screenRadius?.bottomLeft ?? 0.0)),
          bottomRight: Radius.circular(
            (widget.screenRadius?.bottomRight ?? 0.0),
          ),
        ),
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
                  const SizedBox(height: 12),

                  // Top-centered liquid speaker button (between the symbol box and title)
                  if (!(widget.character.type ==
                          HangulCharacterType.consonant &&
                      _compositeFinals.contains(widget.character.symbol)))
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: LiquidGlassButtons.circularIconButton(
                          context,
                          icon: CupertinoIcons.speaker_2,
                          size: 52.0,
                          onPressed: _speakCharacter,
                        ),
                      ),
                    ),

                  // Name
                  Text(
                    AppLocalizations.of(context)!.nameLabel,
                    style: typography.caption.copyWith(
                      fontSize: 13.0,
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: palette.outline),
                    ),
                    child: Text(
                      widget.character.name,
                      style: typography.body.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: palette.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Romanization
                  Text(
                    AppLocalizations.of(context)!.romanizationLabel,
                    style: typography.caption.copyWith(
                      fontSize: 13.0,
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: palette.outline),
                    ),
                    child: Text(
                      widget.character.romanization,
                      style: typography.body.copyWith(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: palette.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Example words (title outside, contents inside rounded box). Each example
                  // is a row with the text and a rounded cupertino speaker button.
                  Text(
                    AppLocalizations.of(context)!.exampleWord,
                    style: typography.caption.copyWith(
                      fontSize: 13.0,
                      color: palette.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: palette.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // primary example row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _buildExampleRichFromRaw(
                                context,
                                widget.character.example,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () =>
                                  _speakExampleRaw(widget.character.example),
                              child: Icon(
                                CupertinoIcons.speaker_2,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        if (widget.character.secondExample != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildExampleRichFromRaw(
                                  context,
                                  widget.character.secondExample!,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _speakExampleRaw(
                                  widget.character.secondExample!,
                                ),
                                child: Icon(
                                  CupertinoIcons.speaker_2,
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
