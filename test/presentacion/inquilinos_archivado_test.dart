import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/presentacion/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dobles/dependencias_en_memoria.dart';

void main() {
  Future<void> abrirInquilinos(
    WidgetTester tester, {
    List<Habitacion> habitaciones = const [],
    List<Inquilino> inquilinos = const [],
    List<Contrato> contratos = const [],
  }) async {
    await tester.pumpWidget(
      AlquilaYaApp(
        dependencias: dependenciasEnMemoria(
          habitaciones: habitaciones,
          inquilinos: inquilinos,
          contratos: contratos,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inquilinos'));
    await tester.pumpAndSettle();
  }

  Future<void> elegirEnElMenu(WidgetTester tester, String accion) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(accion));
    await tester.pumpAndSettle();
  }

  testWidgets('alternar Activos y Archivados cambia lo que se ve', (
    tester,
  ) async {
    await abrirInquilinos(
      tester,
      inquilinos: [
        Inquilino(id: 'i1', nombre: 'Ana Torres'),
        Inquilino(id: 'i2', nombre: 'Luis Vega').archivar(),
      ],
    );

    expect(find.text('Ana Torres'), findsOneWidget);
    expect(find.text('Luis Vega'), findsNothing);

    await tester.tap(find.text('Archivados'));
    await tester.pumpAndSettle();

    expect(find.text('Luis Vega'), findsOneWidget);
    expect(find.text('Ana Torres'), findsNothing);
    expect(find.text('Archivado'), findsOneWidget);
  });

  testWidgets('archivar quita al inquilino de Activos', (tester) async {
    await abrirInquilinos(
      tester,
      inquilinos: [Inquilino(id: 'i1', nombre: 'Ana Torres')],
    );

    await elegirEnElMenu(tester, 'Archivar');

    expect(find.text('Ana Torres'), findsNothing);
    expect(find.text('Todavía no hay inquilinos'), findsOneWidget);

    await tester.tap(find.text('Archivados'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Torres'), findsOneWidget);
  });

  testWidgets('eliminar a alguien con historial avisa y no lo elimina', (
    tester,
  ) async {
    await abrirInquilinos(
      tester,
      habitaciones: [Habitacion(id: 'h1', nombre: 'Habitación 1')],
      inquilinos: [Inquilino(id: 'i1', nombre: 'Ana Torres')],
      contratos: [
        Contrato(
          id: 'c1',
          habitacionId: 'h1',
          inquilinoId: 'i1',
          fechaInicio: DateTime(2026, 8, 20),
          montoMensual: Dinero(35000),
          fechaFin: DateTime(2026, 9, 30),
        ),
      ],
    );

    await elegirEnElMenu(tester, 'Eliminar');

    expect(find.text('Eliminar inquilino'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Ese inquilino tiene contratos. Archívalo para conservar el historial.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ana Torres'), findsOneWidget);
  });
}
