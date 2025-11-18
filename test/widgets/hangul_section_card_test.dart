import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhangul/widgets.dart';
import 'package:learnhangul/design_system.dart';
import 'package:learnhangul/models.dart';

void main() {
  testWidgets(
    'HangulSectionCard hides header when showHeader=false and uses Wrap',
    (tester) async {
      final section = HangulSection(
        title: 'Test Title',
        description: 'Test description',
        characters: [
          HangulCharacter(
            symbol: 'ㄱ',
            name: '기역',
            romanization: 'g',
            example: '',
            type: HangulCharacterType.consonant,
          ),
          HangulCharacter(
            symbol: 'ㄴ',
            name: '니은',
            romanization: 'n',
            example: '',
            type: HangulCharacterType.consonant,
          ),
          HangulCharacter(
            symbol: 'ㄷ',
            name: '디귿',
            romanization: 'd',
            example: '',
            type: HangulCharacterType.consonant,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: LearnHangulTheme.light(),
          home: Scaffold(
            body: HangulSectionCard(
              section: section,
              onCharacterTap: (_) {},
              showHeader: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // There should be no header text
      expect(find.text('Test Title'), findsNothing);
      expect(find.text('Test description'), findsNothing);

      // There should be a Wrap widget used for the tiles
      expect(find.byType(Wrap), findsOneWidget);

      // And the tiles should be present with their symbols
      expect(find.text('ㄱ'), findsOneWidget);
      expect(find.text('ㄴ'), findsOneWidget);
      expect(find.text('ㄷ'), findsOneWidget);
    },
  );
}
