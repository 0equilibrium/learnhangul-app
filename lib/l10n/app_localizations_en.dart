// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LearnHangul';

  @override
  String get learnHangul => 'LearnHangul';

  @override
  String get vowels => 'Vowels';

  @override
  String get consonants => 'Consonants';

  @override
  String get train => 'Train';

  @override
  String get checkAnswer => 'Check Answer';

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get trainingComplete => 'Training complete!';

  @override
  String get trainingExitTitle => 'Leave training?';

  @override
  String get trainingExitMessage => 'Your current training session won\'t be saved if you leave now. Exit anyway?';

  @override
  String get trainingExitLeave => 'Leave';

  @override
  String get trainingExitStay => 'Keep training';

  @override
  String resultSummary(Object correct, Object wrong) {
    return 'Total correct: $correct, Incorrect: $wrong';
  }

  @override
  String get goHome => 'Go home';

  @override
  String get tryAgain => 'Try again';

  @override
  String get exampleWord => 'Example word';

  @override
  String get exampleWordTooltip => 'Play example word pronunciation';

  @override
  String get nameLabel => 'Name';

  @override
  String get romanizationLabel => 'Romanization';

  @override
  String get settings => 'Settings';

  @override
  String get learning => 'Learning';

  @override
  String get eveningReminder => 'Evening reminder';

  @override
  String get eveningReminderSubtitle => 'Receive a study reminder at 19:00 daily';

  @override
  String get ttsHints => 'TTS hints';

  @override
  String get ttsHintsSubtitle => 'Automatically hear voice hints during questions';

  @override
  String get topikLevelTileTitle => 'Training word level';

  @override
  String get topikLevelTileSubtitle => 'Choose which TOPIK vocabulary set is used during training.';

  @override
  String get topikLevelSheetTitle => 'Select TOPIK level';

  @override
  String get topikLevel1Label => 'TOPIK Level 1 (Easiest)';

  @override
  String get topikLevel2Label => 'TOPIK Level 2';

  @override
  String get topikLevel3Label => 'TOPIK Level 3';

  @override
  String get topikLevel4Label => 'TOPIK Level 4';

  @override
  String get topikLevel5Label => 'TOPIK Level 5';

  @override
  String get topikLevel6Label => 'TOPIK Level 6 (Hardest)';

  @override
  String get support => 'Support';

  @override
  String get terms => 'Terms';

  @override
  String get helpCenter => 'Help center';

  @override
  String get contactUs => 'Contact us';

  @override
  String get linkOpenError => 'Cannot open link.';

  @override
  String get mailAppError => 'Cannot open mail app.';

  @override
  String get resetProgress => 'Reset progress data';

  @override
  String get resetProgressSubtitle => 'Deletes correct counts and section unlocks';

  @override
  String get confirm => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get reminderOnMessage => 'Daily reminder enabled.';

  @override
  String get reminderOffMessage => 'Reminders paused.';

  @override
  String get dataResetConfirm => 'All correct counts and progress will be deleted. Continue?';

  @override
  String get dataResetDone => 'Progress data has been reset.';

  @override
  String get reset => 'Reset';

  @override
  String get debugUnlock => 'Debug unlock';

  @override
  String get consonantLockedTitle => 'Consonant learning locked';

  @override
  String consonantLockedContent(Object threshold) {
    return 'Consonant learning unlocks when you answer each letter in the four vowel rows correctly at least $threshold times.';
  }

  @override
  String get learningSettings => 'Learning settings';

  @override
  String vowelUnlockInfo(Object threshold) {
    return 'Consonant learning unlocks when you answer each letter in the four vowel rows correctly at least $threshold times.';
  }

  @override
  String get rowUnlockTitle => 'Unlock New Row';

  @override
  String rowUnlockContent(Object threshold) {
    return 'The next row unlocks when you correctly answer every character in the previous row at least $threshold times.';
  }

  @override
  String get ok => 'OK';

  @override
  String get learnedWords => 'Learned words';

  @override
  String get learnedWordsEmptyTitle => 'No learned words yet.';

  @override
  String get learnedWordsEmptySubtitle => 'Words you encounter in Train will be recorded here.';
}
