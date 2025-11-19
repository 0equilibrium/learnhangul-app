import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'custom_list_widgets.dart';
import 'custom_liquid_glass_dialog.dart';
import 'design_system.dart';
import 'liquid_glass_buttons.dart';
import 'models.dart';
import 'widgets.dart';
import 'utils.dart';

const _learnedWordsPrefsKey = 'learned_words_v1';

enum ConsonantQuestionCategory { single, openSyllable, batchimWord }

class LearnedWordEntry {
  const LearnedWordEntry({
    required this.term,
    required this.romanization,
    this.meaning,
    required this.seenAt,
    required this.timesSeen,
  });

  final String term;
  final String romanization;
  final String? meaning;
  final DateTime seenAt;
  final int timesSeen;

  factory LearnedWordEntry.fromJson(Map<String, dynamic> json) {
    return LearnedWordEntry(
      term: json['term'] as String,
      romanization: json['romanization'] as String,
      meaning: json['meaning'] as String?,
      seenAt: DateTime.parse(json['seenAt'] as String),
      timesSeen: json['timesSeen'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'term': term,
    'romanization': romanization,
    'meaning': meaning,
    'seenAt': seenAt.toIso8601String(),
    'timesSeen': timesSeen,
  };

  LearnedWordEntry copyWith({DateTime? seenAt, int? timesSeen}) {
    return LearnedWordEntry(
      term: term,
      romanization: romanization,
      meaning: meaning,
      seenAt: seenAt ?? this.seenAt,
      timesSeen: timesSeen ?? this.timesSeen,
    );
  }
}

const Map<String, String> _consonantSoundOverrides = {
  'ㄱ': '그',
  'ㄲ': '끄',
  'ㅋ': '크',
  'ㄴ': '느',
  'ㄷ': '드',
  'ㄸ': '뜨',
  'ㅌ': '트',
  'ㄹ': '르',
  'ㅁ': '므',
  'ㅂ': '브',
  'ㅃ': '쁘',
  'ㅍ': '프',
  'ㅅ': '스',
  'ㅆ': '쓰',
  'ㅎ': '흐',
  'ㅇ': '으',
  'ㅈ': '즈',
  'ㅉ': '쯔',
  'ㅊ': '츠',
};

class VowelLearningScreen extends StatefulWidget {
  const VowelLearningScreen({super.key});

  @override
  State<VowelLearningScreen> createState() => _VowelLearningScreenState();
}

class _VowelLearningScreenState extends State<VowelLearningScreen> {
  Map<String, int> _correctCounts = const {};
  List<SectionUnlockStatus> _sectionStatuses = const [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final allVowels = vowelSections
        .expand((section) => section.characters)
        .toList();
    final counts = {
      for (var v in allVowels)
        v.symbol: prefs.getInt('correct_${v.symbol}') ?? 0,
    };
    final summary = evaluateSectionUnlocks(
      sections: vowelSections,
      correctCounts: counts,
    );
    if (!mounted) return;
    setState(() {
      _correctCounts = counts;
      _sectionStatuses = summary.statuses;
    });
  }

  void _showVowelLockedRowDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('새로운 행 해제'),
          content: Text(
            '앞선 행의 모든 모음을 각각 $kRowUnlockThreshold회 이상 맞히면 다음 행이 열립니다.',
          ),
          actions: [
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LearnHangulAppBar('모음'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (final entry in vowelSections.asMap().entries)
                    Padding(
                      // Add vertical spacing between section rows for better readability.
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HangulSectionCard(
                        section: entry.value,
                        onCharacterTap: (character) =>
                            showCharacterDetails(context, character),
                        correctCounts: _correctCounts,
                        isLocked: entry.key < _sectionStatuses.length
                            ? !_sectionStatuses[entry.key].isUnlocked
                            : entry.key > 0,
                        isMastered: entry.key < _sectionStatuses.length
                            ? _sectionStatuses[entry.key].isMastered
                            : false,
                        unlockThreshold: kRowUnlockThreshold,
                        onLockedTap: _showVowelLockedRowDialog,
                        isDense: true,
                        showHeader: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            // Add horizontal margin so the button doesn't stretch edge-to-edge.
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: LiquidGlassButton(
              label: '훈련하기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TrainingScreen(sections: vowelSections),
                  ),
                ).then((_) => _loadCounts());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConsonantLearningScreen extends StatefulWidget {
  const ConsonantLearningScreen({super.key});

  @override
  State<ConsonantLearningScreen> createState() =>
      _ConsonantLearningScreenState();
}

class _ConsonantLearningScreenState extends State<ConsonantLearningScreen> {
  Map<String, int> _correctCounts = const {};
  List<SectionUnlockStatus> _sectionStatuses = const [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final allConsonants = consonantSections
        .expand((section) => section.characters)
        .toList();
    final counts = {
      for (var c in allConsonants)
        c.symbol: prefs.getInt('correct_${c.symbol}') ?? 0,
    };
    final summary = evaluateSectionUnlocks(
      sections: consonantSections,
      correctCounts: counts,
    );
    if (!mounted) return;
    setState(() {
      _correctCounts = counts;
      _sectionStatuses = summary.statuses;
    });
  }

  void _showConsonantLockedRowDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('새로운 행 해제'),
          content: Text(
            '앞선 자음 행의 모든 글자를 $kRowUnlockThreshold회 이상 맞히면 다음 행이 열립니다.',
          ),
          actions: [
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LearnHangulAppBar(
        '자음 학습',
        trailing: LiquidGlassButtons.circularIconButton(
          context,
          icon: Icons.menu_book_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LearnedWordsScreen(),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (final entry in consonantSections.asMap().entries)
                    Padding(
                      // Add vertical spacing between section rows for better readability.
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HangulSectionCard(
                        section: entry.value,
                        onCharacterTap: (character) =>
                            showCharacterDetails(context, character),
                        correctCounts: _correctCounts,
                        isLocked: entry.key < _sectionStatuses.length
                            ? !_sectionStatuses[entry.key].isUnlocked
                            : entry.key > 0,
                        isMastered: entry.key < _sectionStatuses.length
                            ? _sectionStatuses[entry.key].isMastered
                            : false,
                        unlockThreshold: kRowUnlockThreshold,
                        onLockedTap: _showConsonantLockedRowDialog,
                        isDense: true,
                        showHeader: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            // Add horizontal margin so the button doesn't stretch edge-to-edge.
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: LiquidGlassButton(
              label: '훈련하기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TrainingScreen(sections: consonantSections),
                  ),
                ).then((_) => _loadCounts());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminderEnabled = true;
  bool _ttsHintsEnabled = true;

  void _toggleReminder(bool value) {
    setState(() => _reminderEnabled = value);
    LearnHangulSnackbar.show(
      context,
      message: value ? '매일 저녁 알림을 켰어요.' : '알림을 잠시 쉬고 있어요.',
      tone: value ? LearnHangulSnackTone.success : LearnHangulSnackTone.warning,
    );
  }

  void _toggleTts(bool value) {
    setState(() => _ttsHintsEnabled = value);
  }

  void _confirmReset() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('학습 데이터 초기화'),
          content: const Text('맞힌 기록과 음절 진행도가 모두 삭제됩니다. 계속할까요?'),
          actions: [
            CustomLiquidGlassDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            CustomLiquidGlassDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                LearnHangulSnackbar.show(
                  context,
                  message: '데이터를 초기화했어요.',
                  tone: LearnHangulSnackTone.danger,
                );
              },
              child: const Text('초기화'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final sectionBg = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGroupedBackground,
      context,
    );

    return Scaffold(
      appBar: LearnHangulAppBar('설정', backgroundColor: sectionBg),
      backgroundColor: sectionBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: const Text('학습'),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '저녁 리마인더',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: const Text('매일 19시에 학습 알림 받기'),
                  leading: const Icon(Icons.alarm_rounded),
                  trailing: Switch.adaptive(
                    value: _reminderEnabled,
                    onChanged: _toggleReminder,
                  ),
                  onTap: () => _toggleReminder(!_reminderEnabled),
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    'TTS 힌트',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: const Text('문제를 풀 때 자동으로 음성 힌트 듣기'),
                  leading: const Icon(Icons.hearing_rounded),
                  trailing: Switch.adaptive(
                    value: _ttsHintsEnabled,
                    onChanged: _toggleTts,
                  ),
                  onTap: () => _toggleTts(!_ttsHintsEnabled),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: const Text('지원'),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '이용약관',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  leading: const Icon(CupertinoIcons.doc_text),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () async {
                    final url = Uri.parse('https://www.naver.com');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      LearnHangulSnackbar.show(
                        context,
                        message: '링크를 열 수 없습니다.',
                        tone: LearnHangulSnackTone.danger,
                      );
                    }
                  },
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '도움말 센터',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  leading: const Icon(CupertinoIcons.question_circle),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () async {
                    final url = Uri.parse('https://www.naver.com');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      LearnHangulSnackbar.show(
                        context,
                        message: '링크를 열 수 없습니다.',
                        tone: LearnHangulSnackTone.danger,
                      );
                    }
                  },
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '문의하기',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  leading: const Icon(CupertinoIcons.mail),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () async {
                    final emailUri = Uri(
                      scheme: 'mailto',
                      path: 'yujunhyung@gmail.com',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      LearnHangulSnackbar.show(
                        context,
                        message: '메일 앱을 열 수 없습니다.',
                        tone: LearnHangulSnackTone.danger,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: const Text('계정'),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '진행 데이터 초기화',
                    style: TextStyle(
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                  subtitle: const Text('맞힌 수와 섹션 잠금 해제를 모두 삭제합니다'),
                  leading: Icon(
                    Icons.delete_sweep_rounded,
                    color: isDarkMode ? Colors.red[300] : Colors.red,
                  ),
                  onTap: _confirmReset,
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class LearnedWordsScreen extends StatefulWidget {
  const LearnedWordsScreen({super.key});

  @override
  State<LearnedWordsScreen> createState() => _LearnedWordsScreenState();
}

class _LearnedWordsScreenState extends State<LearnedWordsScreen> {
  List<LearnedWordEntry> _words = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_learnedWordsPrefsKey);
      final entries = raw == null
          ? <LearnedWordEntry>[]
          : (jsonDecode(raw) as List<dynamic>)
                .map(
                  (item) => LearnedWordEntry.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      entries.sort((a, b) => b.seenAt.compareTo(a.seenAt));
      if (!mounted) return;
      setState(() {
        _words = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _words = const [];
        _isLoading = false;
      });
    }
  }

  String _formatRelative(DateTime seenAt) {
    final now = DateTime.now();
    final diff = now.difference(seenAt);
    if (diff.inDays >= 1) {
      final local = seenAt.toLocal();
      final month = local.month.toString().padLeft(2, '0');
      final day = local.day.toString().padLeft(2, '0');
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$month/$day $hour:$minute';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}시간 전';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}분 전';
    }
    return '방금 전';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: LearnHangulAppBar('내가 학습한 단어'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final typography = LearnHangulTheme.typographyOf(context);
    final palette = LearnHangulTheme.paletteOf(context);

    Widget body;
    if (_words.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: palette.secondaryText,
              ),
              const SizedBox(height: 12),
              Text('아직 정리된 단어가 없어요.', style: typography.heading),
              const SizedBox(height: 8),
              Text(
                '훈련하기에서 새로운 단어를 만나면 여기에 차곡차곡 쌓여요.',
                textAlign: TextAlign.center,
                style: typography.body.copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadWords,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final word = _words[index];
            return LearnHangulSurface(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.term,
                    style: typography.hero.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(word.romanization, style: typography.caption),
                      if (word.meaning != null) ...[
                        const SizedBox(width: 12),
                        Text('·', style: typography.caption),
                        const SizedBox(width: 12),
                        Text(word.meaning!, style: typography.caption),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: palette.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatRelative(word.seenAt),
                        style: typography.body.copyWith(
                          color: palette.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '학습 ${word.timesSeen}회',
                        style: typography.body.copyWith(
                          color: palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: _words.length,
        ),
      );
    }

    return Scaffold(appBar: const LearnHangulAppBar('내가 학습한 단어'), body: body);
  }
}

enum GivenType { hangul, sound, romanization }

enum ChooseType { romanization, sound, hangul }

class TrainingMode {
  final GivenType given;
  final ChooseType choose;
  const TrainingMode(this.given, this.choose);
}

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key, required this.sections});

  final List<HangulSection> sections;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  static const List<List<String>> _ttsConfusableGroups = [
    ['ㅐ', 'ㅔ'],
    ['ㅒ', 'ㅖ'],
    ['ㅚ', 'ㅙ', 'ㅞ'],
  ];

  late List<HangulCharacter> _characters;
  late Map<String, int> _correctCounts;
  late Map<String, int> _sessionCorrectCounts;
  int _totalCorrect = 0;
  int _globalWrongCount = 0;
  TrainingMode? _currentMode;
  HangulCharacter? _currentQuestion;
  List<String> _options = [];
  String? _selectedOption;
  bool _showResult = false;
  bool _isCorrect = false;
  // Session state: keep track of (character, mode) pairs answered correctly
  final Set<String> _sessionCorrectPairs = <String>{};
  // Avoid consecutive same mode or same character
  TrainingMode? _lastMode;
  String? _lastCharacterSymbol;
  final Random _rand = Random();
  SectionUnlockSummary? _sectionSummary;
  Set<ConsonantQuestionCategory> _allowedConsonantCategories = const {
    ConsonantQuestionCategory.single,
  };
  final List<_RetryQuestion> _retryQueue = <_RetryQuestion>[];
  static const int _sessionGoal = 10;
  static const int _minRetryGap = 3;
  int _questionsServed = 0;

  bool get _isVowelTraining => identical(widget.sections, vowelSections);

  bool get _isConsonantTraining =>
      identical(widget.sections, consonantSections) ||
      (widget.sections.isNotEmpty &&
          widget.sections.first.characters.isNotEmpty &&
          widget.sections.first.characters.first.type ==
              HangulCharacterType.consonant);

  // When generating vowel-sequence questions we synthesize a HangulCharacter
  // where `symbol` is the displayed Hangul (e.g. '아오') and `romanization`
  // is the joined romanizations (e.g. 'a-o' or 'ai'). This lets the
  // rest of the logic treat sequences like ordinary characters.
  HangulCharacter _synthesizeSequence(List<HangulCharacter> parts) {
    final display = parts.map((p) => p.name).join();
    // Join romanizations with '/' so multi-part sequences are unambiguous
    // (e.g. 'o/eo/u/i'). For single-part sequences this will just be the
    // single romanization.
    final roman = parts.map((p) => p.romanization).join('/');
    return HangulCharacter(
      symbol: display,
      name: display,
      romanization: roman,
      example: '',
      type: HangulCharacterType.vowel,
    );
  }

  bool _hasVariedParts(List<HangulCharacter> parts) {
    if (parts.length < 2) return false;
    final first = parts.first.name;
    return parts.any((p) => p.name != first);
  }

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('ko-KR');
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final baseCharacters = widget.sections
        .expand((section) => section.characters)
        .toList();
    final extraCharacters = _isConsonantTraining
        ? consonantTrainingWordPool
        : const <HangulCharacter>[];
    final allCharacters = [...baseCharacters, ...extraCharacters];
    final counts = <String, int>{};
    for (var c in allCharacters) {
      counts[c.symbol] = prefs.getInt('correct_${c.symbol}') ?? 0;
    }

    final summary = evaluateSectionUnlocks(
      sections: widget.sections,
      correctCounts: counts,
    );

    final activeSections = summary.trainableSections;
    _characters = activeSections
        .expand((section) => section.characters)
        .toList();

    if (_isConsonantTraining) {
      _characters = [..._characters, ...consonantTrainingWordPool];
    }

    _retryQueue.clear();

    setState(() {
      _correctCounts = counts;
      _sectionSummary = summary;
      _sessionCorrectCounts = {};
      _globalWrongCount = prefs.getInt('global_wrong_count') ?? 0;
      _allowedConsonantCategories = _isConsonantTraining
          ? _buildAllowedConsonantCategories(summary)
          : const {ConsonantQuestionCategory.single};
      _questionsServed = 0;
    });
    _startNewQuestion();
  }

  Future<void> _updateCountsAndSave() async {
    for (var entry in _sessionCorrectCounts.entries) {
      _correctCounts[entry.key] =
          (_correctCounts[entry.key] ?? 0) + entry.value;
    }
    await _saveCounts();
  }

  Future<void> _saveCounts() async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in _correctCounts.entries) {
      await prefs.setInt('correct_${entry.key}', entry.value);
    }
    await prefs.setInt('global_wrong_count', _globalWrongCount);
  }

  List<TrainingMode> get _trainingModes => const [
    TrainingMode(GivenType.hangul, ChooseType.romanization),
    TrainingMode(GivenType.hangul, ChooseType.sound),
    TrainingMode(GivenType.sound, ChooseType.hangul),
    TrainingMode(GivenType.romanization, ChooseType.hangul),
  ];

  void _startNewQuestion() {
    final modes = _trainingModes;
    MapEntry<HangulCharacter, TrainingMode>? choice;
    final dueRetry = _pullRetryQuestion();
    if (dueRetry != null) {
      choice = MapEntry(dueRetry.character, dueRetry.mode);
    }

    if (choice == null) {
      // 1. Identify the "newly unlocked" section (Target Section).
      // This is the last unlocked section in the list.
      final summary = _sectionSummary;
      int targetSectionIndex = -1;
      if (summary != null) {
        for (int i = 0; i < summary.statuses.length; i++) {
          if (summary.statuses[i].isUnlocked) {
            targetSectionIndex = i;
          }
        }
      }

      List<HangulCharacter> targetPool = [];
      List<HangulCharacter> reviewPool = [];

      // Split characters into Target Pool (New Row) and Review Pool (Old Rows)
      if (targetSectionIndex != -1) {
        final targetSection = widget.sections[targetSectionIndex];
        final targetSymbols = targetSection.characters
            .map((c) => c.symbol)
            .toSet();

        for (final c in _characters) {
          if (targetSymbols.contains(c.symbol)) {
            targetPool.add(c);
          } else {
            reviewPool.add(c);
          }
        }
      } else {
        reviewPool = List.from(_characters);
      }

      // If vowel training, add synthesized sequences to the review pool
      if (_isVowelTraining) {
        final sequences = _buildVowelSequencePool();
        reviewPool.addAll(sequences);
      }

      // 2. Weighted Selection: 70% New Row, 30% Review
      bool useTargetPool = false;
      if (targetPool.isNotEmpty && reviewPool.isNotEmpty) {
        // 70% chance for target pool
        useTargetPool = _rand.nextDouble() < 0.7;
      } else if (targetPool.isNotEmpty) {
        useTargetPool = true;
      } else {
        useTargetPool = false;
      }

      final sourcePool = useTargetPool ? targetPool : reviewPool;
      final candidates = <MapEntry<HangulCharacter, TrainingMode>>[];

      for (final c in sourcePool) {
        if (_isConsonantTraining &&
            !_allowedConsonantCategories.contains(_categoryOf(c))) {
          continue;
        }

        // For the new row (target pool), prioritize easier modes.
        // We exclude 'Sound -> Hangul' (GivenType.sound) to make it easier initially.
        final allowedModes = (useTargetPool)
            ? modes.where((m) => m.given != GivenType.sound).toList()
            : modes;

        for (final m in allowedModes) {
          final key = '${c.symbol}|${m.given.index}-${m.choose.index}';
          if (_sessionCorrectPairs.contains(key)) {
            continue;
          }
          if (_lastCharacterSymbol != null &&
              c.symbol == _lastCharacterSymbol) {
            continue;
          }
          if (_lastMode != null &&
              m.given == _lastMode!.given &&
              m.choose == _lastMode!.choose) {
            continue;
          }
          candidates.add(MapEntry(c, m));
        }
      }

      // Fallback: Relax constraints if no candidates found
      if (candidates.isEmpty) {
        // Try again without "last character/mode" constraints
        for (final c in sourcePool) {
          if (_isConsonantTraining &&
              !_allowedConsonantCategories.contains(_categoryOf(c))) {
            continue;
          }
          // Still keep the "easy mode" constraint for target pool if possible,
          // but if that fails, we might need to open up.
          // For now, let's keep it simple and just re-add without last-check.
          final allowedModes = (useTargetPool)
              ? modes.where((m) => m.given != GivenType.sound).toList()
              : modes;

          for (final m in allowedModes) {
            final key = '${c.symbol}|${m.given.index}-${m.choose.index}';
            if (_sessionCorrectPairs.contains(key)) {
              continue;
            }
            candidates.add(MapEntry(c, m));
          }
        }
      }

      // If no candidates remain under the strict rules, try to synthesize
      // extra consonant-focused items by combining a known initial
      // consonant with mastered vowels. This keeps the "allowed
      // category" constraint (we only consider consonants already in
      // `sourcePool`), and only creates combinations for consonants the
      // learner has answered at least 3 times to avoid exposing unseen
      // consonants. Do NOT relax `_allowedConsonantCategories` here.
      if (candidates.isEmpty && _isConsonantTraining) {
        // Check that vowels are mastered enough to safely combine.
        final vowelSummary = evaluateSectionUnlocks(
          sections: vowelSections,
          correctCounts: _correctCounts,
        );
        if (vowelSummary.allMastered) {
          final vowels = vowelSections
              .expand((s) => s.characters)
              .where((c) => c.type == HangulCharacterType.vowel)
              .toList();

          for (final c in sourcePool) {
            // Only augment for base single-letter consonants (jamo)
            // and only if the user has at least 3 corrects for it.
            final baseCount = _correctCounts[c.symbol] ?? 0;
            if (!_isHangulJamo(c.symbol) || baseCount < 3) continue;

            for (final v in vowels) {
              final composed = _composeSyllable(c.symbol, v.symbol);
              if (composed.isEmpty) continue;
              final synth = HangulCharacter(
                symbol: composed,
                name: composed,
                romanization: '${c.romanization}-${v.romanization}',
                example: '',
                type: HangulCharacterType.consonant,
              );
              for (final m in modes) {
                final key =
                    '${synth.symbol}|${m.given.index}-${m.choose.index}';
                if (_sessionCorrectPairs.contains(key)) continue;
                candidates.add(MapEntry(synth, m));
              }
            }
          }
        }
      }

      // If still empty and we were using target pool, try review pool instead
      if (candidates.isEmpty && useTargetPool && reviewPool.isNotEmpty) {
        for (final c in reviewPool) {
          if (_isConsonantTraining &&
              !_allowedConsonantCategories.contains(_categoryOf(c))) {
            continue;
          }
          for (final m in modes) {
            final key = '${c.symbol}|${m.given.index}-${m.choose.index}';
            if (_sessionCorrectPairs.contains(key)) {
              continue;
            }
            candidates.add(MapEntry(c, m));
          }
        }
      }

      // As a final consonant-only fallback, if candidates remain empty,
      // allow reusing previously-correct session pairs (i.e. ignore
      // `_sessionCorrectPairs`) but still respect `_allowedConsonantCategories`.
      // This avoids relaxing the allowed-category constraint while preventing
      // the session from ending prematurely due to complete exhaustion.
      if (candidates.isEmpty && _isConsonantTraining) {
        for (final c in sourcePool) {
          if (!_allowedConsonantCategories.contains(_categoryOf(c))) continue;
          for (final m in modes) {
            // Intentionally do NOT check `_sessionCorrectPairs` here — we
            // allow repeats when nothing else is available.
            candidates.add(MapEntry(c, m));
          }
        }
        if (candidates.isEmpty && reviewPool.isNotEmpty) {
          for (final c in reviewPool) {
            if (!_allowedConsonantCategories.contains(_categoryOf(c))) continue;
            for (final m in modes) {
              candidates.add(MapEntry(c, m));
            }
          }
        }
      }

      if (candidates.isEmpty) {
        final forcedRetry = _pullRetryQuestion(force: true);
        if (forcedRetry == null) {
          _showCompletionDialog();
          return;
        }
        choice = MapEntry(forcedRetry.character, forcedRetry.mode);
      } else {
        // Apply consonant prioritization if applicable
        final filteredCandidates = _isConsonantTraining
            ? _prioritizeConsonantCandidates(candidates)
            : candidates;

        // 3. Smart Algorithm: Inverse Frequency Weighting
        // Calculate weights for each candidate
        final weightedCandidates =
            <MapEntry<HangulCharacter, TrainingMode>, double>{};
        double totalWeight = 0.0;

        for (final cand in filteredCandidates) {
          final char = cand.key;
          // Use the base symbol count. For sequences, we might not have a direct count,
          // but we can use 0 or average of parts.
          // _correctCounts stores counts by symbol.
          final count = _correctCounts[char.symbol] ?? 0;

          // Weight = 1 / (count + 1).
          // Add a small epsilon or just +1 to avoid division by zero.
          // We can also square it to make it more aggressive: 1 / (count + 1)^2
          final weight = 1.0 / (count + 1);

          weightedCandidates[cand] = weight;
          totalWeight += weight;
        }

        // Weighted random selection
        final r = _rand.nextDouble() * totalWeight;
        double currentSum = 0.0;
        MapEntry<HangulCharacter, TrainingMode>? selected;

        for (final entry in weightedCandidates.entries) {
          currentSum += entry.value;
          if (r <= currentSum) {
            selected = entry.key;
            break;
          }
        }
        // Fallback (rounding errors)
        selected ??= filteredCandidates.last;

        choice = selected;
      }
    }
    _currentQuestion = choice.key;
    _currentMode = choice.value;
    _questionsServed++;

    // Save last chosen for consecutive-avoidance
    _lastMode = _currentMode;
    _lastCharacterSymbol = _currentQuestion!.symbol;

    // Generate options
    _options = _generateOptions();

    _selectedOption = null;
    _showResult = false;

    // Auto-play TTS when the given is sound
    if (_currentMode?.given == GivenType.sound) {
      // Auto-play but do not block UI
      unawaited(_playSound(_currentQuestion!.symbol));
    }
  }

  String _getNameFromSymbol(String symbol) {
    final idx = _characters.indexWhere((c) => c.symbol == symbol);
    if (idx != -1) {
      return _pronunciationFor(_characters[idx]);
    }
    // If not found (e.g. synthesized sequence), return the symbol itself
    return symbol;
  }

  String _pronunciationFor(HangulCharacter char) {
    if (char.type == HangulCharacterType.consonant &&
        _isHangulJamo(char.symbol)) {
      final override = _consonantSoundOverrides[char.symbol];
      if (override != null) return override;
    }
    return char.name;
  }

  List<HangulCharacter> _buildVowelSequencePool() {
    final summary = _sectionSummary;
    if (summary == null) return const [];
    final masteredSections = summary.statuses
        .where((status) => status.isMastered)
        .toList();
    if (masteredSections.isEmpty) return const [];

    final vowels = masteredSections
        .expand((status) => status.section.characters)
        .where((char) => char.type == HangulCharacterType.vowel)
        .toList();
    if (vowels.length < 2) return const [];

    // Build a pool of synthesized vowel sequences (length 2..4). We try to
    // prefer plausible/word-like small sequences and also include random
    // combinations so the user sees a variety. Names already include the
    // leading ㅇ (e.g. '아').
    final byName = {for (var v in vowels) v.name: v};

    final preferred = <List<HangulCharacter>>[];
    // common interjections / sequences to bias towards (if parts exist)
    final commonNames = [
      ['우', '와'],
      ['이', '야'],
      ['아', '이'],
      ['오', '우'],
      ['이', '에'],
      ['우', '아'],
    ];
    for (final combo in commonNames) {
      final parts = combo
          .map((n) => byName[n])
          .whereType<HangulCharacter>()
          .toList();
      if (parts.length == combo.length) preferred.add(parts);
    }

    // Randomly generate additional combinations to reach a modest pool size.
    final seqs = <String, HangulCharacter>{};
    final rand = _rand;
    // Include single vowels as well (but they already exist in _characters)
    for (final v in vowels) {
      seqs[v.name] = v;
    }

    // Add preferred combos first
    for (var parts in preferred) {
      if (_hasVariedParts(parts)) {
        final s = _synthesizeSequence(parts);
        seqs[s.symbol] = s;
      }
    }

    // Then generate random combos of length 2..4
    final attempts = 100;
    for (var i = 0; i < attempts && seqs.length < 40; i++) {
      final len = 2 + rand.nextInt(3); // 2..4
      final parts = List.generate(
        len,
        (_) => vowels[rand.nextInt(vowels.length)],
      );
      if (!_hasVariedParts(parts)) continue;
      final s = _synthesizeSequence(parts);
      seqs[s.symbol] = s;
    }

    // Return only synthesized sequences of length >=2 to avoid duplicating
    // the original single-character list in candidates.
    return seqs.values.where((c) => c.name.length >= 2).toList();
  }

  List<MapEntry<HangulCharacter, TrainingMode>> _prioritizeConsonantCandidates(
    List<MapEntry<HangulCharacter, TrainingMode>> candidates,
  ) {
    if (candidates.isEmpty) return candidates;
    final priorities = _buildConsonantPreferenceOrder();
    for (final category in priorities) {
      final bucket = candidates
          .where((entry) => _categoryOf(entry.key) == category)
          .toList();
      if (bucket.isNotEmpty) return bucket;
    }
    return candidates;
  }

  List<ConsonantQuestionCategory> _buildConsonantPreferenceOrder() {
    final picked = _rollConsonantCategory();
    final order = [
      picked,
      ConsonantQuestionCategory.batchimWord,
      ConsonantQuestionCategory.openSyllable,
      ConsonantQuestionCategory.single,
    ];
    final result = <ConsonantQuestionCategory>[];
    final visited = <ConsonantQuestionCategory>{};
    for (final item in order) {
      if (!_allowedConsonantCategories.contains(item)) continue;
      if (visited.add(item)) {
        result.add(item);
      }
    }
    if (result.isEmpty) {
      return const [ConsonantQuestionCategory.single];
    }
    return result;
  }

  ConsonantQuestionCategory _rollConsonantCategory() {
    final value = _rand.nextDouble();
    if (value < 0.15) return ConsonantQuestionCategory.single;
    if (value < 0.55) return ConsonantQuestionCategory.openSyllable;
    return ConsonantQuestionCategory.batchimWord;
  }

  Set<ConsonantQuestionCategory> _buildAllowedConsonantCategories(
    SectionUnlockSummary summary,
  ) {
    final masteredCount = summary.statuses
        .where((status) => status.isMastered)
        .length;
    final allowed = <ConsonantQuestionCategory>{
      ConsonantQuestionCategory.single,
    };
    if (masteredCount >= 1) {
      allowed.add(ConsonantQuestionCategory.openSyllable);
    }
    if (masteredCount >= 2) {
      allowed.add(ConsonantQuestionCategory.batchimWord);
    }
    return allowed;
  }

  List<String> _generateOptions() {
    final correct = _getCorrectOption();
    final question = _currentQuestion!;
    List<HangulCharacter> pool;
    bool enforceSequenceLength = false;
    int? targetConsonantLength;
    ConsonantQuestionCategory? questionCategory;

    if (_isVowelTraining &&
        question.type == HangulCharacterType.vowel &&
        question.name.length >= 2) {
      pool = _buildVowelSequencePool();
      enforceSequenceLength = true;
    } else if (_isConsonantTraining) {
      questionCategory = _categoryOf(question);
      final length = _syllableLength(question.symbol);
      targetConsonantLength = length;
      final categoryPool = _characters
          .where((c) => _categoryOf(c) == questionCategory)
          .toList();
      final sameLengthPool = categoryPool
          .where((c) => _syllableLength(c.symbol) == length)
          .toList();

      pool = sameLengthPool.length >= 6 ? sameLengthPool : categoryPool;
    } else {
      pool = _characters;
    }

    List<HangulCharacter> optionsPool = pool.where((c) {
      if (_getOptionValue(c) == correct) return false;
      if (enforceSequenceLength &&
          question.name.length >= 2 &&
          c.name.length != question.name.length) {
        return false;
      }
      if (targetConsonantLength != null &&
          _syllableLength(c.symbol) != targetConsonantLength) {
        return false;
      }
      return true;
    }).toList();

    List<HangulCharacter> _filterForSoundGiven(List<HangulCharacter> source) {
      if (!_isGivenSound || _currentQuestion == null) return source;
      final group = _ttsGroupForSymbol(_currentQuestion!.symbol);
      if (group == null) return source;
      return source.where((c) => !group.contains(c.symbol)).toList();
    }

    optionsPool = _filterForSoundGiven(optionsPool);

    if (optionsPool.length < 5) {
      optionsPool = _buildFallbackOptions(
        correctOption: correct,
        question: question,
        enforceSequenceLength: enforceSequenceLength,
        targetConsonantLength: targetConsonantLength,
        categoryOverride: questionCategory,
      );
      optionsPool = _filterForSoundGiven(optionsPool);
    }

    optionsPool.shuffle();
    final selectedOthers = optionsPool
        .take(5)
        .map((c) => _getOptionValue(c))
        .toList();
    selectedOthers.add(correct);
    selectedOthers.shuffle();

    if (_isGivenSound || _isChooseSound) {
      // Prevent showing multiple similar vowels together when the
      // learner depends on TTS (either question or options).
      HangulCharacter? _charForOption(String opt) {
        for (final c in _characters) {
          if (_getOptionValue(c) == opt) return c;
        }
        // Also check synthesized vowel sequences
        final seqs = _buildVowelSequencePool();
        for (final c in seqs) {
          if (_getOptionValue(c) == opt) return c;
        }
        return null;
      }

      for (final group in _ttsConfusableGroups) {
        final present = <String>[];
        for (final opt in selectedOthers) {
          final c = _charForOption(opt);
          if (c == null) continue;
          if (group.contains(c.symbol)) present.add(opt);
        }
        if (present.length <= 1) continue;

        // If one of the present options is the correct one, keep it.
        String keepOpt = present.firstWhere(
          (o) => o == correct,
          orElse: () => '',
        );
        if (keepOpt.isEmpty) keepOpt = present.first;

        // Remove the others from selectedOthers
        for (final opt in present) {
          if (opt == keepOpt) continue;
          selectedOthers.remove(opt);
        }

        // Also remove the banned options from the pool so they can't
        // be reintroduced as replacements.
        optionsPool.removeWhere((c) => group.contains(c.symbol));

        // Try to find a replacement that's not already included
        HangulCharacter? replacementChar;
        for (final candidate in optionsPool) {
          final value = _getOptionValue(candidate);
          if (selectedOthers.contains(value) || value == correct) continue;
          if (group.contains(candidate.symbol)) continue;
          replacementChar = candidate;
          break;
        }
        if (replacementChar != null) {
          selectedOthers.add(_getOptionValue(replacementChar));
        }
        selectedOthers.shuffle();
      }
    }

    return selectedOthers;
  }

  List<HangulCharacter> _buildFallbackOptions({
    required String correctOption,
    required HangulCharacter question,
    required bool enforceSequenceLength,
    required int? targetConsonantLength,
    ConsonantQuestionCategory? categoryOverride,
  }) {
    List<HangulCharacter> pool;
    if (_isConsonantTraining) {
      final category = categoryOverride ?? _categoryOf(question);
      final desiredLength =
          targetConsonantLength ?? _syllableLength(question.symbol);
      pool = _characters.where((c) {
        if (_getOptionValue(c) == correctOption) return false;
        if (_categoryOf(c) != category) return false;
        if (_syllableLength(c.symbol) != desiredLength) return false;
        return true;
      }).toList();

      if (pool.length >= 5) {
        return pool;
      }

      return _characters.where((c) {
        if (_getOptionValue(c) == correctOption) return false;
        return _categoryOf(c) == category;
      }).toList();
    }

    if (enforceSequenceLength) {
      pool = _buildVowelSequencePool().where((c) {
        if (_getOptionValue(c) == correctOption) return false;
        return c.name.length == question.name.length;
      }).toList();
      if (pool.length >= 5) {
        return pool;
      }
    }

    return _characters
        .where((c) => _getOptionValue(c) != correctOption)
        .toList();
  }

  String _getCorrectOption() {
    return _getOptionValue(_currentQuestion!);
  }

  String _getOptionValue(HangulCharacter char) {
    switch (_currentMode!.choose) {
      case ChooseType.romanization:
        return char.romanization;
      case ChooseType.sound:
        return char.symbol; // For sound, we use symbol but will play TTS
      case ChooseType.hangul:
        // For vowel training prefer the 'name' (which includes leading ㅇ)
        if (char.type == HangulCharacterType.vowel) return char.name;
        return char.symbol;
    }
  }

  ConsonantQuestionCategory _categoryOf(HangulCharacter char) {
    final symbol = char.symbol;
    if (consonantBatchimWordSymbols.contains(symbol)) {
      return ConsonantQuestionCategory.batchimWord;
    }
    if (consonantOpenWordSymbols.contains(symbol)) {
      return ConsonantQuestionCategory.openSyllable;
    }
    if (_isHangulJamo(symbol)) {
      return ConsonantQuestionCategory.single;
    }
    if (_hasBatchim(symbol)) {
      return ConsonantQuestionCategory.batchimWord;
    }
    return ConsonantQuestionCategory.openSyllable;
  }

  int _syllableLength(String text) => text.runes.length;

  bool _isHangulJamo(String text) {
    if (text.runes.length != 1) return false;
    final code = text.runes.first;
    const jamoStart = 0x3131;
    const jamoEnd = 0x318E;
    const choseongStart = 0x1100;
    const choseongEnd = 0x11FF;
    return (code >= jamoStart && code <= jamoEnd) ||
        (code >= choseongStart && code <= choseongEnd);
  }

  bool _hasBatchim(String text) {
    for (final rune in text.runes) {
      const base = 0xAC00;
      const last = 0xD7A3;
      if (rune < base || rune > last) continue;
      final relative = rune - base;
      final jong = relative % 28;
      if (jong > 0) return true;
    }
    return false;
  }

  // Hangul composition helpers for synthesizing syllables from an initial
  // consonant jamo and a medial vowel jamo. Used to generate practice
  // items like '가', '고', '나' from base consonants when needed.
  static const List<String> _choseongList = [
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

  static const List<String> _jungseongList = [
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

  String _composeSyllable(String initialJamo, String medialJamo) {
    final ci = _choseongList.indexOf(initialJamo);
    final mi = _jungseongList.indexOf(medialJamo);
    if (ci == -1 || mi == -1) return '';
    // Syllable codepoint formula: 0xAC00 + (choseongIndex * 21 + jungseongIndex) * 28 + jongseongIndex
    const base = 0xAC00;
    final code = base + (ci * 21 + mi) * 28 + 0;
    return String.fromCharCode(code);
  }

  bool get _isGivenSound => _currentMode?.given == GivenType.sound;
  bool get _isChooseSound => _currentMode?.choose == ChooseType.sound;

  List<String>? _ttsGroupForSymbol(String symbol) {
    for (final group in _ttsConfusableGroups) {
      if (group.contains(symbol)) return group;
    }
    return null;
  }

  String _getGivenDisplay() {
    switch (_currentMode!.given) {
      case GivenType.hangul:
        // For vowel training prefer the readable name (e.g. '아') so the
        // displayed syllable includes an initial ㅇ. For synthesized
        // sequences the name is already the joined display.
        return _currentQuestion!.type == HangulCharacterType.vowel
            ? _currentQuestion!.name
            : _currentQuestion!.symbol;
      case GivenType.sound:
        // Will play TTS
        return ''; // Placeholder
      case GivenType.romanization:
        return _currentQuestion!.romanization;
    }
  }

  Future<void> _playSound(String symbol) async {
    final text = _getNameFromSymbol(symbol);
    try {
      await _flutterTts.speak(text);
    } catch (_) {
      // ignore TTS failures
    }
  }

  void _onOptionSelected(String option) {
    // When selecting an option, for TTS-type choices we want to play the
    // audio immediately and treat the tap as both "play" and "select".
    // We play audio on tap and mark selection, but do NOT auto-check the
    // answer here — the user must press '정답확인' to reveal correctness.
    final wasSoundChoice = _currentMode?.choose == ChooseType.sound;
    if (wasSoundChoice) {
      _playSound(option);
    }

    setState(() {
      _selectedOption = option;
    });
  }

  void _checkAnswer() async {
    final correct = _getCorrectOption();
    final isCorrect = _selectedOption == correct;
    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _totalCorrect++;
        final sym = _currentQuestion!.symbol;

        // If the symbol is a synthesized sequence (e.g. '아이'),
        // we want to credit '아' and '이' individually.
        // We can detect this by checking if the symbol length > 1 and it's vowel training,
        // OR just check if the symbol is composed of multiple known characters.
        // For simplicity, if it's vowel training and length > 1, we split by character.
        // Note: '아이' is length 2. '와' is length 1.
        // But wait, `_synthesizeSequence` uses `display` which is `name` joined.
        // Vowel names are '아', '야', etc.
        // So '아이' is '아' + '이'.
        // But '와' is a single character in `vowelSections`.
        // So we should iterate through the `_characters` (base vowels) and see which ones are present?
        // Or better, since `_synthesizeSequence` joins names, we can try to match names.
        // However, `_synthesizeSequence` is internal.
        // A robust way:
        // If `_isVowelTraining` and `_currentQuestion` is NOT in `_characters` (meaning it's synthesized),
        // then we decompose it.

        bool isSynthesized =
            _isVowelTraining && !_characters.contains(_currentQuestion);

        if (isSynthesized) {
          // Decompose. The symbol is the concatenation of names (e.g. '아이').
          // We need to find which vowels make up this string.
          // Since all vowel names are 1 char (actually '아' is 1 char, '와' is 1 char),
          // we can just iterate characters.
          for (var i = 0; i < sym.length; i++) {
            final charStr = sym[i];
            // Find the vowel with this name/symbol
            // Note: Vowel `symbol` is 'ㅏ', `name` is '아'.
            // The synthesized symbol uses `name` (e.g. '아').
            // So we look for a character where `name` == `charStr`.
            // Wait, `name` for 'ㅏ' is '아'.
            // So if sym is '아이', we have '아' and '이'.
            // We need to increment count for 'ㅏ' and 'ㅣ'.

            // Find character where name == charStr
            // If not found (maybe it's a consonant?), skip.
            // Actually, `_characters` contains the base vowels.
            for (final baseChar in _characters) {
              if (baseChar.name == charStr) {
                _sessionCorrectCounts[baseChar.symbol] =
                    (_sessionCorrectCounts[baseChar.symbol] ?? 0) + 1;
                break;
              }
            }
          }
        } else {
          // Standard single character
          _sessionCorrectCounts[sym] = (_sessionCorrectCounts[sym] ?? 0) + 1;
        }

        final key =
            '${_currentQuestion!.symbol}|${_currentMode!.given.index}-${_currentMode!.choose.index}';
        _sessionCorrectPairs.add(key);
      } else {
        _globalWrongCount++;
        if (_globalWrongCount >= 5) {
          _showAdDialog();
          _globalWrongCount = 0;
        }
        _saveCounts();
      }
    });
    if (!isCorrect && _currentQuestion != null && _currentMode != null) {
      _scheduleRetry(_currentQuestion!, _currentMode!);
    }
    _rememberCurrentWord();
    if (_totalCorrect == _sessionGoal) {
      await _updateCountsAndSave();
      _showCompletionDialog();
    }
  }

  void _rememberCurrentWord() {
    if (!_isConsonantTraining) return;
    final current = _currentQuestion;
    if (current == null) return;
    if (_categoryOf(current) == ConsonantQuestionCategory.single) return;
    unawaited(_recordLearnedWord(current));
  }

  Future<void> _recordLearnedWord(HangulCharacter char) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_learnedWordsPrefsKey);
      final entries = raw == null
          ? <LearnedWordEntry>[]
          : (jsonDecode(raw) as List<dynamic>)
                .map(
                  (item) => LearnedWordEntry.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      final idx = entries.indexWhere((e) => e.term == char.symbol);
      final now = DateTime.now();
      if (idx == -1) {
        entries.add(
          LearnedWordEntry(
            term: char.symbol,
            romanization: char.romanization,
            meaning: char.meaning,
            seenAt: now,
            timesSeen: 1,
          ),
        );
      } else {
        final existing = entries[idx];
        entries[idx] = existing.copyWith(
          seenAt: now,
          timesSeen: existing.timesSeen + 1,
        );
      }
      entries.sort((a, b) => b.seenAt.compareTo(a.seenAt));
      await prefs.setString(
        _learnedWordsPrefsKey,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {
      // Ignore persistence failures to avoid interrupting 학습 흐름.
    }
  }

  void _scheduleRetry(HangulCharacter character, TrainingMode mode) {
    final exists = _retryQueue.any(
      (entry) =>
          entry.character.symbol == character.symbol &&
          entry.mode.given == mode.given &&
          entry.mode.choose == mode.choose,
    );
    if (exists) return;

    final retryMode = _pickRetryMode(character, mode);
    final availableAfter = _questionsServed + _minRetryGap;
    _retryQueue.add(
      _RetryQuestion(
        character: character,
        mode: retryMode,
        availableAfter: availableAfter,
      ),
    );
  }

  TrainingMode _pickRetryMode(
    HangulCharacter character,
    TrainingMode failedMode,
  ) {
    final modes = _trainingModes;
    final alternatives = modes
        .where(
          (mode) =>
              mode.given != failedMode.given ||
              mode.choose != failedMode.choose,
        )
        .toList();
    final unused = alternatives.where((mode) {
      final key =
          '${character.symbol}|${mode.given.index}-${mode.choose.index}';
      return !_sessionCorrectPairs.contains(key);
    }).toList();
    final pool = unused.isNotEmpty
        ? unused
        : (alternatives.isNotEmpty ? alternatives : modes);
    return pool[_rand.nextInt(pool.length)];
  }

  _RetryQuestion? _pullRetryQuestion({bool force = false}) {
    if (_retryQueue.isEmpty) return null;
    _retryQueue.sort((a, b) => a.availableAfter.compareTo(b.availableAfter));
    final readyIndex = _retryQueue.indexWhere(
      (entry) => entry.availableAfter <= _questionsServed,
    );
    if (readyIndex != -1) {
      return _retryQueue.removeAt(readyIndex);
    }
    if (force) {
      return _retryQueue.removeAt(0);
    }
    return null;
  }

  void _nextQuestion() {
    setState(() {
      _startNewQuestion();
    });
  }

  void _restartSession() {
    setState(() {
      _totalCorrect = 0;
      _sessionCorrectPairs.clear();
      _sessionCorrectCounts.clear();
      _retryQueue.clear();
      _questionsServed = 0;
      _startNewQuestion();
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: CustomLiquidGlassDialog(
            title: const Text('훈련 완료!'),
            content: Text('총 맞힌 수: $_totalCorrect, 틀린 수: $_globalWrongCount'),
            actions: [
              CustomLiquidGlassDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  _restartSession();
                },
                child: const Text('한 번 더 풀기'),
              ),
              CustomLiquidGlassDialogAction(
                isConfirmationBlue: true,
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close TrainingScreen
                },
                child: const Text('홈으로 가기'),
              ),
            ],
          ),
        ),
      ),
    );
    // Show interstitial ad here
  }

  void _showAdDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('잠깐 숨 돌려요'),
          content: const Text('집중력이 흔들릴 땐 짧은 광고나 스트레칭으로 리셋해주세요.'),
          actions: [
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('훈련 중단'),
          content: const Text('지금 나가면 훈련 기록이 저장되지 않아요. 그래도 나가시겠어요?'),
          actions: [
            CustomLiquidGlassDialogAction(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close TrainingScreen
              },
              child: const Text('나가기'),
            ),
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('훈련하기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMode == null || _currentQuestion == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);

    final bool canCheck = !_showResult && _selectedOption != null;
    final bool canAdvance = _showResult && _totalCorrect < _sessionGoal;
    final String buttonLabel = !_showResult
        ? '정답 확인'
        : (_totalCorrect >= _sessionGoal ? '완료' : '다음 문제');
    final VoidCallback? primaryAction = !_showResult
        ? (canCheck ? _checkAnswer : null)
        : (canAdvance ? _nextQuestion : null);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          // Avoid adding bottom safe-area padding here so the action button's
          // bottom offset lines up with other screens that don't use SafeArea.
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    LiquidGlassButtons.circularIconButton(
                      context,
                      onPressed: () => _showExitDialog(),
                      // Use Cupertino chevron instead of Material arrow
                      icon: CupertinoIcons.left_chevron,
                      isBackgroundBright: false,
                    ),
                    const SizedBox(width: 16),
                    _buildProgressMeter(
                      context: context,
                      label: '맞힌 문제',
                      value: _totalCorrect,
                      goal: _sessionGoal,
                      color: palette.success,
                    ),
                    const SizedBox(width: 16),
                    _buildProgressMeter(
                      context: context,
                      label: '실수 카운트',
                      value: _globalWrongCount,
                      goal: 5,
                      color: palette.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_currentMode!.given == GivenType.sound)
                  IntrinsicWidth(
                    child: LearnHangulSurface(
                      backgroundColor: palette.elevatedSurface,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      onTap: () => _playSound(_currentQuestion!.symbol),
                      child: Center(
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 40,
                          color: palette.primaryText,
                        ),
                      ),
                    ),
                  )
                else
                  LearnHangulSurface(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getGivenDisplay(),
                          style: typography.hero.copyWith(fontSize: 40),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 1.1,
                        ),
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      final option = _options[index];
                      return _buildOptionCard(
                        context: context,
                        option: option,
                        isCorrectAnswer: option == _getCorrectOption(),
                        isSelected: option == _selectedOption,
                        showIcon:
                            _currentMode!.choose == ChooseType.sound &&
                            !_showResult,
                        onTap: _showResult
                            ? null
                            : () => _onOptionSelected(option),
                      );
                    },
                  ),
                ),
                // Result notice intentionally hidden per UX change.
                const SizedBox(height: 12),
                Padding(
                  // Outer horizontal padding of this screen is 20; add 4 to reach
                  // the 24 horizontal padding used by the main screens. Also
                  // add 12 bottom here so combined bottom padding equals 24.
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: LiquidGlassButton(
                    label: buttonLabel,
                    onPressed: primaryAction,
                    variant: _showResult
                        ? (_isCorrect
                              ? LiquidGlassButtonVariant.success
                              : LiquidGlassButtonVariant.danger)
                        : LiquidGlassButtonVariant.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String option,
    required bool isCorrectAnswer,
    required bool isSelected,
    required bool showIcon,
    required VoidCallback? onTap,
  }) {
    final palette = LearnHangulTheme.paletteOf(context);
    final typography = LearnHangulTheme.typographyOf(context);

    Color background = palette.surface;
    Color border = palette.outline;
    Color foreground = palette.primaryText;

    if (_showResult) {
      if (isCorrectAnswer) {
        background = palette.success.withOpacity(0.15);
        border = palette.success;
        foreground = palette.success;
      } else if (isSelected && !_isCorrect) {
        background = palette.danger.withOpacity(0.15);
        border = palette.danger;
        foreground = palette.danger;
      }
    } else if (isSelected) {
      background = palette.info.withOpacity(0.12);
      border = palette.info.withOpacity(0.5);
      foreground = palette.info;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Center(
            child: showIcon
                ? Icon(Icons.volume_up_rounded, color: foreground, size: 34)
                : Text(
                    option,
                    textAlign: TextAlign.center,
                    style: typography.heading.copyWith(color: foreground),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressMeter({
    required BuildContext context,
    required String label,
    required int value,
    required int goal,
    required Color color,
  }) {
    final typography = LearnHangulTheme.typographyOf(context);
    final palette = LearnHangulTheme.paletteOf(context);
    final progress = (value / goal).clamp(0.0, 1.0);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: palette.surface,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text('$value / $goal', style: typography.caption),
        ],
      ),
    );
  }
}

class _RetryQuestion {
  _RetryQuestion({
    required this.character,
    required this.mode,
    required this.availableAfter,
  });

  final HangulCharacter character;
  final TrainingMode mode;
  int availableAfter;
}
