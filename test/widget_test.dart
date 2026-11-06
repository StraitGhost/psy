import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psy/main.dart'; // Asegúrate de que el nombre de tu paquete sea 'psy' o 'psycase'

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // CORRECCIÓN AQUÍ: PsyCaseApp en lugar de MyApp
    await tester.pumpWidget(const PsyCaseApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}