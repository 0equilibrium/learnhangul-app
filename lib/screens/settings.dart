import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

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
      message: value ? '매일 저녁 알림을 켰어요.' : '알림을 잠시 쉬고 있어요.',
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
          title: const Text('학습 데이터 초기화'),
          content: const Text('맞힌 기록과 음절 진행도가 모두 삭제됩니다. 계속할까요?'),
          actions: [
            CustomLiquidGlassDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            CustomLiquidGlassDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                LearnHangulSnackbar.show(
                  context,
                  message: '데이터를 초기화했어요.',
                  tone: LearnHangulSnackTone.danger,
                );
              },
              child: const Text('초기화'),
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
      appBar: LearnHangulAppBar('설정', backgroundColor: sectionBg),
      backgroundColor: sectionBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: const Text('학습'),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '저녁 리마인더',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: const Text('매일 19시에 학습 알림 받기'),
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
                    'TTS 힌트',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: const Text('문제를 풀 때 자동으로 음성 힌트 듣기'),
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
              header: const Text('지원'),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '이용약관',
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
                        message: '링크를 열 수 없습니다.',
                        tone: LearnHangulSnackTone.danger,
                      );
                  },
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '도움말 센터',
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
                        message: '링크를 열 수 없습니다.',
                        tone: LearnHangulSnackTone.danger,
                      );
                  },
                ),
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '문의하기',
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
                        message: '메일 앱을 열 수 없습니다.',
                        tone: LearnHangulSnackTone.danger,
                      );
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomListSection.insetGrouped(
              header: const Text('계정'),
              children: [
                CustomListTile(
                  backgroundColor: palette.surface,
                  title: Text(
                    '진행 데이터 초기화',
                    style: TextStyle(
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                  subtitle: const Text('맞힌 수와 섹션 잠금 해제를 모두 삭제합니다'),
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
