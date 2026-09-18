// Smoke test: la app arranca y muestra la pantalla de login cuando no hay sesión.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rumbo/main.dart';

void main() {
  testWidgets('Muestra el login cuando no hay sesión activa', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const RumboApp());
    await tester.pump();

    expect(find.text('Rumbo'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
