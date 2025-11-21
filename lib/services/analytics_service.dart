import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/training_words_repository.dart';

/// Lightweight facade around Mixpanel to avoid sprinkling init logic across
/// widgets. Persists a generated distinct ID so Mixpanel profiles remain
/// consistent between launches even without sign-in.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const String _token = '052c9d9667686a5c95cd031793b168ff';
  static const String _distinctIdKey = 'mixpanel_distinct_id';

  Mixpanel? _mixpanel;
  bool _initializing = false;

  bool get isReady => _mixpanel != null;

  Future<void> init() async {
    if (_mixpanel != null || _initializing) return;
    _initializing = true;
    try {
      final mixpanel = await Mixpanel.init(_token, trackAutomaticEvents: true);
      final prefs = await SharedPreferences.getInstance();
      var distinctId = prefs.getString(_distinctIdKey);
      if (distinctId == null) {
        distinctId = _generateDistinctId();
        await prefs.setString(_distinctIdKey, distinctId);
      }
      mixpanel.identify(distinctId);
      final localeTag = PlatformDispatcher.instance.locale.toLanguageTag();
      final platform = defaultTargetPlatform.name;
      mixpanel.registerSuperProperties({
        'app_language': localeTag,
        'platform': platform,
      });
      final people = mixpanel.getPeople();
      people.setOnce('first_seen_at', DateTime.now().toIso8601String());
      people.set('app_language', localeTag);
      people.set('platform', platform);
      people.set('distinct_id', distinctId);
      _mixpanel = mixpanel;
    } catch (error) {
      debugPrint('Mixpanel init failed: $error');
    } finally {
      _initializing = false;
    }
  }

  void trackAppLaunch() {
    _track('app_launch');
  }

  void trackTopikLevelChanged(TopikWordLevel level) {
    _track('topik_level_changed', {'level': level.number});
    _setProfileValue('topik_level', level.number);
  }

  void syncTopikLevelProfile(TopikWordLevel level) {
    _setProfileValue('topik_level', level.number);
  }

  void trackTrainingSessionStarted({
    required bool isConsonantSession,
    required bool includesWordPool,
    required int questionPoolSize,
    TopikWordLevel? wordLevel,
  }) {
    _track('training_session_started', {
      'mode': isConsonantSession ? 'consonant' : 'vowel',
      'includes_words': includesWordPool,
      'question_pool_size': questionPoolSize,
      if (wordLevel != null) 'topik_level': wordLevel.number,
    });
    _incrementProfile('training_sessions_started', 1);
  }

  void trackTrainingQuestion({
    required bool isCorrect,
    required String symbol,
    required String givenType,
    required String chooseType,
  }) {
    _track('training_question_answered', {
      'is_correct': isCorrect,
      'symbol': symbol,
      'given_type': givenType,
      'choose_type': chooseType,
    });
    _incrementProfile('questions_answered', 1);
    _incrementProfile(isCorrect ? 'questions_correct' : 'questions_wrong', 1);
  }

  void trackTrainingCompleted({
    required int totalCorrect,
    required int mistakes,
  }) {
    _track('training_completed', {
      'total_correct': totalCorrect,
      'mistakes': mistakes,
    });
    _incrementProfile('training_sessions_completed', 1);
  }

  void trackTrainingExit({
    required int progress,
    required int mistakes,
  }) {
    _track('training_exited', {
      'total_correct': progress,
      'mistakes': mistakes,
    });
  }

  void trackAdShown(String trigger) {
    _track('interstitial_shown', {'trigger': trigger});
  }

  void _track(String eventName, [Map<String, dynamic>? props]) {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;
    try {
      mixpanel.track(eventName, properties: props);
    } catch (error) {
      debugPrint('Failed to track $eventName: $error');
    }
  }

  void _setProfileValue(String key, Object value) {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;
    try {
      mixpanel.getPeople().set(key, value);
    } catch (error) {
      debugPrint('Failed to update Mixpanel profile: $error');
    }
  }

  void _incrementProfile(String key, num amount) {
    final mixpanel = _mixpanel;
    if (mixpanel == null) return;
    try {
      mixpanel.getPeople().increment(key, amount.toDouble());
    } catch (error) {
      debugPrint('Failed to increment Mixpanel profile: $error');
    }
  }

  String _generateDistinctId() {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buffer.write(alphabet[rand.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }
}
