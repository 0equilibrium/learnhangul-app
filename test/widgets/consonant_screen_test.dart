import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhangul/screens.dart';
import 'package:learnhangul/design_system.dart';

void main() {
  testWidgets('ConsonantLearningScreen hides section titles', (tester) async {
    // Ensure a larger window to avoid small-screen overflow in tests.
    tester.binding.window.physicalSizeTestValue = const Size(1200, 2400);
    addTearDown(() => tester.binding.window.clearPhysicalSizeTestValue());

    await tester.pumpWidget(
      MaterialApp(
        theme: LearnHangulTheme.light(),
        home: const ConsonantLearningScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Sections in models.dart have titles like '기본 자음', ensure not present
    expect(find.text('기본 자음'), findsNothing);
    expect(find.text('격음 자음'), findsNothing);
    expect(find.text('쌍자음'), findsNothing);
  });
}
