import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocray_advmobprog/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('counter and theme switch work together', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeModel(),
        child: const MyApp(),
      ),
    );

    MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.light);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.dark);
  });
}
