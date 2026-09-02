import 'package:alquilaya/presentacion/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles/dependencias_en_memoria.dart';

void main() {
  testWidgets('arranca en el panel con la base vacía', (tester) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria()),
    );
    // Las pantallas cargan sus datos de forma asíncrona.
    await tester.pumpAndSettle();

    // El panel es el destino inicial.
    expect(find.text('AlquilaYa'), findsOneWidget);
    expect(find.text('Ocupadas'), findsOneWidget);
    expect(find.text('Disponibles'), findsOneWidget);
    expect(find.text('Deuda vencida'), findsOneWidget);

    // Sin contratos no hay nada que cobrar, y se dice.
    expect(find.text('No hay cobros próximos.'), findsOneWidget);
  });

  testWidgets('ofrece los cinco destinos de la navegación', (tester) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final destino in [
      'Inicio',
      'Cuotas',
      'Contratos',
      'Habitaciones',
      'Inquilinos',
    ]) {
      expect(find.text(destino), findsOneWidget);
    }
  });
}
