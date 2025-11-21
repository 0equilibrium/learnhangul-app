// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'LearnHangul';

  @override
  String get learnHangul => 'LearnHangul';

  @override
  String get vowels => '母音';

  @override
  String get consonants => '子音';

  @override
  String get train => 'トレーニング';

  @override
  String get checkAnswer => '答えを確認';

  @override
  String get nextQuestion => '次の問題';

  @override
  String get trainingComplete => 'トレーニング完了！';

  @override
  String resultSummary(Object correct, Object wrong) {
    return '正解数: $correct, 間違い: $wrong';
  }

  @override
  String get goHome => 'ホームへ';

  @override
  String get tryAgain => 'もう一度挑戦';

  @override
  String get exampleWord => '例の単語';

  @override
  String get exampleWordTooltip => '例の単語の発音を再生';

  @override
  String get settings => '設定';

  @override
  String get learning => '学習';

  @override
  String get eveningReminder => '夕方のリマインダー';

  @override
  String get eveningReminderSubtitle => '毎日19時に学習リマインダーを受け取る';

  @override
  String get ttsHints => 'TTS ヒント';

  @override
  String get ttsHintsSubtitle => '問題を解くときに自動的に音声ヒントを再生する';

  @override
  String get support => 'サポート';

  @override
  String get terms => '利用規約';

  @override
  String get helpCenter => 'ヘルプセンター';

  @override
  String get contactUs => 'お問い合わせ';

  @override
  String get linkOpenError => 'リンクを開けません。';

  @override
  String get mailAppError => 'メールアプリを開けません。';

  @override
  String get resetProgress => '進捗データをリセット';

  @override
  String get resetProgressSubtitle => '正解数とセクションのロック解除をすべて削除します';

  @override
  String get confirm => 'OK';

  @override
  String get cancel => 'キャンセル';

  @override
  String get reminderOnMessage => '毎日のリマインダーを有効にしました。';

  @override
  String get reminderOffMessage => 'リマインダーを一時停止しました。';

  @override
  String get dataResetConfirm => '正解数と進捗はすべて削除されます。続行しますか？';

  @override
  String get dataResetDone => '進捗データをリセットしました。';

  @override
  String get reset => 'リセット';

  @override
  String get debugUnlock => 'デバッグ解除';

  @override
  String get consonantLockedTitle => '子音学習はロックされています';

  @override
  String consonantLockedContent(Object threshold) {
    return '母音の4行の各文字をそれぞれ$threshold回以上正解すると子音学習が解除されます。';
  }

  @override
  String get learningSettings => '学習設定';

  @override
  String vowelUnlockInfo(Object threshold) {
    return '母音の4行の各文字をそれぞれ$threshold回以上正解すると子音学習が解除されます。';
  }

  @override
  String get rowUnlockTitle => '新しい行をアンロック';

  @override
  String rowUnlockContent(Object threshold) {
    return '前の行のすべての文字をそれぞれ$threshold回以上正解すると、次の行が解除されます。';
  }

  @override
  String get ok => 'OK';
}
