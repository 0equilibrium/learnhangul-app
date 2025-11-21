import 'package:flutter/material.dart';

import '../design_system.dart';
import '../data/training_words_repository.dart';
import '../models.dart';

class DevAllWordsScreen extends StatefulWidget {
  const DevAllWordsScreen({super.key});

  @override
  State<DevAllWordsScreen> createState() => _DevAllWordsScreenState();
}

class _DevAllWordsScreenState extends State<DevAllWordsScreen> {
  bool _loading = true;
  final Map<TopikWordLevel, TrainingWordData> _dataByLevel = {};
  final List<HangulCharacter> _otherWords = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    _dataByLevel.clear();
    _otherWords.clear();

    for (final level in TopikWordLevel.values) {
      try {
        final data = await trainingWordRepository.load(level: level);
        _dataByLevel[level] = data;
      } catch (_) {
        _dataByLevel[level] = TrainingWordData(
          openSyllableWords: const [],
          batchimWords: const [],
        );
      }
    }

    // Collect all symbols present in Topik level data.
    final present = <String>{};
    for (final data in _dataByLevel.values) {
      present.addAll(data.trainingWordBySymbol.keys);
    }

    // Find any characters from the built-in consonant/vowel sections
    // that are not present in the Topik datasets and show them as "Other".
    for (final section in [...consonantSections, ...vowelSections]) {
      for (final ch in section.characters) {
        if (!present.contains(ch.symbol)) {
          _otherWords.add(ch);
        }
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _openLevel(
    BuildContext context,
    String title,
    List<HangulCharacter> words,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LevelWordsScreen(title: title, words: words),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: LearnHangulAppBar('Developer: All words'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tiles = <Widget>[];
    for (final level in TopikWordLevel.values) {
      final data = _dataByLevel[level]!;
      final count = data.trainingWordBySymbol.length;
      tiles.add(
        GestureDetector(
          onTap: () => _openLevel(
            context,
            '${level.number}급 ($count)',
            data.trainingWordBySymbol.values.toList()
              ..sort((a, b) => a.symbol.compareTo(b.symbol)),
          ),
          child: LearnHangulSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${level.number}급',
                  style: LearnHangulTheme.typographyOf(context).heading,
                ),
                const SizedBox(height: 8),
                Text(
                  '$count 단어',
                  style: LearnHangulTheme.typographyOf(context).body,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_otherWords.isNotEmpty) {
      tiles.add(
        GestureDetector(
          onTap: () => _openLevel(
            context,
            '급수 바깥 단어 (${_otherWords.length})',
            _otherWords..sort((a, b) => a.symbol.compareTo(b.symbol)),
          ),
          child: LearnHangulSurface(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '급수 바깥',
                  style: LearnHangulTheme.typographyOf(context).heading,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_otherWords.length} 단어',
                  style: LearnHangulTheme.typographyOf(context).body,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: LearnHangulAppBar('Developer: All words'),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: Scrollbar(
          thumbVisibility: true,
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3 / 2,
            children: tiles,
          ),
        ),
      ),
    );
  }
}

class LevelWordsScreen extends StatelessWidget {
  const LevelWordsScreen({super.key, required this.title, required this.words});

  final String title;
  final List<HangulCharacter> words;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LearnHangulAppBar(title),
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: words.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final w = words[index];
            return LearnHangulSurface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        w.symbol,
                        style: LearnHangulTheme.typographyOf(context).heading,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(w.name)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (w.pos != null && w.pos!.isNotEmpty)
                    Text(
                      '품사: ${w.pos}',
                      style: LearnHangulTheme.typographyOf(context).caption,
                    ),
                  if (w.example.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '예문: ${w.example}',
                      style: LearnHangulTheme.typographyOf(context).body,
                    ),
                  ],
                  if (w.meaning != null && (w.meaning ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '설명: ${w.meaning}',
                      style: LearnHangulTheme.typographyOf(context).caption,
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
