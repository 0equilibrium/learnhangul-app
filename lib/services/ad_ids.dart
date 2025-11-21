import 'package:flutter/foundation.dart';

/// Provides the correct AdMob unit IDs depending on build/debug mode.
class AdIDs {
  AdIDs._();

  static const String appId = 'ca-app-pub-2026353035353646~1379478546';
  static const String placementExitBeforeComplete = 'exit_before_complete';
  static const String placementWrongOverFive = 'wrong_over_five';

  static const String _exitBeforeCompleteUnit =
      'ca-app-pub-2026353035353646/2313286268';
  static const String _wrongOverFiveUnit =
      'ca-app-pub-2026353035353646/4282464748';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  static String interstitial(String placement) {
    if (kDebugMode) return _testInterstitialIos;
    switch (placement) {
      case placementWrongOverFive:
        return _wrongOverFiveUnit;
      case placementExitBeforeComplete:
      default:
        return _exitBeforeCompleteUnit;
    }
  }
}
