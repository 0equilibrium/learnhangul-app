import '../models.dart';

// Preferences key for learned words (public so multiple screens can use it)
const String learnedWordsPrefsKey = 'learned_words_v1';

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
