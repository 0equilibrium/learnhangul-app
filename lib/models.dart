class HangulSection {
  const HangulSection({
    required this.title,
    required this.description,
    required this.characters,
  });

  final String title;
  final String description;
  final List<HangulCharacter> characters;
}

enum HangulCharacterType { consonant, vowel }

class HangulCharacter {
  const HangulCharacter({
    required this.symbol,
    required this.name,
    required this.romanization,
    required this.example,
    this.secondExample,
    required this.type,
    this.meaning,
    // Optional part-of-speech (품사) when available from vocab lists.
    this.pos,
  });

  final String symbol;
  final String name;
  final String romanization;
  // Primary example (legacy field).
  final String example;
  // Optional second example to show two examples in the UI.
  final String? secondExample;
  final HangulCharacterType type;
  final String? meaning;
  final String? pos;

  factory HangulCharacter.fromJson(
    Map<String, dynamic> json, {
    HangulCharacterType? typeOverride,
  }) {
    final typeValue = json['type'];
    HangulCharacterType resolvedType;
    if (typeOverride != null) {
      resolvedType = typeOverride;
    } else if (typeValue is String) {
      resolvedType = HangulCharacterType.values.firstWhere(
        (value) => value.name == typeValue,
        orElse: () => HangulCharacterType.consonant,
      );
    } else {
      resolvedType = HangulCharacterType.consonant;
    }

    return HangulCharacter(
      symbol: json['symbol'] as String,
      name: (json['name'] as String?) ?? (json['symbol'] as String),
      romanization: json['romanization'] as String? ?? '',
      example: json['example'] as String? ?? '',
      secondExample: json['secondExample'] as String?,
      type: resolvedType,
      meaning: json['meaning'] as String?,
      pos: json['pos'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'romanization': romanization,
    'example': example,
    'secondExample': secondExample,
    'type': type.name,
    'meaning': meaning,
    'pos': pos,
  };
}

const List<String> consonantPracticeIdeas = [
  '모음 ㅏ/ㅗ/ㅣ와 빠르게 조합하며 음절 리듬을 만들어 보세요.',
  '받침 위치에서 소리가 어떻게 닫히는지 천천히 들어보세요.',
  '비슷한 영어 자음과 비교해 혀와 입술의 위치를 메모하세요.',
];

const List<HangulSection> consonantSections = [
  HangulSection(
    title: '기본 자음',
    description: '단어의 뼈대를 만드는 14개의 기본 자음입니다.',
    characters: [
      HangulCharacter(
        symbol: 'ㄱ',
        name: '기역',
        romanization: 'g',
        example: '가방 (ga-bang, bag)',
        secondExample: '고기 (go-gi, meat)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄴ',
        name: '니은',
        romanization: 'n',
        example: '나무 (na-mu, tree)',
        secondExample: '눈 (nun, snow)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄷ',
        name: '디귿',
        romanization: 'd',
        example: '달 (dal, moon)',
        secondExample: '도시 (do-si, city)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄹ',
        name: '리을',
        romanization: 'r / l',
        example: '라면 (ra-myeon, ramen)',
        secondExample: '리본 (ri-bon, ribbon)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅁ',
        name: '미음',
        romanization: 'm',
        example: '물 (mul, water)',
        secondExample: '모자 (mo-ja, hat)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅂ',
        name: '비읍',
        romanization: 'b',
        example: '바람 (ba-ram, wind)',
        secondExample: '바나나 (ba-na-na, banana)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅅ',
        name: '시옷',
        romanization: 's',
        example: '사과 (sa-gwa, apple)',
        secondExample: '사진 (sa-jin, photo)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅇ',
        name: '이응',
        romanization: 'ng / silent',
        example: '아침 (a-chim, morning)',
        secondExample: '오이 (o-i, cucumber)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅈ',
        name: '지읒',
        romanization: 'j',
        example: '자전거 (ja-jeon-geo, bicycle)',
        secondExample: '주스 (ju-seu, juice)',
        type: HangulCharacterType.consonant,
      ),
    ],
  ),
  HangulSection(
    title: '격음 자음',
    description: '강한 호흡으로 발음하는 격음 자음입니다.',
    characters: [
      HangulCharacter(
        symbol: 'ㅋ',
        name: '키읔',
        romanization: 'k',
        example: '카메라 (ka-me-ra, camera)',
        secondExample: '콜라 (kol-la, cola)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅌ',
        name: '티읕',
        romanization: 't',
        example: '토끼 (to-kki, rabbit)',
        secondExample: '탁자 (tak-ja, table)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅍ',
        name: '피읖',
        romanization: 'p',
        example: '포도 (po-do, grape)',
        secondExample: '편지 (pyeon-ji, letter)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅊ',
        name: '치읓',
        romanization: 'ch',
        example: '친구 (chin-gu, friend)',
        secondExample: '채소 (chae-so, vegetable)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅎ',
        name: '히읗',
        romanization: 'h',
        example: '하늘 (ha-neul, sky)',
        secondExample: '학교 (hak-kyo, school)',
        type: HangulCharacterType.consonant,
      ),
    ],
  ),
  HangulSection(
    title: '쌍자음',
    description: '성대를 긴장시켜 내는 된소리 자음으로, 짧고 단단하게 발음합니다.',
    characters: [
      HangulCharacter(
        symbol: 'ㄲ',
        name: '쌍기역',
        romanization: 'gg',
        example: '까치 (gga-chi, magpie)',
        secondExample: '꽂 (ggot, flower)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄸ',
        name: '쌍디귿',
        romanization: 'dd',
        example: '떡 (ddeok, rice cake)',
        secondExample: '또 (tto, again)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅃ',
        name: '쌍비읍',
        romanization: 'bb',
        example: '빵 (bbang, bread)',
        secondExample: '빠르다 (ppa-reu-da, fast)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅆ',
        name: '쌍시옷',
        romanization: 'ss',
        example: '쌀 (ssal, rice grain)',
        secondExample: '씻다 (ssit-da, wash)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅉ',
        name: '쌍지읒',
        romanization: 'jj',
        example: '짜장 (jja-jang, black bean sauce)',
        secondExample: '짧다 (jjalb-da, short)',
        type: HangulCharacterType.consonant,
      ),
    ],
  ),
  HangulSection(
    title: '겹받침 자음',
    description: '받침에서만 등장하는 자음 조합으로, 뒤에 오는 음절에 따라 소리가 달라집니다.',
    characters: [
      HangulCharacter(
        symbol: 'ㄳ',
        name: '기역시옷',
        romanization: 'gs',
        example: '값 (gap, price)',
        secondExample: '넋 (neok, spirit)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄵ',
        name: '니은지읒',
        romanization: 'nj',
        example: '앉다 (an-da, sit)',
        secondExample: '앉아 (an-ja, sit)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄶ',
        name: '니은히읗',
        romanization: 'nh',
        example: '많다 (man-ta, many)',
        secondExample: '많이 (man-hi, much)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄺ',
        name: '리을기역',
        romanization: 'lg',
        example: '읽다 (ik-tta, read)',
        secondExample: '읽어 (il-geo, read)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄻ',
        name: '리을미음',
        romanization: 'lm',
        example: '삶 (sam, life)',
        secondExample: '삶다 (sam-da, boil)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄼ',
        name: '리을비읍',
        romanization: 'lb',
        example: '밟다 (bap-tta, step on)',
        secondExample: '넓다 (neolb-da, wide)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄽ',
        name: '리을시옷',
        romanization: 'ls',
        example: '곬 (gol, passage)',
        secondExample: '외곬 (oe-gol, passage)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄾ',
        name: '리을티읕',
        romanization: 'lt',
        example: '훑다 (hut-tta, scan)',
        secondExample: '훑어 (hut-eo, scan)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㄿ',
        name: '리을피읖',
        romanization: 'lp',
        example: '읊다 (eup-tta, recite)',
        secondExample: '읊어 (eup-eo, recite)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅀ',
        name: '리을히읗',
        romanization: 'lh',
        example: '싫다 (sil-ta, dislike)',
        secondExample: '싫어 (silh-eo, dislike)',
        type: HangulCharacterType.consonant,
      ),
      HangulCharacter(
        symbol: 'ㅄ',
        name: '비읍시옷',
        romanization: 'bs',
        example: '값어치 (gap-eo-chi, value)',
        secondExample: '값 (gap, price)',
        type: HangulCharacterType.consonant,
      ),
    ],
  ),
];

const List<HangulSection> vowelSections = [
  HangulSection(
    title: '',
    description: '',
    characters: [
      HangulCharacter(
        symbol: 'ㅏ',
        name: '아',
        romanization: 'a',
        example: '바다 (ba-da, sea)',
        secondExample: '아기 (a-gi, baby)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅓ',
        name: '어',
        romanization: 'eo',
        example: '서울 (seo-ul, Seoul)',
        secondExample: '엄마 (eom-ma, mom)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅗ',
        name: '오',
        romanization: 'o',
        example: '고모 (go-mo, aunt)',
        secondExample: '오이 (o-i, cucumber)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅜ',
        name: '우',
        romanization: 'u',
        example: '우산 (u-san, umbrella)',
        secondExample: '우유 (u-yu, milk)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅡ',
        name: '으',
        romanization: 'eu',
        example: '그늘 (geu-neul, shade)',
        secondExample: '의자 (ui-ja, chair)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅣ',
        name: '이',
        romanization: 'i',
        example: '미소 (mi-so, smile)',
        secondExample: '이름 (i-reum, name)',
        type: HangulCharacterType.vowel,
      ),
    ],
  ),
  HangulSection(
    title: '',
    description: '',
    characters: [
      HangulCharacter(
        symbol: 'ㅐ',
        name: '애',
        romanization: 'ae',
        example: '배 (bae, pear/boat)',
        secondExample: '애인 (ae-in, lover)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅔ',
        name: '에',
        romanization: 'e',
        example: '네 (ne, you)',
        secondExample: '에어컨 (e-eo-keon, air conditioner)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅚ',
        name: '외',
        romanization: 'oe',
        example: '외국 (oe-guk, foreign country)',
        secondExample: '외출 (oe-chul, outing)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅟ',
        name: '위',
        romanization: 'wi',
        example: '위험 (wi-heom, danger)',
        secondExample: '위치 (wi-chi, location)',
        type: HangulCharacterType.vowel,
      ),
    ],
  ),
  HangulSection(
    title: '',
    description: '',
    characters: [
      HangulCharacter(
        symbol: 'ㅑ',
        name: '야',
        romanization: 'ya',
        example: '야구 (ya-gu, baseball)',
        secondExample: '야채 (ya-chae, vegetable)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅒ',
        name: '얘',
        romanization: 'yae',
        example: '얘기 (yae-gi, talk)',
        secondExample: '얘 (yae, kid)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅕ',
        name: '여',
        romanization: 'yeo',
        example: '여우 (yeo-u, fox)',
        secondExample: '여름 (yeo-reum, summer)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅖ',
        name: '예',
        romanization: 'ye',
        example: '예 (ye, yes)',
        secondExample: '예약 (ye-yak, reservation)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅛ',
        name: '요',
        romanization: 'yo',
        example: '요리 (yo-ri, cooking)',
        secondExample: '요가 (yo-ga, yoga)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅠ',
        name: '유',
        romanization: 'yu',
        example: '유리 (yu-ri, glass)',
        secondExample: '유적 (yu-jeok, ruins)',
        type: HangulCharacterType.vowel,
      ),
    ],
  ),
  HangulSection(
    title: '',
    description: '',
    characters: [
      HangulCharacter(
        symbol: 'ㅘ',
        name: '와',
        romanization: 'wa',
        example: '과일 (gwa-il, fruit)',
        secondExample: '와인 (wa-in, wine)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅙ',
        name: '왜',
        romanization: 'wae',
        example: '왜 (wae, why)',
        secondExample: '왜곡 (wae-gok, distortion)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅝ',
        name: '워',
        romanization: 'wo',
        example: '원 (won, origin/currency)',
        secondExample: '워터 (wo-teo, water (loanword))',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅞ',
        name: '웨',
        romanization: 'we',
        example: '웨딩 (we-ding, wedding)',
        secondExample: '웹사이트 (wep-sa-i-teu, website)',
        type: HangulCharacterType.vowel,
      ),
      HangulCharacter(
        symbol: 'ㅢ',
        name: '의',
        romanization: 'ui',
        example: '의사 (ui-sa, doctor)',
        secondExample: '의자 (ui-ja, chair)',
        type: HangulCharacterType.vowel,
      ),
    ],
  ),
];
