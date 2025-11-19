import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../custom_list_widgets.dart';
import '../custom_liquid_glass_dialog.dart';
import '../design_system.dart';
import '../liquid_glass_buttons.dart';
import '../models.dart';
import '../widgets.dart';
import '../utils.dart';
import 'training.dart';

class VowelLearningScreen extends StatefulWidget {
  const VowelLearningScreen({super.key});

  @override
  State<VowelLearningScreen> createState() => _VowelLearningScreenState();
}

class _VowelLearningScreenState extends State<VowelLearningScreen> {
  Map<String, int> _correctCounts = const {};
  List<SectionUnlockStatus> _sectionStatuses = const [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final allVowels = vowelSections
        .expand((section) => section.characters)
        .toList();
    final counts = {
      for (var v in allVowels)
        v.symbol: prefs.getInt('correct_${v.symbol}') ?? 0,
    };
    final summary = evaluateSectionUnlocks(
      sections: vowelSections,
      correctCounts: counts,
    );
    if (!mounted) return;
    setState(() {
      _correctCounts = counts;
      _sectionStatuses = summary.statuses;
    });
  }

  void _showVowelLockedRowDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: CustomLiquidGlassDialog(
          title: const Text('새로운 행 해제'),
          content: Text(
            '앞선 행의 모든 모음을 각각 $kRowUnlockThreshold회 이상 맞히면 다음 행이 열립니다.',
          ),
          actions: [
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LearnHangulAppBar('모음'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (final entry in vowelSections.asMap().entries)
                    Padding(
                      // Add vertical spacing between section rows for better readability.
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HangulSectionCard(
                        section: entry.value,
                        onCharacterTap: (character) =>
                            showCharacterDetails(context, character),
                        correctCounts: _correctCounts,
                        isLocked: entry.key < _sectionStatuses.length
                            ? !_sectionStatuses[entry.key].isUnlocked
                            : entry.key > 0,
                        isMastered: entry.key < _sectionStatuses.length
                            ? _sectionStatuses[entry.key].isMastered
                            : false,
                        unlockThreshold: kRowUnlockThreshold,
                        onLockedTap: _showVowelLockedRowDialog,
                        isDense: true,
                        showHeader: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            // Add horizontal margin so the button doesn't stretch edge-to-edge.
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: LiquidGlassButton(
              label: '훈련하기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TrainingScreen(sections: vowelSections),
                  ),
                ).then((_) => _loadCounts());
              },
            ),
          ),
        ],
      ),
    );
  }
}
