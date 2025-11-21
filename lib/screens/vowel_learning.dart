import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnhangul/l10n/app_localizations.dart';

import '../custom_liquid_glass_dialog.dart';
import '../design_system.dart';
import '../models.dart';
import '../widgets.dart';
import '../utils.dart';
import 'training.dart';
import '../premium_voice_dialog.dart';

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
          title: Text(AppLocalizations.of(context)!.rowUnlockTitle),
          content: Text(
            AppLocalizations.of(context)!.rowUnlockContent(kRowUnlockThreshold),
          ),
          actions: [
            CustomLiquidGlassDialogAction(
              isConfirmationBlue: true,
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LearnHangulAppBar(AppLocalizations.of(context)!.vowels),
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
              label: AppLocalizations.of(context)!.train,
              onPressed: () async {
                final ok = await showPremiumVoiceCheckDialog(context);
                if (!ok) return;
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
