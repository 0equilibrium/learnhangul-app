import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system.dart';
import '../models.dart';

class DevProgressControlScreen extends StatefulWidget {
  const DevProgressControlScreen({super.key});

  @override
  State<DevProgressControlScreen> createState() =>
      _DevProgressControlScreenState();
}

class _DevProgressControlScreenState extends State<DevProgressControlScreen> {
  int _vowelRows = 0;
  int _consonantRows = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();

    int vowelCount = 0;
    for (var i = 0; i < vowelSections.length; i++) {
      final section = vowelSections[i];
      final allOk = section.characters.every((c) {
        final v = prefs.getInt('correct_${c.symbol}') ?? 0;
        return v >= 4;
      });
      if (allOk) vowelCount++;
    }

    int consonantCount = 0;
    for (var i = 0; i < consonantSections.length; i++) {
      final section = consonantSections[i];
      final allOk = section.characters.every((c) {
        final v = prefs.getInt('correct_${c.symbol}') ?? 0;
        return v >= 4;
      });
      if (allOk) consonantCount++;
    }

    if (!mounted) return;
    setState(() {
      _vowelRows = vowelCount;
      _consonantRows = consonantCount;
      _loading = false;
    });
  }

  Future<void> _applySettings() async {
    final prefs = await SharedPreferences.getInstance();

    for (var i = 0; i < vowelSections.length; i++) {
      final target = i < _vowelRows ? 4 : 0;
      for (final c in vowelSections[i].characters) {
        await prefs.setInt('correct_${c.symbol}', target);
      }
    }

    for (var i = 0; i < consonantSections.length; i++) {
      final target = i < _consonantRows ? 4 : 0;
      for (final c in consonantSections[i].characters) {
        await prefs.setInt('correct_${c.symbol}', target);
      }
    }

    if (!mounted) return;
    LearnHangulSnackbar.show(
      context,
      message:
          'Progress updated (vowel=$_vowelRows, consonant=$_consonantRows)',
      tone: LearnHangulSnackTone.success,
    );
    await _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final typography = LearnHangulTheme.typographyOf(context);
    if (_loading) {
      return const Scaffold(
        appBar: LearnHangulAppBar('Developer: Progress control'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: LearnHangulAppBar('Developer: Progress control'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vowels rows (0..${vowelSections.length})',
              style: typography.heading,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _vowelRows.toDouble(),
                    min: 0,
                    max: vowelSections.length.toDouble(),
                    divisions: vowelSections.length,
                    label: '$_vowelRows',
                    onChanged: (v) => setState(() => _vowelRows = v.toInt()),
                  ),
                ),
                SizedBox(width: 48, child: Text('$_vowelRows')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Consonant rows (0..${consonantSections.length})',
              style: typography.heading,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _consonantRows.toDouble(),
                    min: 0,
                    max: consonantSections.length.toDouble(),
                    divisions: consonantSections.length,
                    label: '$_consonantRows',
                    onChanged: (v) =>
                        setState(() => _consonantRows = v.toInt()),
                  ),
                ),
                SizedBox(width: 48, child: Text('$_consonantRows')),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: LiquidGlassButton(
                    label: 'Save',
                    onPressed: _applySettings,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loadCurrent,
                    child: const Text('Reload'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Note: Setting to 0 will set all characters in the type to 0 correct counts.',
              style: typography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
