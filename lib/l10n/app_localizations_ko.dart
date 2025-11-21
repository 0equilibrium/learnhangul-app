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
}
