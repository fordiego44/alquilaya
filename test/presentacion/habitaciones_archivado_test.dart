import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/presentacion/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dobles/dependencias_en_memoria.dart';

/// Archivar y eliminar desde la pantalla de habitaciones.
///
/// Todo se hace por la interfaz —menús, diálogos y pestañas— porque lo que se
/// prueba aquí es precisamente el cableado: las reglas ya tienen sus propios
/// tests en la capa de aplicación.
void main() {
  /// Deja la app abierta en la pestaña de habitaciones.
  Future<void> abrirHabitaciones(
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
    await tester.tap(find.text('Habitaciones'));
    await tester.pumpAndSettle();
  }

  /// Abre el menú de la única fila del listado y elige una acción.
  Future<void> elegirEnElMenu(WidgetTester tester, String accion) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(accion));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'una habitación archivada no aparece en Activas pero sí en Archivadas',
    (tester) async {
      await abrirHabitaciones(
        tester,
        habitaciones: [
          Habitacion(id: 'h1', nombre: 'Habitación 1'),
          Habitacion(id: 'h2', nombre: 'Habitación 2').archivar(),
        ],
      );

      expect(find.text('Habitación 1'), findsOneWidget);
      expect(find.text('Habitación 2'), findsNothing);

      await tester.tap(find.text('Archivadas'));
      await tester.pumpAndSettle();

      expect(find.text('Habitación 2'), findsOneWidget);
      expect(find.text('Habitación 1'), findsNothing);
      expect(find.text('Archivada'), findsOneWidget);
    },
  );

  testWidgets('archivar quita la habitación de Activas', (tester) async {
    await abrirHabitaciones(
      tester,
      habitaciones: [Habitacion(id: 'h1', nombre: 'Habitación 1')],
    );

    await elegirEnElMenu(tester, 'Archivar');

    expect(find.text('Habitación 1'), findsNothing);
    expect(find.text('Todavía no hay habitaciones'), findsOneWidget);

    // Y está donde debe: en la otra vista.
    await tester.tap(find.text('Archivadas'));
    await tester.pumpAndSettle();
    expect(find.text('Habitación 1'), findsOneWidget);
  });

  testWidgets('reactivar la quita de Archivadas y la devuelve a Activas', (
    tester,
  ) async {
    await abrirHabitaciones(
      tester,
      habitaciones: [Habitacion(id: 'h1', nombre: 'Habitación 1').archivar()],
    );

    await tester.tap(find.text('Archivadas'));
    await tester.pumpAndSettle();
    expect(find.text('Habitación 1'), findsOneWidget);

    await elegirEnElMenu(tester, 'Reactivar');

    expect(find.text('Habitación 1'), findsNothing);
    expect(find.text('No hay habitaciones archivadas'), findsOneWidget);

    await tester.tap(find.text('Activas'));
    await tester.pumpAndSettle();
    expect(find.text('Habitación 1'), findsOneWidget);
  });

  testWidgets('archivar una habitación ocupada avisa y no la archiva', (
    tester,
  ) async {
    await abrirHabitaciones(
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
        ),
      ],
    );

    await elegirEnElMenu(tester, 'Archivar');

    expect(
      find.text(
        'Esa habitación tiene un contrato activo. Finalízalo antes de '
        'archivarla.',
      ),
      findsOneWidget,
    );
    // Sigue donde estaba y sigue activa.
    expect(find.text('Habitación 1'), findsOneWidget);
    expect(find.text('Ocupada'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación y avisa si hay contratos', (
    tester,
  ) async {
    await abrirHabitaciones(
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

    // Eliminar es físico: primero se pregunta.
    expect(find.text('Eliminar habitación'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Esa habitación tiene contratos. Archívala para conservar el '
        'historial.',
      ),
      findsOneWidget,
    );
    expect(find.text('Habitación 1'), findsOneWidget);
  });
}
