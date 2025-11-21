import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:learnhangul/l10n/app_localizations.dart';

import '../custom_list_widgets.dart';
import '../custom_liquid_glass_dialog.dart';
import '../design_system.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminderEnabled = true;
  bool _ttsHintsEnabled = true;

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

  void _toggleTts(bool value) {
    setState(() => _ttsHintsEnabled = value);
  }

  void _confirmReset() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
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

    final sectionBg = CupertinoDynamicColor.resolve(
      CupertinoColors.systemGroupedBackground,
      context,
    );

    return Scaffold(
      appBar: LearnHangulAppBar(
        AppLocalizations.of(context)!.settings,
        backgroundColor: sectionBg,
      ),
      backgroundColor: sectionBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: Text(AppLocalizations.of(context)!.learning),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    AppLocalizations.of(context)!.eveningReminder,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.eveningReminderSubtitle,
                  ),
                  leading: const Icon(Icons.alarm_rounded),
                  trailing: Switch.adaptive(
                    value: _reminderEnabled,
                    onChanged: _toggleReminder,
                  ),
                  onTap: () => _toggleReminder(!_reminderEnabled),
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    AppLocalizations.of(context)!.ttsHints,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context)!.ttsHintsSubtitle,
                  ),
                  leading: const Icon(Icons.hearing_rounded),
                  trailing: Switch.adaptive(
                    value: _ttsHintsEnabled,
                    onChanged: _toggleTts,
                  ),
                  onTap: () => _toggleTts(!_ttsHintsEnabled),
                ),
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
                    final url = Uri.parse('https://www.naver.com');
                    if (await canLaunchUrl(url))
                      await launchUrl(url);
                    else
                      LearnHangulSnackbar.show(
                        context,
                        message: AppLocalizations.of(context)!.linkOpenError,
                        tone: LearnHangulSnackTone.danger,
                      );
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
                    final url = Uri.parse('https://www.naver.com');
                    if (await canLaunchUrl(url))
                      await launchUrl(url);
                    else
                      LearnHangulSnackbar.show(
                        context,
                        message: AppLocalizations.of(context)!.linkOpenError,
                        tone: LearnHangulSnackTone.danger,
                      );
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
                      path: 'yujunhyung@gmail.com',
                    );
                    if (await canLaunchUrl(emailUri))
                      await launchUrl(emailUri);
                    else
                      LearnHangulSnackbar.show(
                        context,
                        message: AppLocalizations.of(context)!.mailAppError,
                        tone: LearnHangulSnackTone.danger,
                      );
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
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
