// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'LearnHangul';

  @override
  String get learnHangul => 'LearnHangul';

  @override
  String get vowels => '모음';

  @override
  String get consonants => '자음';

  @override
  String get train => '훈련하기';

  @override
  String get checkAnswer => '정답 확인';

  @override
  String get nextQuestion => '다음 문제';

  @override
  String get trainingComplete => '훈련 완료!';

  @override
  String get trainingExitTitle => '훈련 중단';

  @override
  String get trainingExitMessage => '지금 나가면 훈련 기록이 저장되지 않아요. 그래도 나가시겠어요?';

  @override
  String get trainingExitLeave => '나가기';

  @override
  String get trainingExitStay => '훈련하기';

  @override
  String resultSummary(Object correct, Object wrong) {
    return '총 맞힌 수: $correct, 틀린 수: $wrong';
  }

  @override
  String get goHome => '홈으로 가기';

  @override
  String get tryAgain => '한번 더 풀기';

  @override
  String get exampleWord => '예시 단어';

  @override
  String get exampleWordTooltip => '예시 단어 발음 듣기';

  @override
  String get nameLabel => '이름';

  @override
  String get romanizationLabel => '로마자';

  @override
  String get settings => '설정';

  @override
  String get learning => '학습';

  @override
  String get eveningReminder => '저녁 리마인더';

  @override
  String get eveningReminderSubtitle => '매일 19시에 학습 알림 받기';

  @override
  String get ttsHints => 'TTS 힌트';

  @override
  String get ttsHintsSubtitle => '문제를 풀 때 자동으로 음성 힌트 듣기';

  @override
  String get topikLevelTileTitle => '학습 단어 수준';

  @override
  String get topikLevelTileSubtitle => '훈련하기에서 사용할 TOPIK 어휘 세트를 선택하세요.';

  @override
  String get topikLevelSheetTitle => 'TOPIK 레벨 선택';

  @override
  String get topikLevel1Label => 'TOPIK 레벨 1 (쉬움)';

  @override
  String get topikLevel2Label => 'TOPIK 레벨 2';

  @override
  String get topikLevel3Label => 'TOPIK 레벨 3';

  @override
  String get topikLevel4Label => 'TOPIK 레벨 4';

  @override
  String get topikLevel5Label => 'TOPIK 레벨 5';

  @override
  String get topikLevel6Label => 'TOPIK 레벨 6 (어려움)';

  @override
  String get support => '지원';

  @override
  String get terms => '이용약관';

  @override
  String get helpCenter => '도움말 센터';

  @override
  String get contactUs => '문의하기';

  @override
  String get linkOpenError => '링크를 열 수 없습니다.';

  @override
  String get mailAppError => '메일 앱을 열 수 없습니다.';

  @override
  String get resetProgress => '진행 데이터 초기화';

  @override
  String get resetProgressSubtitle => '맞힌 수와 섹션 잠금 해제를 모두 삭제합니다';

  @override
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String get reminderOnMessage => '매일 저녁 알림을 켰어요.';

  @override
  String get reminderOffMessage => '알림을 잠시 쉬고 있어요.';

  @override
  String get dataResetConfirm => '맞힌 기록과 음절 진행도가 모두 삭제됩니다. 계속할까요?';

  @override
  String get dataResetDone => '데이터를 초기화했어요.';

  @override
  String get reset => '초기화';

  @override
  String get debugUnlock => '디버깅잠금해제';

  @override
  String get consonantLockedTitle => '자음 학습 잠금';

  @override
  String consonantLockedContent(Object threshold) {
    return '모음 네 행의 모든 글자를 각각 $threshold회 이상 맞히면 자음 학습이 열립니다.';
  }

  @override
  String get learningSettings => '학습';

  @override
  String vowelUnlockInfo(Object threshold) {
    return '모음 네 행의 모든 글자를 각각 $threshold회 이상 맞히면 자음 학습이 열립니다.';
  }

  @override
  String get rowUnlockTitle => '새로운 행 해제';

  @override
  String rowUnlockContent(Object threshold) {
    return '앞선 행의 모든 글자를 $threshold회 이상 맞히면 다음 행이 열립니다.';
  }

  @override
  String get ok => '확인';

  @override
  String get learnedWords => '내가 학습한 단어';

  @override
  String get learnedWordsEmptyTitle => '아직 정리된 단어가 없어요.';

  @override
  String get learnedWordsEmptySubtitle => '훈련하기에서 새로운 단어를 만나면 여기에 차곡차곡 쌓여요.';
}
