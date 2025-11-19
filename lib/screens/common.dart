import '../models.dart';

// Preferences key for learned words (public so multiple screens can use it)
const String learnedWordsPrefsKey = 'learned_words_v1';

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

final Map<String, HangulCharacter> trainingWordBySymbol = {
  for (final word in consonantTrainingWordPool) word.symbol: word,
};

final Map<String, List<HangulCharacter>> batchimOnlyQuestionWords = {
  for (final entry in batchimOnlyWordSymbolMap.entries)
    entry.key: [
      for (final symbol in entry.value)
        if (trainingWordBySymbol.containsKey(symbol))
          trainingWordBySymbol[symbol]!,
    ],
};

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
