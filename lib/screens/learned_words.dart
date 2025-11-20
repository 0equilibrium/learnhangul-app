import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../premium_voice_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system.dart';
import 'common.dart';

class LearnedWordsScreen extends StatefulWidget {
  const LearnedWordsScreen({super.key});

  @override
  State<LearnedWordsScreen> createState() => _LearnedWordsScreenState();
}

class _LearnedWordsScreenState extends State<LearnedWordsScreen> {
  List<LearnedWordEntry> _words = const [];
  bool _isLoading = true;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadWords();
    _configureTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _loadWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(learnedWordsPrefsKey);
      final entries = raw == null
          ? <LearnedWordEntry>[]
          : (jsonDecode(raw) as List<dynamic>)
                .map(
                  (item) => LearnedWordEntry.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      entries.sort((a, b) => b.seenAt.compareTo(a.seenAt));
      if (!mounted) return;
      setState(() {
        _words = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _words = const [];
        _isLoading = false;
      });
    }
  }

  Future<void> _configureTts() async {
    try {
      await _flutterTts.setLanguage('ko-KR');
    } catch (_) {}
    try {
      await _flutterTts.setSpeechRate(0.5);
    } catch (_) {}
    try {
      await _flutterTts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      final ok = await showPremiumVoiceCheckDialog(context);
      if (!ok) return;
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: LearnHangulAppBar('내가 학습한 단어'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final typography = LearnHangulTheme.typographyOf(context);
    final palette = LearnHangulTheme.paletteOf(context);

    Widget body;
    if (_words.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 48,
                color: palette.secondaryText,
              ),
              const SizedBox(height: 12),
              Text('아직 정리된 단어가 없어요.', style: typography.heading),
              const SizedBox(height: 8),
              Text(
                '훈련하기에서 새로운 단어를 만나면 여기에 차곡차곡 쌓여요.',
                textAlign: TextAlign.center,
                style: typography.body.copyWith(color: palette.secondaryText),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _loadWords,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final word = _words[index];
            return GestureDetector(
              onTap: () => _speak(word.term),
              child: LearnHangulSurface(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.term,
                      style: typography.hero.copyWith(fontSize: 36),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(word.romanization, style: typography.caption),
                        if (word.meaning != null) ...[
                          const SizedBox(width: 12),
                          Text('·', style: typography.caption),
                          const SizedBox(width: 12),
                          Text(word.meaning!, style: typography.caption),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: _words.length,
        ),
      );
    }

    return Scaffold(appBar: const LearnHangulAppBar('내가 학습한 단어'), body: body);
  }
}
