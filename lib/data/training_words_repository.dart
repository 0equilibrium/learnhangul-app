import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models.dart';

const String trainingWordsAssetPath = 'assets/data/training_words.json';

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

class TrainingWordData {
  TrainingWordData._({
    required this.openSyllableWords,
    required this.batchimWords,
    required this.consonantTrainingWordPool,
    required this.consonantOpenWordSymbols,
    required this.consonantBatchimWordSymbols,
    required this.trainingWordBySymbol,
    required this.batchimOnlyQuestionWords,
  });

  factory TrainingWordData({
    required List<HangulCharacter> openSyllableWords,
    required List<HangulCharacter> batchimWords,
  }) {
    final pool = [...openSyllableWords, ...batchimWords];
    final openSymbols = {for (final word in openSyllableWords) word.symbol};
    final batchimSymbols = {for (final word in batchimWords) word.symbol};
    final wordMap = {for (final word in pool) word.symbol: word};
    final batchimQuestions = {
      for (final entry in batchimOnlyWordSymbolMap.entries)
        entry.key: [
          for (final symbol in entry.value)
            if (wordMap.containsKey(symbol)) wordMap[symbol]!,
        ],
    };

    return TrainingWordData._(
      openSyllableWords: openSyllableWords,
      batchimWords: batchimWords,
      consonantTrainingWordPool: pool,
      consonantOpenWordSymbols: openSymbols,
      consonantBatchimWordSymbols: batchimSymbols,
      trainingWordBySymbol: wordMap,
      batchimOnlyQuestionWords: batchimQuestions,
    );
  }

  final List<HangulCharacter> openSyllableWords;
  final List<HangulCharacter> batchimWords;
  final List<HangulCharacter> consonantTrainingWordPool;
  final Set<String> consonantOpenWordSymbols;
  final Set<String> consonantBatchimWordSymbols;
  final Map<String, HangulCharacter> trainingWordBySymbol;
  final Map<String, List<HangulCharacter>> batchimOnlyQuestionWords;
}

class TrainingWordRepository {
  TrainingWordRepository({this.assetPath = trainingWordsAssetPath});

  final String assetPath;
  TrainingWordData? _cache;

  Future<TrainingWordData> load() async {
    if (_cache != null) return _cache!;
    final jsonString = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> jsonMap =
        jsonDecode(jsonString) as Map<String, dynamic>;
    final openWords = _parseList(jsonMap['openSyllable']);
    final batchimWords = _parseList(jsonMap['batchim']);
    _cache = TrainingWordData(
      openSyllableWords: openWords,
      batchimWords: batchimWords,
    );
    return _cache!;
  }

  List<HangulCharacter> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => HangulCharacter.fromJson(
            item,
            typeOverride: HangulCharacterType.consonant,
          ),
        )
        .toList(growable: false);
  }
}

final TrainingWordRepository trainingWordRepository = TrainingWordRepository();
