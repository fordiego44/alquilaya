import 'package:alquilaya/presentacion/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dobles/dependencias_en_memoria.dart';

/// La puerta de autenticación decide qué se ve al arrancar y reacciona cuando
/// la sesión cambia. Todo pasa por `AutenticacionEnMemoria`: no hay Supabase ni
/// red en estas pruebas.
void main() {
  testWidgets('con sesión entra directamente a la navegación', (tester) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria(autenticado: true)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsNothing);
  });

  testWidgets('sin sesión muestra el login y no la navegación', (tester) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria(autenticado: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Lo que hay detrás del login no debe estar montado.
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('al iniciar sesión la interfaz pasa a la navegación', (
    tester,
  ) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria(autenticado: false)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'ana@ejemplo.com');
    await tester.enterText(find.byType(TextField).at(1), 'una-contrasena');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    // El cambio no lo hace la pantalla navegando: lo hace la puerta al recibir
    // el evento de sesión.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Correo'), findsNothing);
  });
}
