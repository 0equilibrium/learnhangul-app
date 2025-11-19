import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design_system.dart';
import 'models.dart';
import 'screens.dart';
import 'custom_liquid_glass_dialog.dart';
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
    // Build actions for CustomLiquidGlassDialog. When in debug mode, stack
    // the confirmation and debug-unlock buttons vertically; otherwise show a
    // single blue confirmation button (same as '새로운 행 해제').
    final List<Widget> dialogActions;

    if (kDebugMode) {
      dialogActions = [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
            const SizedBox(height: 12),
            CustomLiquidGlassDialogAction(
              onPressed: () {
                // Mark unlocked for this session and open consonant screen.
                if (!mounted) return;
                setState(() {
                  _consonantUnlocked = true;
                });
                Navigator.pop(context);
                _openConsonantScreen(context);
              },
              child: const Text('디버깅잠금해제'),
            ),
          ],
        ),
      ];
    } else {
      dialogActions = [
        CustomLiquidGlassDialogAction(
          isConfirmationBlue: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ];
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('자음 학습 잠금'),
          content: Text(
            '모음 네 행의 모든 글자를 각각 $kRowUnlockThreshold회 이상 맞히면 자음 학습이 열립니다.',
          ),
          actions: dialogActions,
        ),
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
        'leading': Text(
          'ㄱ',
          style: TextStyle(
            fontSize: 24,
            color: showConsonantLocked
                ? palette.secondaryText.withOpacity(0.5)
                : iconColor,
          ),
        ),
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
