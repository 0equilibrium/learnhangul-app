import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:learnhangul/l10n/app_localizations.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'design_system.dart';
import 'home_page.dart';
import 'services/analytics_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.instance.init();
  await MobileAds.instance.initialize();
  AnalyticsService.instance.trackAppLaunch();
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
