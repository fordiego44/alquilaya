import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/presentacion/app.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dobles/dependencias_en_memoria.dart';

/// Archivar retira del futuro, no del pasado: un contrato antiguo tiene que
/// seguir diciendo con quién y dónde fue, aunque ambos estén archivados.
void main() {
  testWidgets(
    'un contrato de habitación e inquilino archivados conserva sus nombres',
    (tester) async {
      await tester.pumpWidget(
        AlquilaYaApp(
          dependencias: dependenciasEnMemoria(
            habitaciones: [
              Habitacion(id: 'h1', nombre: 'Habitación 1').archivar(),
            ],
            inquilinos: [Inquilino(id: 'i1', nombre: 'Ana Torres').archivar()],
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
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contratos'));
      await tester.pumpAndSettle();

      expect(find.text('Habitación 1 · Ana Torres'), findsOneWidget);
      expect(find.textContaining('eliminada'), findsNothing);
      expect(find.textContaining('eliminado'), findsNothing);
    },
  );
}
