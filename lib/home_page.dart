import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design_system.dart';
import 'models.dart';
import 'screens.dart';
import 'utils.dart';

class LearnHangulHomePage extends StatefulWidget {
  const LearnHangulHomePage({super.key});

  @override
  State<LearnHangulHomePage> createState() => _LearnHangulHomePageState();
}

class _LearnHangulHomePageState extends State<LearnHangulHomePage> {
  bool _isLoading = true;
  bool _consonantUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final allVowels = vowelSections.expand((section) => section.characters);
    final counts = <String, int>{
      for (final vowel in allVowels)
        vowel.symbol: prefs.getInt('correct_${vowel.symbol}') ?? 0,
    };
    final summary = evaluateSectionUnlocks(
      sections: vowelSections,
      correctCounts: counts,
    );
    if (!mounted) return;
    setState(() {
      _consonantUnlocked = summary.allMastered;
      _isLoading = false;
    });
  }

  void _openVowelScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VowelLearningScreen()),
    ).then((_) => _loadProgress());
  }

  void _openConsonantScreen(BuildContext context) {
    if (_isLoading) return;
    if (!_consonantUnlocked) {
      _showConsonantLockedDialog(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConsonantLearningScreen()),
    ).then((_) => _loadProgress());
  }

  void _showConsonantLockedDialog(BuildContext context) {
    final actions = <LearnHangulDialogAction>[
      const LearnHangulDialogAction(label: '확인', isPrimary: true),
    ];

    // Add a debug-only unlock button which bypasses the unlock requirement.
    if (kDebugMode) {
      actions.add(
        LearnHangulDialogAction(
          label: '디버깅잠금해제',
          onTap: () {
            // Mark the consonant section unlocked for this session and open the
            // consonant learning screen. This does not persist unlock status.
            if (!mounted) return;
            setState(() {
              _consonantUnlocked = true;
            });
            _openConsonantScreen(context);
          },
        ),
      );
    }

    showDialog(
      context: context,
      builder: (_) => LearnHangulDialog(
        title: '자음 학습 잠금',
        message: '모음 네 행의 모든 글자를 각각 $kRowUnlockThreshold회 이상 맞히면 자음 학습이 열립니다.',
        variant: LearnHangulDialogVariant.warning,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = LearnHangulTheme.paletteOf(context);
    final iconColor = palette.primaryText;
    final bool showConsonantLocked = !_isLoading && !_consonantUnlocked;

    final menuItems = [
      {
        'label': '모음',
        'leading': Text('ㅏ', style: TextStyle(fontSize: 24, color: iconColor)),
        'onPressed': () => _openVowelScreen(context),
        'variant': LiquidGlassButtonVariant.primary,
        'isLocked': false,
      },
      {
        'label': '자음',
        'leading': Text('ㄱ', style: TextStyle(fontSize: 24, color: iconColor)),
        'onPressed': () => _openConsonantScreen(context),
        'variant': LiquidGlassButtonVariant.secondary,
        'isLocked': showConsonantLocked,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('LearnHangul'),
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              children: [
                const SizedBox(height: 28),
                ...menuItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: LiquidGlassButton(
                      label: item['label'] as String,
                      leading: item['leading'] as Widget,
                      trailing: Icon(
                        CupertinoIcons.chevron_right,
                        color: (item['isLocked'] as bool)
                            ? palette.secondaryText.withOpacity(0.5)
                            : iconColor,
                      ),
                      onPressed: item['onPressed'] as VoidCallback,
                      variant: item['variant'] as LiquidGlassButtonVariant,
                      labelStyle: (item['isLocked'] as bool)
                          ? TextStyle(
                              color: palette.secondaryText.withOpacity(0.5),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: LiquidGlassButton(
              label: '학습 환경 설정',
              leading: Icon(CupertinoIcons.gear_solid, color: iconColor),
              trailing: Icon(CupertinoIcons.chevron_right, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              variant: LiquidGlassButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
