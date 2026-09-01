import 'package:alquilaya/presentacion/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widget_test.dart';

/// Reproduce el fallo visto en el emulador: al volver del formulario, la
/// habitación recién creada no aparece en el listado hasta cambiar de pestaña
/// y volver.
void main() {
  testWidgets('la habitación creada aparece al volver del formulario', (
    tester,
  ) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria()),
    );
    await tester.pumpAndSettle();

    // Inicio → Habitaciones.
    await tester.tap(find.text('Habitaciones'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay habitaciones'), findsOneWidget);

    // Abrir el formulario con el botón flotante.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Nueva habitación'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Habitación 1');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // De vuelta en el listado, sin haber cambiado de pestaña.
    expect(find.text('Nueva habitación'), findsNothing);
    expect(find.text('Habitación 1'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
  });
}
