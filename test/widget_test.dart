// Prueba de humo básica: verifica la pantalla inicial según configuración del servidor.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anomaliagw_mobile/main.dart';
import 'package:anomaliagw_mobile/screens/server_config_screen.dart';

void main() {
  testWidgets('La app arranca mostrando la pantalla de configuración de servidor cuando no hay servidor configurado',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AnomaliaApp());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(ServerConfigScreen), findsOneWidget);
  });
}
