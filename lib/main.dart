import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:learnhangul/l10n/app_localizations.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'design_system.dart';
import 'home_page.dart';

void main() {
  runApp(const LearnHangulApp());
}

class LearnHangulApp extends StatelessWidget {
  const LearnHangulApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      child: MaterialApp(
        locale: locale,
        title: 'LearnHangul',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: LearnHangulTheme.light(),
        darkTheme: LearnHangulTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LearnHangulHomePage(),
      ),
    );
  }
}
