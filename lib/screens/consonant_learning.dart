import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:learnhangul/l10n/app_localizations.dart';

import '../custom_liquid_glass_dialog.dart';
import '../design_system.dart';
import '../liquid_glass_buttons.dart';
import '../models.dart';
import '../widgets.dart';
import '../utils.dart';
import 'training.dart';
import 'learned_words.dart';
import '../premium_voice_dialog.dart';

class ConsonantLearningScreen extends StatefulWidget {
  const ConsonantLearningScreen({super.key});

  @override
  State<ConsonantLearningScreen> createState() =>
      _ConsonantLearningScreenState();
}

class _ConsonantLearningScreenState extends State<ConsonantLearningScreen> {
  Map<String, int> _correctCounts = const {};
  List<SectionUnlockStatus> _sectionStatuses = const [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final allConsonants = consonantSections
        .expand((section) => section.characters)
        .toList();
    final counts = {
      for (var c in allConsonants)
        c.symbol: prefs.getInt('correct_${c.symbol}') ?? 0,
    };
    final summary = evaluateSectionUnlocks(
      sections: consonantSections,
      correctCounts: counts,
    );
    if (!mounted) return;
    setState(() {
      _correctCounts = counts;
      _sectionStatuses = summary.statuses;
    });
  }

  void _showConsonantLockedRowDialog() {
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
      appBar: LearnHangulAppBar(
        AppLocalizations.of(context)!.consonants,
        trailing: LiquidGlassButtons.circularIconButton(
          context,
          icon: Icons.menu_book_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LearnedWordsScreen(),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (final entry in consonantSections.asMap().entries)
                    Padding(
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
                        onLockedTap: _showConsonantLockedRowDialog,
                        isDense: true,
                        showHeader: false,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
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
                        TrainingScreen(sections: consonantSections),
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
