import 'package:learnhangul/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../premium_voice_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../custom_liquid_glass_dialog.dart';
import '../design_system.dart';
import '../data/training_words_repository.dart';
import '../liquid_glass_buttons.dart';
import '../models.dart';
import '../services/ad_ids.dart';
import '../services/analytics_service.dart';
import '../utils.dart';
import 'common.dart';

enum ConsonantQuestionCategory { single, openSyllable, batchimWord }

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
  String? _currentTrackingSymbol;
  List<String> _options = [];
  String? _selectedOption;
  bool _showResult = false;
  bool _isCorrect = false;
  final Set<String> _sessionCorrectPairs = <String>{};
  TrainingMode? _lastMode;
  String? _lastCharacterSymbol;
  final Random _rand = Random();
  SectionUnlockSummary? _sectionSummary;
  Set<ConsonantQuestionCategory> _allowedConsonantCategories = const {
    ConsonantQuestionCategory.single,
  };
  final List<_RetryQuestion> _retryQueue = <_RetryQuestion>[];
  TrainingWordData? _trainingWords;
  TopikWordLevel? _activeTrainingWordLevel;
  static const int _sessionGoal = 10;
  static const int _minRetryGap = 3;
  int _questionsServed = 0;
  static const String _adPlacementExit = AdIDs.placementExitBeforeComplete;
  static const String _adPlacementWrong = AdIDs.placementWrongOverFive;
  bool _sessionLogged = false;

  bool get _isVowelTraining => identical(widget.sections, vowelSections);

  bool get _isConsonantTraining =>
      identical(widget.sections, consonantSections) ||
      (widget.sections.isNotEmpty &&
          widget.sections.first.characters.isNotEmpty &&
          widget.sections.first.characters.first.type ==
              HangulCharacterType.consonant);

  HangulCharacter _synthesizeSequence(List<HangulCharacter> parts) {
    final display = parts.map((p) => p.name).join();
    final roman = parts.map((p) => p.romanization).join('-');
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

  bool get _includesWordPool =>
      _trainingWords?.consonantTrainingWordPool.isNotEmpty ?? false;

  void _logSessionStart({required bool includesWordPool}) {
    if (_sessionLogged) return;
    AnalyticsService.instance.trackTrainingSessionStarted(
      isConsonantSession: _isConsonantTraining,
      includesWordPool: includesWordPool,
      questionPoolSize: _characters.length,
      wordLevel: _activeTrainingWordLevel,
    );
    _sessionLogged = true;
  }

  @override
  void initState() {
    super.initState();
    _configureTts();
    _loadCounts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _configureTts() async {
    final double rate = (_isVowelTraining || _isConsonantTraining) ? 0.35 : 0.5;
    try {
      await _flutterTts.setLanguage('ko-KR');
    } catch (_) {}
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (_) {
      // ignore
    }
    try {
      await _flutterTts.setPitch(1.0);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    TrainingWordData? trainingWords;
    if (_isConsonantTraining) {
      final level = await TopikWordLevelPreferences.load();
      final shouldReload =
          _trainingWords == null || _activeTrainingWordLevel != level;
      if (shouldReload) {
        trainingWords = await trainingWordRepository.load(level: level);
        _trainingWords = trainingWords;
        _activeTrainingWordLevel = level;
      } else {
        trainingWords = _trainingWords;
      }
    }
    final baseCharacters = widget.sections
        .expand((section) => section.characters)
        .toList();
    final extraCharacters =
        trainingWords?.consonantTrainingWordPool ?? const <HangulCharacter>[];
    final includesWordPool = extraCharacters.isNotEmpty;
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

    if (trainingWords != null) {
      _characters = [
        ..._characters,
        ...trainingWords.consonantTrainingWordPool,
      ];
    }

    // Exclude affix-like training entries (contain '-') from being presented
    // during training. They remain in the repository for storage/lookup,
    // but shouldn't be used as candidates or options.
    _characters = _characters.where((c) => !c.symbol.contains('-')).toList();

    _retryQueue.clear();

    setState(() {
      _correctCounts = counts;
      _sectionSummary = summary;
      _sessionCorrectCounts = {};
      _globalWrongCount = prefs.getInt('global_wrong_count') ?? 0;
      _allowedConsonantCategories =
          _isConsonantTraining && trainingWords != null
          ? _buildAllowedConsonantCategories(summary)
          : const {ConsonantQuestionCategory.single};
      _questionsServed = 0;
    });
    _sessionLogged = false;
    _startNewQuestion();
    _logSessionStart(includesWordPool: includesWordPool);
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
    final retryInfo = _pullRetryQuestion();
    if (retryInfo != null) {
      choice = MapEntry(retryInfo.character, retryInfo.mode);
    }

    if (choice == null) {
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

      if (_isVowelTraining) {
        final sequences = _buildVowelSequencePool();
        reviewPool.addAll(sequences);
      }

      if (_isConsonantTraining) {
        bool isCategoryAllowed(HangulCharacter char) {
          return _allowedConsonantCategories.contains(_categoryOf(char));
        }

        targetPool = targetPool.where(isCategoryAllowed).toList();
        reviewPool = reviewPool.where(isCategoryAllowed).toList();
      }

      bool useTargetPool = false;
      if (targetPool.isNotEmpty && reviewPool.isNotEmpty) {
        useTargetPool = _rand.nextDouble() < 0.7;
      } else if (targetPool.isNotEmpty) {
        useTargetPool = true;
      } else if (reviewPool.isNotEmpty) {
        useTargetPool = false;
      } else {
        if (_isConsonantTraining) {
          final fallbackPool = _characters.where((c) {
            return _allowedConsonantCategories.contains(_categoryOf(c));
          }).toList();
          if (fallbackPool.isNotEmpty) {
            targetPool = fallbackPool;
          } else {
            targetPool = List.from(_characters);
          }
        } else {
          targetPool = List.from(_characters);
        }
        reviewPool = <HangulCharacter>[];
        useTargetPool = true;
      }

      final sourcePool = useTargetPool ? targetPool : reviewPool;
      final candidates = <MapEntry<HangulCharacter, TrainingMode>>[];

      for (final c in sourcePool) {
        if (_isConsonantTraining &&
            !_allowedConsonantCategories.contains(_categoryOf(c))) {
          continue;
        }

        final allowedModes = (useTargetPool)
            ? modes.where((m) => m.given != GivenType.sound).toList()
            : modes;

        for (final m in allowedModes) {
          final key = '${c.symbol}|${m.given.index}-${m.choose.index}';
          if (_sessionCorrectPairs.contains(key)) continue;
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

      if (candidates.isEmpty) {
        for (final c in sourcePool) {
          if (_isConsonantTraining &&
              !_allowedConsonantCategories.contains(_categoryOf(c))) {
            continue;
          }
          final allowedModes = (useTargetPool)
              ? modes.where((m) => m.given != GivenType.sound).toList()
              : modes;
          for (final m in allowedModes) {
            final key = '${c.symbol}|${m.given.index}-${m.choose.index}';
            if (_sessionCorrectPairs.contains(key)) continue;
            candidates.add(MapEntry(c, m));
          }
        }
      }

      if (candidates.isEmpty && _isConsonantTraining) {
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
            final baseCount = _correctCounts[c.symbol] ?? 0;
            if (!isHangulJamo(c.symbol) || baseCount < 3) continue;

            for (final v in vowels) {
              final composed = composeSyllable(c.symbol, v.symbol);
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

      if (candidates.isEmpty && useTargetPool && reviewPool.isNotEmpty) {
        for (final c in reviewPool) {
          if (_isConsonantTraining &&
              !_allowedConsonantCategories.contains(_categoryOf(c))) {
            continue;
          }
          for (final m in modes) {
            final key = '${c.symbol}|${m.given.index}-${m.choose.index}';
            if (_sessionCorrectPairs.contains(key)) continue;
            candidates.add(MapEntry(c, m));
          }
        }
      }

      if (candidates.isEmpty && _isConsonantTraining) {
        for (final c in sourcePool) {
          if (!_allowedConsonantCategories.contains(_categoryOf(c))) {
            continue;
          }
          for (final m in modes) {
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
        final filteredCandidates = _isConsonantTraining
            ? _prioritizeConsonantCandidates(candidates)
            : candidates;

        final weightedCandidates =
            <MapEntry<HangulCharacter, TrainingMode>, double>{};
        double totalWeight = 0.0;

        for (final cand in filteredCandidates) {
          final char = cand.key;
          final count = _correctCounts[char.symbol] ?? 0;
          final weight = 1.0 / (count + 1);
          weightedCandidates[cand] = weight;
          totalWeight += weight;
        }

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
        selected ??= filteredCandidates.last;
        choice = selected;
      }
    }
    final MapEntry<HangulCharacter, TrainingMode> selectedChoice = choice;
    _currentMode = selectedChoice.value;
    if (retryInfo case final retry?) {
      _currentQuestion = selectedChoice.key;
      _currentTrackingSymbol = retry.trackingSymbol;
    } else {
      final batchimOverride = _pickBatchimOnlyWord(selectedChoice.key.symbol);
      _currentQuestion = batchimOverride ?? selectedChoice.key;
      _currentTrackingSymbol = batchimOverride != null
          ? selectedChoice.key.symbol
          : _currentQuestion!.symbol;
    }
    _questionsServed++;

    _lastMode = _currentMode;
    _lastCharacterSymbol = _questionTrackingSymbol();

    _options = _generateOptions();

    _selectedOption = null;
    _showResult = false;

    if (_currentMode?.given == GivenType.sound) {
      unawaited(_playSound(_currentQuestion!.symbol));
    }
  }

  String _getNameFromSymbol(String symbol) {
    final idx = _characters.indexWhere((c) => c.symbol == symbol);
    if (idx != -1) return _pronunciationFor(_characters[idx]);

    // Fallback: symbol may be a training-word that was filtered out from
    // the presented pool (e.g. affix-like entries). Try lookup in the
    // training words repository so pronunciation/name is available for TTS.
    final trainingWords = _trainingWords;
    if (trainingWords != null) {
      final hw = trainingWords.trainingWordBySymbol[symbol];
      if (hw != null) return _pronunciationFor(hw);
    }

    return symbol;
  }

  bool _isTrainingWordSymbol(String symbol) {
    final trainingWords = _trainingWords;
    if (trainingWords == null) return false;
    return trainingWords.trainingWordBySymbol.containsKey(symbol);
  }

  List<HangulCharacter> _batchimOnlyOptionPool() {
    final trainingWords = _trainingWords;
    if (trainingWords == null) return const [];
    final seen = <String>{};
    final pool = <HangulCharacter>[];
    for (final word in trainingWords.batchimOnlyWordPool) {
      if (word.symbol.contains('-')) continue;
      if (seen.add(word.symbol)) pool.add(word);
    }
    return pool;
  }

  String _hangulDisplayLabel(HangulCharacter char) {
    if (_isTrainingWordSymbol(char.symbol)) {
      return sanitizeTrainingWordSymbol(char.symbol);
    }
    if (char.type == HangulCharacterType.vowel) return char.name;
    return char.symbol;
  }

  String _formatOptionLabel(String option) {
    // If this option corresponds to a training-word symbol (loaded from
    // CSV), present a sanitized form to the user so numeric suffixes and
    // punctuation are not shown. This applies regardless of the current
    // choose mode (e.g. for sound options we still reveal the clean
    // Hangul text when answers are shown).
    if (_isTrainingWordSymbol(option)) {
      return sanitizeTrainingWordSymbol(option);
    }

    // Otherwise, for non-training-word options, only special-case
    // Hangul-mode where vowel characters use their `name`.
    if (_currentMode?.choose != ChooseType.hangul) return option;
    return option;
  }

  String _pronunciationFor(HangulCharacter char) {
    if (char.type == HangulCharacterType.consonant &&
        isHangulJamo(char.symbol)) {
      final override = consonantSoundOverrides[char.symbol];
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

    final byName = {for (var v in vowels) v.name: v};

    final preferred = <List<HangulCharacter>>[];
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

    final seqs = <String, HangulCharacter>{};
    final rand = _rand;
    for (final v in vowels) {
      seqs[v.name] = v;
    }

    for (var parts in preferred) {
      if (_hasVariedParts(parts)) {
        final s = _synthesizeSequence(parts);
        seqs[s.symbol] = s;
      }
    }

    final attempts = 100;
    for (var i = 0; i < attempts && seqs.length < 40; i++) {
      final len = 2 + rand.nextInt(3);
      final parts = List.generate(
        len,
        (_) => vowels[rand.nextInt(vowels.length)],
      );
      if (!_hasVariedParts(parts)) continue;
      final s = _synthesizeSequence(parts);
      seqs[s.symbol] = s;
    }

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
      if (visited.add(item)) result.add(item);
    }
    if (result.isEmpty) return const [ConsonantQuestionCategory.single];
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
    if (masteredCount >= 1) allowed.add(ConsonantQuestionCategory.openSyllable);
    if (masteredCount >= 2) allowed.add(ConsonantQuestionCategory.batchimWord);
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
      final bool useBatchimOnlyPool =
          questionCategory == ConsonantQuestionCategory.batchimWord &&
          _isBatchimOnlyTrackingSymbol();
      List<HangulCharacter> categoryPool;
      if (useBatchimOnlyPool) {
        categoryPool = _batchimOnlyOptionPool();
        if (categoryPool.isEmpty) {
          categoryPool = _characters
              .where((c) => _categoryOf(c) == questionCategory)
              .toList();
        }
      } else {
        categoryPool = _characters
            .where((c) => _categoryOf(c) == questionCategory)
            .toList();
      }
      final sameLengthPool = categoryPool
          .where((c) => _syllableLength(c.symbol) == length)
          .toList();

      pool = sameLengthPool.length >= 6 ? sameLengthPool : categoryPool;
    } else {
      pool = _characters;
    }

    List<HangulCharacter> optionsPool = pool.where((c) {
      if (_getOptionValue(c) == correct) {
        return false;
      }
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

    List<HangulCharacter> filterForSoundGiven(List<HangulCharacter> source) {
      if (!_isGivenSound || _currentQuestion == null) return source;
      final group = _ttsGroupForSymbol(_currentQuestion!.symbol);
      if (group == null) return source;
      return source.where((c) => !group.contains(c.symbol)).toList();
    }

    optionsPool = filterForSoundGiven(optionsPool);

    // If the current question expects romanization as the choice, ensure
    // candidate options have the same number of romanization parts
    // (syllable-separated by '-') as the correct answer. This prevents
    // mixing 1/2/3-syllable romanizations when the question has 3
    // syllables (e.g. '값어치' -> 'gap-eo-chi').
    if (_currentMode?.choose == ChooseType.romanization) {
      final correctRoman = _getCorrectOption();
      final expectedParts = correctRoman
          .split('-')
          .where((p) => p.isNotEmpty)
          .length;
      optionsPool = optionsPool.where((c) {
        final parts = _getOptionValue(
          c,
        ).split('-').where((p) => p.isNotEmpty).length;
        return parts == expectedParts;
      }).toList();
    }

    if (optionsPool.length < 5) {
      optionsPool = _buildFallbackOptions(
        correctOption: correct,
        question: question,
        enforceSequenceLength: enforceSequenceLength,
        targetConsonantLength: targetConsonantLength,
        categoryOverride: questionCategory,
      );
      optionsPool = filterForSoundGiven(optionsPool);

      // Re-apply romanization-length filter after fallback generation as
      // the fallback may have introduced candidates with differing
      // syllable counts.
      if (_currentMode?.choose == ChooseType.romanization) {
        final correctRoman = _getCorrectOption();
        final expectedParts = correctRoman
            .split('-')
            .where((p) => p.isNotEmpty)
            .length;
        optionsPool = optionsPool.where((c) {
          final parts = _getOptionValue(
            c,
          ).split('-').where((p) => p.isNotEmpty).length;
          return parts == expectedParts;
        }).toList();
      }
    }

    optionsPool.shuffle();

    var selectedCharOthers = optionsPool.take(5).toList();

    if (enforceSequenceLength && question.name.length >= 2) {
      selectedCharOthers.retainWhere(
        (c) => c.name.length == question.name.length,
      );
      for (final candidate in optionsPool) {
        if (selectedCharOthers.length >= 5) break;
        if (selectedCharOthers.contains(candidate)) continue;
        if (candidate.name.length != question.name.length) continue;
        selectedCharOthers.add(candidate);
      }
      for (final candidate in optionsPool) {
        if (selectedCharOthers.length >= 5) break;
        if (selectedCharOthers.contains(candidate)) continue;
        selectedCharOthers.add(candidate);
      }
    }

    if (_isBatchimOnlyTrackingSymbol() && _isGivenSound) {
      selectedCharOthers = _filterBatchimSoundConflicts(
        selectedCharOthers,
        question,
        optionsPool,
      );
    }

    selectedCharOthers.removeWhere((c) => _getOptionValue(c) == correct);

    final selectedOthers = selectedCharOthers
        .take(5)
        .map((c) => _getOptionValue(c))
        .toList();
    selectedOthers.add(correct);
    selectedOthers.shuffle();

    if (_isGivenSound || _isChooseSound) {
      HangulCharacter? charForOption(String opt) {
        for (final c in _characters) {
          if (_getOptionValue(c) == opt) return c;
        }
        final seqs = _buildVowelSequencePool();
        for (final c in seqs) {
          if (_getOptionValue(c) == opt) return c;
        }
        return null;
      }

      for (final group in _ttsConfusableGroups) {
        final present = <String>[];
        for (final opt in selectedOthers) {
          final c = charForOption(opt);
          if (c == null) continue;
          if (group.contains(c.symbol)) present.add(opt);
        }
        if (present.length <= 1) continue;

        String keepOpt = present.firstWhere(
          (o) => o == correct,
          orElse: () => '',
        );
        if (keepOpt.isEmpty) keepOpt = present.first;

        for (final opt in present) {
          if (opt == keepOpt) {
            continue;
          }
          selectedOthers.remove(opt);
        }

        optionsPool.removeWhere((c) => group.contains(c.symbol));

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
      final useBatchimOnlyPool =
          category == ConsonantQuestionCategory.batchimWord &&
          _isBatchimOnlyTrackingSymbol();
      List<HangulCharacter> sourcePool;
      if (useBatchimOnlyPool) {
        sourcePool = _batchimOnlyOptionPool();
        if (sourcePool.isEmpty) sourcePool = _characters;
      } else {
        sourcePool = _characters;
      }
      pool = sourcePool.where((c) {
        if (_getOptionValue(c) == correctOption) return false;
        if (_categoryOf(c) != category) return false;
        if (_syllableLength(c.symbol) != desiredLength) return false;
        return true;
      }).toList();

      if (pool.length >= 5) return pool;

      return sourcePool.where((c) {
        if (_getOptionValue(c) == correctOption) return false;
        return _categoryOf(c) == category;
      }).toList();
    }

    if (enforceSequenceLength) {
      pool = _buildVowelSequencePool().where((c) {
        if (_getOptionValue(c) == correctOption) return false;
        return c.name.length == question.name.length;
      }).toList();
      if (pool.length >= 5) return pool;
    }

    return _characters
        .where((c) => _getOptionValue(c) != correctOption)
        .toList();
  }

  List<HangulCharacter> _filterBatchimSoundConflicts(
    List<HangulCharacter> initial,
    HangulCharacter question,
    List<HangulCharacter> sourcePool, {
    int desiredCount = 5,
  }) {
    final questionKey = batchimOnlyPronunciationKey(question.symbol);
    if (questionKey == null) return initial;
    final seenKeys = <String>{questionKey};
    final unique = <HangulCharacter>[];
    final fallback = <HangulCharacter>[];
    final usedSymbols = <String>{};

    void categorize(HangulCharacter candidate) {
      if (usedSymbols.contains(candidate.symbol)) return;
      usedSymbols.add(candidate.symbol);
      final key = batchimOnlyPronunciationKey(candidate.symbol);
      if (key == null) {
        fallback.add(candidate);
        return;
      }
      if (seenKeys.add(key)) {
        unique.add(candidate);
      } else {
        fallback.add(candidate);
      }
    }

    for (final candidate in initial) {
      categorize(candidate);
    }

    if (unique.length < desiredCount) {
      for (final candidate in sourcePool) {
        if (unique.length >= desiredCount) break;
        categorize(candidate);
      }
    }

    final result = <HangulCharacter>[];
    for (final cand in unique) {
      if (result.length >= desiredCount) break;
      result.add(cand);
    }
    for (final cand in fallback) {
      if (result.length >= desiredCount) break;
      result.add(cand);
    }
    return result.isEmpty ? initial : result;
  }

  String _getCorrectOption() => _getOptionValue(_currentQuestion!);

  String _getOptionValue(HangulCharacter char) {
    switch (_currentMode!.choose) {
      case ChooseType.romanization:
        return char.romanization;
      case ChooseType.sound:
        return char.symbol;
      case ChooseType.hangul:
        if (char.type == HangulCharacterType.vowel) return char.name;
        return char.symbol;
    }
  }

  ConsonantQuestionCategory _categoryOf(HangulCharacter char) {
    final symbol = char.symbol;
    if (batchimOnlyConsonants.contains(symbol)) {
      return ConsonantQuestionCategory.batchimWord;
    }
    final trainingWords = _trainingWords;
    if (trainingWords != null) {
      if (trainingWords.consonantBatchimWordSymbols.contains(symbol)) {
        return ConsonantQuestionCategory.batchimWord;
      }
      if (trainingWords.consonantOpenWordSymbols.contains(symbol)) {
        return ConsonantQuestionCategory.openSyllable;
      }
    }
    if (isHangulJamo(symbol)) return ConsonantQuestionCategory.single;
    if (hasBatchim(symbol)) return ConsonantQuestionCategory.batchimWord;
    return ConsonantQuestionCategory.openSyllable;
  }

  int _syllableLength(String text) {
    // If this text is a training-word symbol (from the CSV), compute length
    // based on the sanitized name so numeric suffixes don't affect length
    // comparisons used when building option pools.
    // Always sanitize the incoming text first so that any numeric suffixes
    // or punctuation are removed before computing length. This ensures
    // variants like "소재02" or "지구02" count as the correct Hangul
    // syllable length rather than including digits.
    final sanitized = sanitizeTrainingWordSymbol(text);
    if (sanitized.isNotEmpty) return sanitized.runes.length;
    return text.runes.length;
  }

  HangulCharacter? _pickBatchimOnlyWord(String symbol) {
    final trainingWords = _trainingWords;
    if (trainingWords == null) return null;
    if (!batchimOnlyConsonants.contains(symbol)) return null;
    final words = trainingWords.batchimOnlyQuestionWords[symbol];
    if (words == null || words.isEmpty) return null;
    final presentable = words.where((w) => !w.symbol.contains('-')).toList();
    if (presentable.isEmpty) return null;
    return presentable[_rand.nextInt(presentable.length)];
  }

  String _questionTrackingSymbol() =>
      _currentTrackingSymbol ?? (_currentQuestion?.symbol ?? '');

  bool _isBatchimOnlyTrackingSymbol() =>
      batchimOnlyConsonants.contains(_questionTrackingSymbol());

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
        return _hangulDisplayLabel(_currentQuestion!);
      case GivenType.sound:
        return '';
      case GivenType.romanization:
        return _currentQuestion!.romanization;
    }
  }

  Future<void> _playSound(String symbol) async {
    final text = _getNameFromSymbol(symbol);
    try {
      // Require premium Korean voice before speaking
      final ok = await showPremiumVoiceCheckDialog(context);
      if (!ok) return;
      await _flutterTts.speak(text);
    } catch (error) {
      // ignore
    }
  }

  void _onOptionSelected(String option) {
    final wasSoundChoice = _currentMode?.choose == ChooseType.sound;
    if (wasSoundChoice) _playSound(option);
    setState(() {
      _selectedOption = option;
    });
  }

  void _checkAnswer() async {
    final correct = _getCorrectOption();
    final isCorrect = _selectedOption == correct;
    final questionSymbol = _currentQuestion?.symbol;
    final givenTypeName = _currentMode?.given.name;
    final chooseTypeName = _currentMode?.choose.name;
    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _totalCorrect++;
        final questionSymbol = _currentQuestion!.symbol;
        final trackingSymbol = _questionTrackingSymbol();

        bool isSynthesized =
            _isVowelTraining && !_characters.contains(_currentQuestion);

        if (isSynthesized) {
          for (var i = 0; i < questionSymbol.length; i++) {
            final charStr = questionSymbol[i];
            for (final baseChar in _characters) {
              if (baseChar.name == charStr) {
                _sessionCorrectCounts[baseChar.symbol] =
                    (_sessionCorrectCounts[baseChar.symbol] ?? 0) + 1;
                break;
              }
            }
          }
        } else {
          _sessionCorrectCounts[trackingSymbol] =
              (_sessionCorrectCounts[trackingSymbol] ?? 0) + 1;
        }

        final key =
            '$trackingSymbol|${_currentMode!.given.index}-${_currentMode!.choose.index}';
        _sessionCorrectPairs.add(key);
      } else {
        _globalWrongCount++;
        if (_globalWrongCount >= 5) {
          _showInterstitialAd(placement: _adPlacementWrong);
          _globalWrongCount = 0;
        }
        _saveCounts();
      }
    });
    if (questionSymbol != null &&
        givenTypeName != null &&
        chooseTypeName != null) {
      AnalyticsService.instance.trackTrainingQuestion(
        isCorrect: isCorrect,
        symbol: questionSymbol,
        givenType: givenTypeName,
        chooseType: chooseTypeName,
      );
    }
    if (!isCorrect && _currentQuestion != null && _currentMode != null) {
      _scheduleRetry(_currentQuestion!, _currentMode!);
    }
    _rememberCurrentWord();
    if (_totalCorrect == _sessionGoal) {
      await _updateCountsAndSave();
      AnalyticsService.instance.trackTrainingCompleted(
        totalCorrect: _totalCorrect,
        mistakes: _globalWrongCount,
      );
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
      final raw = prefs.getString(learnedWordsPrefsKey);
      final entries = raw == null
          ? <LearnedWordEntry>[]
          : (jsonDecode(raw) as List<dynamic>)
                .map(
                  (item) => LearnedWordEntry.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      final idx = entries.indexWhere((e) => e.symbol == char.symbol);
      final now = DateTime.now();
      final displayTerm = _hangulDisplayLabel(char);
      if (idx == -1) {
        entries.add(
          LearnedWordEntry(
            symbol: char.symbol,
            term: displayTerm,
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
        learnedWordsPrefsKey,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  void _scheduleRetry(HangulCharacter character, TrainingMode mode) {
    final exists = _retryQueue.any(
      (entry) =>
          entry.character.symbol == character.symbol &&
          entry.mode.given == mode.given &&
          entry.mode.choose == mode.choose,
    );
    if (exists) return;

    final trackingSymbol = _questionTrackingSymbol();
    final retryMode = _pickRetryMode(character, mode, trackingSymbol);
    final availableAfter = _questionsServed + _minRetryGap;
    _retryQueue.add(
      _RetryQuestion(
        character: character,
        mode: retryMode,
        availableAfter: availableAfter,
        trackingSymbol: trackingSymbol,
      ),
    );
  }

  TrainingMode _pickRetryMode(
    HangulCharacter character,
    TrainingMode failedMode,
    String trackingSymbol,
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
      final key = '$trackingSymbol|${mode.given.index}-${mode.choose.index}';
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
    if (readyIndex != -1) return _retryQueue.removeAt(readyIndex);
    if (force) return _retryQueue.removeAt(0);
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
      _currentTrackingSymbol = null;
      _startNewQuestion();
    });
    _sessionLogged = false;
    _logSessionStart(includesWordPool: _includesWordPool);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: CustomLiquidGlassDialog(
            title: Text(AppLocalizations.of(context)!.trainingComplete),
            content: Text(
              AppLocalizations.of(
                context,
              )!.resultSummary(_totalCorrect, _globalWrongCount),
            ),
            actions: [
              CustomLiquidGlassDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  _restartSession();
                },
                child: Text(AppLocalizations.of(context)!.tryAgain),
              ),
              CustomLiquidGlassDialogAction(
                isConfirmationBlue: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.goHome),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdDialog({VoidCallback? onClosed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('잠깐 숨 돌려요'),
          content: const Text('집중력이 흔들릴 땐 짧은 광고나 스트레칭으로 리셋해주세요.'),
          actions: [
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () {
                Navigator.pop(context);
                onClosed?.call();
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInterstitialAd({
    required String placement,
    VoidCallback? onCompleted,
  }) {
    InterstitialAd.load(
      adUnitId: AdIDs.interstitial(placement),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onCompleted?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial show failed ($placement): $error');
              ad.dispose();
              _showAdDialog(onClosed: onCompleted);
            },
          );
          AnalyticsService.instance.trackAdShown(placement);
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial load failed ($placement): $error');
          _showAdDialog(onClosed: onCompleted);
        },
      ),
    );
  }

  void _showExitDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: Text(l10n.trainingExitTitle),
          content: Text(l10n.trainingExitMessage),
          actions: [
            CustomLiquidGlassDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                _handleExitConfirmed();
              },
              child: Text(l10n.trainingExitLeave),
            ),
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.trainingExitStay),
            ),
          ],
        ),
      ),
    );
  }

  void _handleExitConfirmed() {
    AnalyticsService.instance.trackTrainingExit(
      progress: _totalCorrect,
      mistakes: _globalWrongCount,
    );
    _showInterstitialAd(
      placement: _adPlacementExit,
      onCompleted: () {
        if (!mounted) return;
        Navigator.of(context).pop();
      },
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
        ? AppLocalizations.of(context)!.checkAnswer
        : (_totalCorrect >= _sessionGoal
              ? AppLocalizations.of(context)!.trainingComplete
              : AppLocalizations.of(context)!.nextQuestion);
    final VoidCallback? primaryAction = !_showResult
        ? (canCheck ? _checkAnswer : null)
        : (canAdvance ? _nextQuestion : null);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
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
                          CupertinoIcons.speaker_2,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 18.0;
                      final itemCount = _options.length;

                      // Start with 3 columns (2 rows for 6 items)
                      int columns = 3;
                      int rows = (itemCount + columns - 1) ~/ columns;

                      final totalHorizontalSpacing = (columns - 1) * spacing;
                      final totalVerticalSpacing = (rows - 1) * spacing;

                      final cardWidth =
                          (constraints.maxWidth - totalHorizontalSpacing) /
                          (columns == 0 ? 1 : columns);
                      final cardHeight =
                          (constraints.maxHeight - totalVerticalSpacing) /
                          (rows == 0 ? 1 : rows);
                      // Cap per-card height so tiles don't stretch excessively tall
                      const double maxCardHeight = 140.0;
                      final measuredCardHeight = cardHeight.clamp(
                        0.0,
                        maxCardHeight,
                      );

                      // Measure text to see if it would overflow the computed card size.
                      final textScaler = MediaQuery.textScalerOf(context);
                      final baseFontSize =
                          (LearnHangulTheme.typographyOf(
                            context,
                          ).heading.fontSize ??
                          16.0);
                      final textStyle = LearnHangulTheme.typographyOf(
                        context,
                      ).heading.copyWith(fontSize: baseFontSize);

                      bool needsMoreHorizontalSpace = false;
                      for (final option in _options) {
                        final label = _formatOptionLabel(option);
                        final tp = TextPainter(
                          text: TextSpan(
                            text: label,
                            style: textStyle.copyWith(
                              fontSize: textScaler.scale(baseFontSize),
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                          maxLines: 10,
                        );
                        // Give a small padding allowance within the card.
                        final available = (cardWidth - 16.0).clamp(
                          10.0,
                          double.infinity,
                        );
                        tp.layout(maxWidth: available);
                        // Compare against the capped measured height so extremely
                        // tall available space doesn't cause oversized tiles.
                        if (tp.height > (measuredCardHeight - 16.0)) {
                          needsMoreHorizontalSpace = true;
                          break;
                        }
                      }

                      if (needsMoreHorizontalSpace) {
                        columns = 2; // switch to 3 rows x 2 columns layout
                      }

                      rows = (itemCount + columns - 1) ~/ columns;
                      final computedTotalHorizontalSpacing =
                          (columns - 1) * spacing;
                      final computedTotalVerticalSpacing = (rows - 1) * spacing;
                      final computedCardWidth =
                          (constraints.maxWidth -
                              computedTotalHorizontalSpacing) /
                          (columns == 0 ? 1 : columns);
                      final computedCardHeight =
                          (constraints.maxHeight -
                              computedTotalVerticalSpacing) /
                          (rows == 0 ? 1 : rows);

                      // Cap the final card height to avoid very tall tiles when the
                      // grid area is large; use this capped height to compute aspect ratio.
                      final usedCardHeight = computedCardHeight.clamp(
                        0.0,
                        maxCardHeight,
                      );

                      final childAspectRatio =
                          computedCardWidth /
                          (usedCardHeight == 0 ? 1 : usedCardHeight);

                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: childAspectRatio.isFinite
                              ? childAspectRatio
                              : 1.1,
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
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
    final displayLabel = _formatOptionLabel(option);

    Color background = palette.surface;
    Color border = palette.outline;
    Color foreground = palette.primaryText;

    if (_showResult) {
      if (isCorrectAnswer) {
        background = palette.success.withValues(alpha: 0.15);
        border = palette.success;
        foreground = palette.success;
      } else if (isSelected && !_isCorrect) {
        background = palette.danger.withValues(alpha: 0.15);
        border = palette.danger;
        foreground = palette.danger;
      }
    } else if (isSelected) {
      background = palette.info.withValues(alpha: 0.12);
      border = palette.info.withValues(alpha: 0.5);
      foreground = palette.info;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(28),
        onPressed: onTap,
        child: Center(
          child: showIcon
              ? Icon(CupertinoIcons.speaker_2, color: foreground, size: 34)
              : Text(
                  displayLabel,
                  textAlign: TextAlign.center,
                  style: typography.heading.copyWith(color: foreground),
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
    required this.trackingSymbol,
  });

  final HangulCharacter character;
  final TrainingMode mode;
  final String trackingSymbol;
  int availableAfter;
}
