import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_liquid_glass_dialog.dart';

/// Checks whether a premium Korean voice is available to the TTS engine.
Future<bool> hasPremiumKoreanVoice() async {
  try {
    final flutterTts = FlutterTts();
    // getVoices is a getter that returns Future<dynamic>
    final voicesResult = await flutterTts.getVoices;
    final voices = voicesResult as List?;

    // Silent voice detection (no console logging)
    int koPremiumCount = 0;

    if (voices != null && voices.isNotEmpty) {
      for (final v in voices) {
        if (v is Map) {
          final locale = (v['locale'] ?? v['language'] ?? '') as String;
          final quality = (v['quality'] ?? '') as String;
          if (locale.toLowerCase().startsWith('ko') && quality == 'premium') {
            koPremiumCount++;
            break;
          }
        }
      }
    }

    return koPremiumCount > 0;
  } catch (_) {
    // Silent on errors
  }
  return false;
}

/// Shows a dialog that instructs the user how to download a premium Korean voice.
/// Returns true if a premium voice is present (either already or after re-check),
/// otherwise false.
Future<bool> showPremiumVoiceCheckDialog(BuildContext context) async {
  const kBypassKey = 'debug_bypass_premium_voice';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kBypassKey) ?? false) return true;
  } catch (_) {
    // ignore
  }

  final already = await hasPremiumKoreanVoice();
  if (!context.mounted) return false;
  if (already) return true;

  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Center(
            child: CustomLiquidGlassDialog(
              title: const Text('고품질 음성 필요'),
              content: const Text(
                '앱에서 고품질(프리미엄) 한국어 음성이 필요합니다.\n설정 > 접근성 > 말하기 > 음성에서 한국어 음성을 다운로드한 뒤 다시 확인하세요.',
              ),
              actions: [
                CustomLiquidGlassDialogAction(
                  isConfirmationBlue: true,
                  onPressed: () {
                    // Try to open the Settings app. On iOS, this opens the app's settings page,
                    // from which users can navigate to Accessibility > Spoken Content > Voices.
                    const url = 'app-settings:';
                    try {
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {
                      // ignore
                    }
                  },
                  child: const Text('설정 열기'),
                ),
                CustomLiquidGlassDialogAction(
                  isConfirmationBlue: false,
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    hasPremiumKoreanVoice().then((ok) {
                      if (navigator.mounted) navigator.pop(ok);
                    });
                  },
                  child: const Text('다시 확인'),
                ),
                CustomLiquidGlassDialogAction(
                  isConfirmationBlue: false,
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
              ],
            ),
          );
        },
      ) ??
      false;
}
