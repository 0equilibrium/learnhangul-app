import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

enum TopikWordLevel {
  topik1(1),
  topik2(2),
  topik3(3),
  topik4(4),
  topik5(5),
  topik6(6);

  const TopikWordLevel(this.number);
  final int number;

  String get assetPath => 'assets/topik_words/$number급_어휘_통합.csv';
  String get storageValue => 'topik_$number';
}

class TopikWordLevelPreferences {
  const TopikWordLevelPreferences._();

  static const String _prefsKey = 'topik_word_level';

  static Future<TopikWordLevel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null) return TopikWordLevel.topik1;
    return TopikWordLevel.values.firstWhere(
      (level) => level.storageValue == stored,
      orElse: () => TopikWordLevel.topik1,
    );
  }

  static Future<void> save(TopikWordLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, level.storageValue);
  }
}

const Map<String, String> consonantSoundOverrides = {
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

const Set<String> batchimOnlyConsonants = {
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
};

const Map<String, List<String>> batchimOnlyWordSymbolMap = {
  'ㄳ': ['삯', '넋', '몫'],
  'ㄵ': ['앉다', '앉는', '앉고'],
  'ㄶ': ['않다', '않는', '많다'],
  'ㄺ': ['닭', '읽다', '맑다'],
  'ㄻ': ['삶다', '닮다', '옮다'],
  'ㄼ': ['밟다', '밟는', '넓다', '넓은', '넓고', '짧다'],
  'ㄽ': ['곬'],
  'ㄾ': ['핥다', '핥는', '핥고', '훑다'],
  'ㄿ': ['읊다', '읊는', '읊고'],
  'ㅀ': ['앓다', '앓고', '앓는', '싫다', '싫어'],
  'ㅄ': ['값', '값어치', '없다', '없어'],
};

const Map<String, String> batchimOnlyPronunciationOverrides = {
  'ㄳ': 'ㄱ',
  'ㄵ': 'ㄴ',
  'ㄶ': 'ㄴ',
  'ㄺ': 'ㄱ',
  'ㄻ': 'ㅁ',
  'ㄼ': 'ㄹ',
  'ㄽ': 'ㄹ',
  'ㄾ': 'ㄹ',
  'ㄿ': 'ㅂ',
  'ㅀ': 'ㄹ',
  'ㅄ': 'ㅂ',
};

const List<String> _choseongRomanizations = [
  'g',
  'kk',
  'n',
  'd',
  'tt',
  'r',
  'm',
  'b',
  'pp',
  's',
  'ss',
  '',
  'j',
  'jj',
  'ch',
  'k',
  't',
  'p',
  'h',
];

const List<String> _jungseongRomanizations = [
  'a',
  'ae',
  'ya',
  'yae',
  'eo',
  'e',
  'yeo',
  'ye',
  'o',
  'wa',
  'wae',
  'oe',
  'yo',
  'u',
  'wo',
  'we',
  'wi',
  'yu',
  'eu',
  'ui',
  'i',
];

const List<String> _jongseongRomanizations = [
  '',
  'k',
  'k',
  'k',
  'n',
  'n',
  'n',
  't',
  'l',
  'lk',
  'lm',
  'lp',
  'ls',
  'lt',
  'lp',
  'lh',
  'm',
  'p',
  'p',
  't',
  't',
  'ng',
  't',
  't',
  'k',
  't',
  'p',
  't',
];

String sanitizeTrainingWordSymbol(String symbol) {
  // Keep only Hangul syllables (가-힣). This removes numeric suffixes
  // and other punctuation so variants like "문화적01" or
  // "문화적01∙ 문화적02" turn into a clean name: "문화적".
  final onlyHangul = symbol.replaceAll(RegExp(r'[^가-힣]'), '');
  return onlyHangul;
}

String romanizeHangul(String text) {
  final buffer = StringBuffer();
  final current = <String>[];

  void flush() {
    if (current.isEmpty) return;
    buffer.write(current.join('-'));
    current.clear();
  }

  for (final rune in text.runes) {
    if (_isHangulSyllable(rune)) {
      current.add(_romanizeSyllable(rune));
    } else {
      flush();
      buffer.write(String.fromCharCode(rune));
    }
  }
  flush();

  final result = buffer.toString();
  return result.trim();
}

bool _isHangulSyllable(int rune) => rune >= 0xAC00 && rune <= 0xD7A3;

String _romanizeSyllable(int rune) {
  const base = 0xAC00;
  final relative = rune - base;
  final choseongIndex = relative ~/ (21 * 28);
  final jungseongIndex = (relative % (21 * 28)) ~/ 28;
  final jongseongIndex = relative % 28;
  final initial = _choseongRomanizations[choseongIndex];
  final medial = _jungseongRomanizations[jungseongIndex];
  final finalPart = _jongseongRomanizations[jongseongIndex];
  return initial + medial + finalPart;
}

Iterable<String> _splitVariants(String raw) sync* {
  // Split on slashes and common variant separators such as middle dots
  // used in the CSV (e.g. '∙', '·', '•') and commas.
  final separators = RegExp(r"[\/∙·•,]+");
  for (final part in raw.split(separators)) {
    final value = part.trim();
    if (value.isEmpty) continue;
    yield value;
  }
}

HangulCharacter? _buildBatchimFallbackWord(String raw) {
  final sanitized = sanitizeTrainingWordSymbol(raw);
  if (sanitized.isEmpty) return null;
  return HangulCharacter(
    symbol: raw,
    name: sanitized,
    romanization: romanizeHangul(sanitized),
    example: '',
    type: HangulCharacterType.consonant,
  );
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

class TrainingWordData {
  TrainingWordData._({
    required this.openSyllableWords,
    required this.batchimWords,
    required this.consonantTrainingWordPool,
    required this.consonantOpenWordSymbols,
    required this.consonantBatchimWordSymbols,
    required this.trainingWordBySymbol,
    required this.batchimOnlyQuestionWords,
    required this.batchimOnlyWordPool,
  });

  factory TrainingWordData({
    required List<HangulCharacter> openSyllableWords,
    required List<HangulCharacter> batchimWords,
  }) {
    final pool = [...openSyllableWords, ...batchimWords];
    final openSymbols = {for (final word in openSyllableWords) word.symbol};
    final batchimSymbols = {for (final word in batchimWords) word.symbol};
    final wordMap = {for (final word in pool) word.symbol: word};
    final batchimQuestions = <String, List<HangulCharacter>>{};
    final batchimWordPool = <HangulCharacter>[];
    for (final entry in batchimOnlyWordSymbolMap.entries) {
      final replacements = <HangulCharacter>[];
      for (final symbol in entry.value) {
        final existing = wordMap[symbol];
        if (existing != null) {
          replacements.add(existing);
          continue;
        }
        final fallback = _buildBatchimFallbackWord(symbol);
        if (fallback != null) replacements.add(fallback);
      }
      if (replacements.isNotEmpty) {
        batchimQuestions[entry.key] = replacements;
        batchimWordPool.addAll(replacements);
      }
    }

    return TrainingWordData._(
      openSyllableWords: openSyllableWords,
      batchimWords: batchimWords,
      consonantTrainingWordPool: pool,
      consonantOpenWordSymbols: openSymbols,
      consonantBatchimWordSymbols: batchimSymbols,
      trainingWordBySymbol: wordMap,
      batchimOnlyQuestionWords: batchimQuestions,
      batchimOnlyWordPool: batchimWordPool,
    );
  }

  final List<HangulCharacter> openSyllableWords;
  final List<HangulCharacter> batchimWords;
  final List<HangulCharacter> consonantTrainingWordPool;
  final Set<String> consonantOpenWordSymbols;
  final Set<String> consonantBatchimWordSymbols;
  final Map<String, HangulCharacter> trainingWordBySymbol;
  final Map<String, List<HangulCharacter>> batchimOnlyQuestionWords;
  final List<HangulCharacter> batchimOnlyWordPool;
}

class TrainingWordRepository {
  TrainingWordRepository();

  final Map<TopikWordLevel, TrainingWordData> _cache = {};

  Future<TrainingWordData> load({required TopikWordLevel level}) async {
    final cached = _cache[level];
    if (cached != null) return cached;
    final contents = await rootBundle.loadString(level.assetPath);
    final data = _parseCsv(contents);
    _cache[level] = data;
    return data;
  }

  void clearLevel(TopikWordLevel level) => _cache.remove(level);

  void clear() => _cache.clear();

  TrainingWordData _parseCsv(String contents) {
    final normalized = contents.replaceAll('\r\n', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalized);
    if (rows.isEmpty) {
      return TrainingWordData(
        openSyllableWords: const [],
        batchimWords: const [],
      );
    }

    final openWords = <HangulCharacter>[];
    final batchimWords = <HangulCharacter>[];

    for (final row in rows.skip(1)) {
      if (row.isEmpty) continue;
      final vocabularyRaw = row.length > 2
          ? row[2]?.toString().trim() ?? ''
          : '';
      if (vocabularyRaw.isEmpty) continue;
      final posRaw = row.length > 3 ? row[3]?.toString().trim() ?? '' : '';
      final guideRaw = row.length > 4 ? row[4]?.toString().trim() ?? '' : '';
      final example = guideRaw.isEmpty ? null : guideRaw;
      // Track sanitized variants seen for this row to avoid duplicates
      final seenSanitized = <String>{};
      for (final variant in _splitVariants(vocabularyRaw)) {
        final sanitized = sanitizeTrainingWordSymbol(variant);
        if (sanitized.isEmpty) continue;
        if (!seenSanitized.add(sanitized)) continue;
        final romanization = romanizeHangul(sanitized);
        final character = HangulCharacter(
          symbol: variant,
          name: sanitized,
          romanization: romanization,
          example: example ?? '',
          type: HangulCharacterType.consonant,
          meaning: null,
          pos: posRaw.isEmpty ? null : posRaw,
        );
        if (_hasBatchim(sanitized)) {
          batchimWords.add(character);
        } else {
          openWords.add(character);
        }
      }
    }

    return TrainingWordData(
      openSyllableWords: openWords,
      batchimWords: batchimWords,
    );
  }
}

final TrainingWordRepository trainingWordRepository = TrainingWordRepository();
