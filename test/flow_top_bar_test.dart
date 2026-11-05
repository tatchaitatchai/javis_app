import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:javis_app/core/theme/app_theme.dart';
import 'package:javis_app/core/widgets/calm_buttons.dart';
import 'package:javis_app/core/widgets/flow_page.dart';

void main() {
  testWidgets('Text actions in the top bar stay on one line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: calmTheme(Brightness.light),
        home: Scaffold(
          body: FlowTopBar(
            leading: QuietButton(label: 'Cancel', onPressed: () {}),
            center: const Text('Edit scene'),
            trailing: QuietButton(label: 'Save', onPressed: () {}),
          ),
        ),
      ),
    );

    const twoLines = 2 * 15.5 * 1.35;
    expect(tester.getSize(find.text('Cancel')).height, lessThan(twoLines));
    expect(tester.getSize(find.text('Save')).height, lessThan(twoLines));
    expect(tester.takeException(), isNull);
  });

  testWidgets('A title stays centered between empty and icon slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: calmTheme(Brightness.light),
        home: const Scaffold(
          body: FlowTopBar(
            leading: SizedBox.square(key: ValueKey('leading'), dimension: 40),
            center: Text('Title', key: ValueKey('title')),
          ),
        ),
      ),
    );

    final bar = tester.getSize(find.byType(FlowTopBar)).width;
    expect(tester.getCenter(find.byKey(const ValueKey('title'))).dx, bar / 2);
  });
}
