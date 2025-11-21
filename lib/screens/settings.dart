import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:learnhangul/l10n/app_localizations.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../custom_list_widgets.dart';
import '../custom_liquid_glass_dialog.dart';
import '../data/training_words_repository.dart';
import '../design_system.dart';
import '../services/analytics_service.dart';
import 'dev_all_words.dart';
import 'dev_progress_control.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminderEnabled = true;
  bool _premiumBypass = false;
  TopikWordLevel? _selectedTopikLevel;
  bool _loadingTopikLevel = true;

  @override
  void initState() {
    super.initState();
    _loadTopikLevel();
    _loadPremiumBypass();
  }

  Future<void> _loadPremiumBypass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('debug_bypass_premium_voice') ?? false;
      if (!mounted) return;
      setState(() => _premiumBypass = val);
    } catch (_) {
      // ignore
    }
  }

  void _togglePremiumBypass(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('debug_bypass_premium_voice', value);
    } catch (_) {
      // ignore
    }
    if (!mounted) return;
    setState(() => _premiumBypass = value);
    LearnHangulSnackbar.show(
      context,
      message: value ? '프리미엄 보이스 체크 우회 활성화' : '프리미엄 보이스 체크 우회 비활성화',
      tone: value ? LearnHangulSnackTone.success : LearnHangulSnackTone.warning,
    );
  }

  void _toggleReminder(bool value) {
    setState(() => _reminderEnabled = value);
    LearnHangulSnackbar.show(
      context,
      message: value
          ? AppLocalizations.of(context)!.reminderOnMessage
          : AppLocalizations.of(context)!.reminderOffMessage,
      tone: value ? LearnHangulSnackTone.success : LearnHangulSnackTone.warning,
    );
  }

  // TTS hints removed; no toggle method needed.

  Future<void> _loadTopikLevel() async {
    final level = await TopikWordLevelPreferences.load();
    AnalyticsService.instance.syncTopikLevelProfile(level);
    if (!mounted) return;
    setState(() {
      _selectedTopikLevel = level;
      _loadingTopikLevel = false;
    });
  }

  // Short numeric label shown in the settings tile trailing.
  String _topikLevelTrailingLabel(TopikWordLevel level) => '${level.number}';

  // Picker option label: use explicit "TOPIK Level {n}" text for choices.
  String _topikLevelOptionLabel(TopikWordLevel level) =>
      'TOPIK Level ${level.number}';

  Future<void> _persistTopikLevel(TopikWordLevel level) async {
    await TopikWordLevelPreferences.save(level);
    AnalyticsService.instance.trackTopikLevelChanged(level);
    if (!mounted) return;
    setState(() => _selectedTopikLevel = level);
  }

  void _onTopikLevelSelected(TopikWordLevel level) {
    if (level == _selectedTopikLevel) return;
    unawaited(_persistTopikLevel(level));
  }

  void _confirmReset() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: Text(AppLocalizations.of(context)!.resetProgress),
          content: Text(AppLocalizations.of(context)!.dataResetConfirm),
          actions: [
            CustomLiquidGlassDialogAction(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            CustomLiquidGlassDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                LearnHangulSnackbar.show(
                  context,
                  message: AppLocalizations.of(context)!.dataResetDone,
                  tone: LearnHangulSnackTone.danger,
                );
              },
              child: Text(AppLocalizations.of(context)!.reset),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final sectionBg = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGroupedBackground,
      context,
    );

    return Scaffold(
      appBar: LearnHangulAppBar(l10n.settings, backgroundColor: sectionBg),
      backgroundColor: sectionBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: Text(l10n.learning),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    l10n.topikLevelTileTitle,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(l10n.topikLevelTileSubtitle),
                  leading: const Icon(Icons.auto_stories_outlined),
                  trailing: _loadingTopikLevel
                      ? const CupertinoActivityIndicator(radius: 9)
                      : PullDownButton(
                          itemBuilder: (context) => [
                            for (final level in TopikWordLevel.values)
                              PullDownMenuItem.selectable(
                                onTap: () => _onTopikLevelSelected(level),
                                title: _topikLevelOptionLabel(level),
                                selected:
                                    level ==
                                    (_selectedTopikLevel ??
                                        TopikWordLevel.topik1),
                              ),
                          ],
                          buttonBuilder: (context, showMenu) => GestureDetector(
                            onTap: showMenu,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _topikLevelTrailingLabel(
                                    _selectedTopikLevel ??
                                        TopikWordLevel.topik1,
                                  ),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(CupertinoIcons.chevron_down),
                              ],
                            ),
                          ),
                        ),
                  onTap: null,
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    l10n.eveningReminder,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(l10n.eveningReminderSubtitle),
                  leading: const Icon(Icons.alarm_rounded),
                  trailing: Switch.adaptive(
                    value: _reminderEnabled,
                    onChanged: _toggleReminder,
                  ),
                  onTap: () => _toggleReminder(!_reminderEnabled),
                ),
                // TTS hints tile removed per user request.
              ],
            ),
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: Text(AppLocalizations.of(context)!.support),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    AppLocalizations.of(context)!.terms,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  leading: const Icon(CupertinoIcons.doc_text),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () async {
                    final url = Uri.parse(
                      'https://deeply-hide-660.notion.site/Terms-2b26ba03239c80129628fa317591a703',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (!context.mounted) return;
                      LearnHangulSnackbar.show(
                        context,
                        message: AppLocalizations.of(context)!.linkOpenError,
                        tone: LearnHangulSnackTone.danger,
                      );
                    }
                  },
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    AppLocalizations.of(context)!.helpCenter,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  leading: const Icon(CupertinoIcons.question_circle),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () async {
                    final url = Uri.parse(
                      'https://deeply-hide-660.notion.site/Help-Center-2b26ba03239c80609baada469b90af3a',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (!context.mounted) return;
                      LearnHangulSnackbar.show(
                        context,
                        message: AppLocalizations.of(context)!.linkOpenError,
                        tone: LearnHangulSnackTone.danger,
                      );
                    }
                  },
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    AppLocalizations.of(context)!.contactUs,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  leading: const Icon(CupertinoIcons.mail),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () async {
                    final emailUri = Uri(
                      scheme: 'mailto',
                      path: 'grainy-tartans.0g@icloud.com',
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (!context.mounted) return;
                      LearnHangulSnackbar.show(
                        context,
                        message: AppLocalizations.of(context)!.mailAppError,
                        tone: LearnHangulSnackTone.danger,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: Text(AppLocalizations.of(context)!.learnHangul),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    AppLocalizations.of(context)!.resetProgress,
                    style: TextStyle(
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.resetProgressSubtitle,
                  ),
                  leading: Icon(
                    Icons.delete_sweep_rounded,
                    color: isDarkMode ? Colors.red[300] : Colors.red,
                  ),
                  onTap: _confirmReset,
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 6),
              CustomListSection.insetGrouped(
                header: const Text('Developer'),
                children: [
                  CustomListTile(
                    backgroundColor: palette.surface,
                    title: const Text('Show all training words'),
                    subtitle: const Text('앱 내 존재하는 전체 훈련 단어 보기'),
                    leading: const Icon(Icons.developer_mode_outlined),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DevAllWordsScreen(),
                        ),
                      );
                    },
                  ),
                  CustomListTile(
                    backgroundColor: palette.surface,
                    title: const Text('프리미엄 보이스 체크 우회'),
                    subtitle: const Text('프리미엄 음성 체크를 디버그 목적으로 우회'),
                    leading: const Icon(Icons.hearing_rounded),
                    trailing: Switch.adaptive(
                      value: _premiumBypass,
                      onChanged: _togglePremiumBypass,
                    ),
                    onTap: () => _togglePremiumBypass(!_premiumBypass),
                  ),
                  CustomListTile(
                    backgroundColor: palette.surface,
                    title: const Text('Progress control'),
                    subtitle: const Text('모음/자음 행 단위로 정답 횟수 조정'),
                    leading: const Icon(Icons.tune),
                    trailing: const Icon(CupertinoIcons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DevProgressControlScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
