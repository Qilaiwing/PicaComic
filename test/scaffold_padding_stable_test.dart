import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pica_comic/components/components.dart';

// Regression: the content top padding must be final on frame 0 (no "bounce"
// when a page opens) and the large title must render at its measured height.
void main() {
  for (final withBottom in [false, true]) {
    testWidgets('scaffold top padding is stable (bottom=$withBottom)',
        (tester) async {
      final tops = <double>[];
      await tester.pumpWidget(MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.light(),
          child: Material(
            child: MiuixScaffold(
              topBar: MiuixTopAppBar(
                title: 'Settings',
                bottomContent: withBottom ? const SizedBox(height: 44) : null,
                bottomContentHeightHint: withBottom ? 44 : 0,
              ),
              content: (p) {
                tops.add(p.top);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tops.toSet().length, 1, reason: '$tops');
      for (final e in find.text('Settings').evaluate()) {
        if ((e.widget as Text).style?.fontSize == 25) {
          expect(DefaultTextStyle.of(e).style.height, isNull);
        }
      }
    });
  }
}
