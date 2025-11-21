import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LearnHangul'**
  String get appTitle;

  /// No description provided for @learnHangul.
  ///
  /// In en, this message translates to:
  /// **'LearnHangul'**
  String get learnHangul;

  /// No description provided for @vowels.
  ///
  /// In en, this message translates to:
  /// **'Vowels'**
  String get vowels;

  /// No description provided for @consonants.
  ///
  /// In en, this message translates to:
  /// **'Consonants'**
  String get consonants;

  /// No description provided for @train.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get train;

  /// No description provided for @checkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check Answer'**
  String get checkAnswer;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// No description provided for @trainingComplete.
  ///
  /// In en, this message translates to:
  /// **'Training complete!'**
  String get trainingComplete;

  /// No description provided for @resultSummary.
  ///
  /// In en, this message translates to:
  /// **'Total correct: {correct}, Incorrect: {wrong}'**
  String resultSummary(Object correct, Object wrong);

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get goHome;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @exampleWord.
  ///
  /// In en, this message translates to:
  /// **'Example word'**
  String get exampleWord;

  /// No description provided for @exampleWordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play example word pronunciation'**
  String get exampleWordTooltip;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// No description provided for @eveningReminder.
  ///
  /// In en, this message translates to:
  /// **'Evening reminder'**
  String get eveningReminder;

  /// No description provided for @eveningReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive a study reminder at 19:00 daily'**
  String get eveningReminderSubtitle;

  /// No description provided for @ttsHints.
  ///
  /// In en, this message translates to:
  /// **'TTS hints'**
  String get ttsHints;

  /// No description provided for @ttsHintsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically hear voice hints during questions'**
  String get ttsHintsSubtitle;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get terms;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get helpCenter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @linkOpenError.
  ///
  /// In en, this message translates to:
  /// **'Cannot open link.'**
  String get linkOpenError;

  /// No description provided for @mailAppError.
  ///
  /// In en, this message translates to:
  /// **'Cannot open mail app.'**
  String get mailAppError;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress data'**
  String get resetProgress;

  /// No description provided for @resetProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deletes correct counts and section unlocks'**
  String get resetProgressSubtitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reminderOnMessage.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder enabled.'**
  String get reminderOnMessage;

  /// No description provided for @reminderOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminders paused.'**
  String get reminderOffMessage;

  /// No description provided for @dataResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'All correct counts and progress will be deleted. Continue?'**
  String get dataResetConfirm;

  /// No description provided for @dataResetDone.
  ///
  /// In en, this message translates to:
  /// **'Progress data has been reset.'**
  String get dataResetDone;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @debugUnlock.
  ///
  /// In en, this message translates to:
  /// **'Debug unlock'**
  String get debugUnlock;

  /// No description provided for @consonantLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Consonant learning locked'**
  String get consonantLockedTitle;

  /// No description provided for @consonantLockedContent.
  ///
  /// In en, this message translates to:
  /// **'Consonant learning unlocks when you answer each letter in the four vowel rows correctly at least {threshold} times.'**
  String consonantLockedContent(Object threshold);

  /// No description provided for @learningSettings.
  ///
  /// In en, this message translates to:
  /// **'Learning settings'**
  String get learningSettings;

  /// No description provided for @vowelUnlockInfo.
  ///
  /// In en, this message translates to:
  /// **'Consonant learning unlocks when you answer each letter in the four vowel rows correctly at least {threshold} times.'**
  String vowelUnlockInfo(Object threshold);

  /// No description provided for @rowUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock New Row'**
  String get rowUnlockTitle;

  /// No description provided for @rowUnlockContent.
  ///
  /// In en, this message translates to:
  /// **'The next row unlocks when you correctly answer every character in the previous row at least {threshold} times.'**
  String rowUnlockContent(Object threshold);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
