import '../data/training_words_repository.dart';

// Preferences key for learned words (public so multiple screens can use it)
const String learnedWordsPrefsKey = 'learned_words_v1';

class LearnedWordEntry {
  const LearnedWordEntry({
    required this.symbol,
    required this.term,
    required this.romanization,
    this.meaning,
    required this.seenAt,
    required this.timesSeen,
  });

  final String symbol;
  final String term;
  final String romanization;
  final String? meaning;
  final DateTime seenAt;
  final int timesSeen;

  factory LearnedWordEntry.fromJson(Map<String, dynamic> json) {
    final symbol = json['symbol'] as String? ?? json['term'] as String;
    final termRaw = json['term'] as String? ?? symbol;
    return LearnedWordEntry(
      symbol: symbol,
      term: sanitizeTrainingWordSymbol(termRaw),
      romanization: json['romanization'] as String,
      meaning: json['meaning'] as String?,
      seenAt: DateTime.parse(json['seenAt'] as String),
      timesSeen: json['timesSeen'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'term': term,
    'romanization': romanization,
    'meaning': meaning,
    'seenAt': seenAt.toIso8601String(),
    'timesSeen': timesSeen,
  };

  LearnedWordEntry copyWith({DateTime? seenAt, int? timesSeen}) {
    return LearnedWordEntry(
      symbol: symbol,
      term: term,
      romanization: romanization,
      meaning: meaning,
      seenAt: seenAt ?? this.seenAt,
      timesSeen: timesSeen ?? this.timesSeen,
    );
  }
}

// Hangul composition helpers (made public for use in training)
const List<String> choseongList = [
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

const List<String> jungseongList = [
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

const List<String> jongseongList = [
  '',
  'ㄱ',
  'ㄲ',
  'ㄳ',
  'ㄴ',
  'ㄵ',
  'ㄶ',
  'ㄷ',
  'ㄹ',
  'ㄺ',
  'ㄻ',
  'ㄼ',
  'ㄽ',
  'ㄾ',
  'ㄿ',
  'ㅀ',
  'ㅁ',
  'ㅂ',
  'ㅄ',
  'ㅅ',
  'ㅆ',
  'ㅇ',
  'ㅈ',
  'ㅊ',
  'ㅋ',
  'ㅌ',
  'ㅍ',
  'ㅎ',
];

String composeSyllable(String initialJamo, String medialJamo) {
  final ci = choseongList.indexOf(initialJamo);
  final mi = jungseongList.indexOf(medialJamo);
  if (ci == -1 || mi == -1) return '';
  const base = 0xAC00;
  final code = base + (ci * 21 + mi) * 28 + 0;
  return String.fromCharCode(code);
}

bool isHangulJamo(String text) {
  if (text.runes.length != 1) return false;
  final code = text.runes.first;
  const jamoStart = 0x3131;
  const jamoEnd = 0x318E;
  const choseongStart = 0x1100;
  const choseongEnd = 0x11FF;
  return (code >= jamoStart && code <= jamoEnd) ||
      (code >= choseongStart && code <= choseongEnd);
}

bool hasBatchim(String text) {
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

String approximateBatchimPronunciation(String text) {
  const base = 0xAC00;
  final buffer = StringBuffer();
  bool changed = false;
  for (final rune in text.runes) {
    if (rune < base || rune > 0xD7A3) {
      buffer.writeCharCode(rune);
      continue;
    }
    final relative = rune - base;
    final choseongIndex = relative ~/ (21 * 28);
    final jungseongIndex = (relative % (21 * 28)) ~/ 28;
    final jongseongIndex = relative % 28;
    final jong = jongseongList[jongseongIndex];
    final override = batchimOnlyPronunciationOverrides[jong];
    if (override == null) {
      buffer.writeCharCode(rune);
      continue;
    }
    final overrideIndex = jongseongList.indexOf(override);
    final newJongIndex = overrideIndex == -1 ? jongseongIndex : overrideIndex;
    final code = base + (choseongIndex * 21 + jungseongIndex) * 28 + newJongIndex;
    buffer.writeCharCode(code);
    changed = true;
  }
  if (!changed) return text;
  return buffer.toString();
}

String? batchimOnlyPronunciationKey(String text) {
  final approximated = approximateBatchimPronunciation(text);
  if (approximated == text) return null;
  return approximated;
}
