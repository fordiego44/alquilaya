import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

Contrato contratoDePrueba({DateTime? fechaInicio, DateTime? fechaFin}) =>
    Contrato(
      id: 'c1',
      habitacionId: 'h1',
      inquilinoId: 'i1',
      fechaInicio: fechaInicio ?? DateTime(2026, 8, 20),
      montoMensual: Dinero(35000),
      fechaFin: fechaFin,
    );

void main() {
  group('Contrato', () {
    test('el monto mensual debe ser positivo', () {
      expect(
        () => Contrato(
          id: 'c1',
          habitacionId: 'h1',
          inquilinoId: 'i1',
          fechaInicio: DateTime(2026, 8, 20),
          montoMensual: Dinero.cero,
        ),
        throwsArgumentError,
      );
    });

    test('rechaza referencias vacías', () {
      expect(
        () => Contrato(
          id: 'c1',
          habitacionId: '',
          inquilinoId: 'i1',
          fechaInicio: DateTime(2026, 8, 20),
          montoMensual: Dinero(35000),
        ),
        throwsArgumentError,
      );
    });

    test('está activo mientras no tenga fecha de fin', () {
      expect(contratoDePrueba().estaActivo, isTrue);
      expect(
        contratoDePrueba(fechaFin: DateTime(2026, 12, 31)).estaActivo,
        isFalse,
      );
    });

    test('el día base de cobro es el día de la fecha de inicio', () {
      expect(contratoDePrueba().diaBaseDeCobro, 20);
      expect(
        contratoDePrueba(fechaInicio: DateTime(2026, 1, 31)).diaBaseDeCobro,
        31,
      );
    });

    test('la fecha de fin no puede ser anterior al inicio', () {
      expect(
        () => contratoDePrueba(fechaFin: DateTime(2026, 8, 19)),
        throwsArgumentError,
      );
      expect(() => contratoDePrueba().finalizar(DateTime(2026, 8, 19)),
          throwsArgumentError);
    });

    test('finalizar devuelve una copia y no muta el original', () {
      final activo = contratoDePrueba();
      final finalizado = activo.finalizar(DateTime(2026, 12, 31));

      expect(activo.estaActivo, isTrue);
      expect(activo.fechaFin, isNull);
      expect(finalizado.estaActivo, isFalse);
      expect(finalizado.fechaFin, DateTime(2026, 12, 31));
      expect(finalizado.montoMensual, activo.montoMensual);
    });

    test('un contrato ya finalizado no se finaliza de nuevo', () {
      final finalizado = contratoDePrueba().finalizar(DateTime(2026, 12, 31));
      expect(
        () => finalizado.finalizar(DateTime(2027, 1, 31)),
        throwsStateError,
      );
    });

    test('la igualdad es por id: el contrato finalizado sigue siendo el mismo', () {
      final activo = contratoDePrueba();
      expect(activo.finalizar(DateTime(2026, 12, 31)), activo);
    });
  });
}
