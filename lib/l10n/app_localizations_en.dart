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
  String get settings => 'Settings';

  @override
  String get learning => 'Learning';

  @override
  String get eveningReminder => 'Evening reminder';

  @override
  String get eveningReminderSubtitle =>
      'Receive a study reminder at 19:00 daily';

  @override
  String get ttsHints => 'TTS hints';

  @override
  String get ttsHintsSubtitle =>
      'Automatically hear voice hints during questions';

  @override
  String get support => 'Support';

  @override
  String get terms => 'Terms of service';

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
  String get resetProgressSubtitle =>
      'Deletes correct counts and section unlocks';

  @override
  String get confirm => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get reminderOnMessage => 'Daily reminder enabled.';

  @override
  String get reminderOffMessage => 'Reminders paused.';

  @override
  String get dataResetConfirm =>
      'All correct counts and progress will be deleted. Continue?';

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
}
