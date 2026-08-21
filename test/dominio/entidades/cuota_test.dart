import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

final monto = Dinero(35000);

Cuota cuotaDePrueba({DateTime? fechaVencimiento}) => Cuota(
  id: 'q1',
  contratoId: 'c1',
  periodo: Periodo(2026, 9),
  monto: monto,
  fechaVencimiento: fechaVencimiento ?? DateTime(2026, 9, 20),
);

Pago pagoDePrueba({String cuotaId = 'q1', Dinero? importe}) => Pago(
  id: 'p1',
  cuotaId: cuotaId,
  monto: importe ?? monto,
  fechaPago: DateTime(2026, 9, 20),
);

void main() {
  group('Cuota: estado derivado', () {
    test('sin pagos y antes del vencimiento está pendiente', () {
      expect(
        cuotaDePrueba().estadoSegun(const [], DateTime(2026, 9, 10)),
        EstadoCuota.pendiente,
      );
    });

    test('el mismo día del vencimiento todavía no está vencida', () {
      expect(
        cuotaDePrueba().estadoSegun(const [], DateTime(2026, 9, 20, 23, 59)),
        EstadoCuota.pendiente,
      );
    });

    test('pasado el vencimiento y sin pagar está vencida', () {
      expect(
        cuotaDePrueba().estadoSegun(const [], DateTime(2026, 9, 21)),
        EstadoCuota.vencida,
      );
    });

    test('pagada lo está aunque el vencimiento haya pasado', () {
      expect(
        cuotaDePrueba().estadoSegun([pagoDePrueba()], DateTime(2026, 12, 1)),
        EstadoCuota.pagada,
      );
    });

    test('el monto pendiente es el total, o cero si está saldada', () {
      final cuota = cuotaDePrueba();
      expect(cuota.montoPendiente(const []), monto);
      expect(cuota.montoPendiente([pagoDePrueba()]), Dinero.cero);
    });
  });

  group('Cuota: un pago salda la cuota entera', () {
    test('acepta el pago por el importe exacto', () {
      expect(
        () => cuotaDePrueba().validarPago(pagoDePrueba(), const []),
        returnsNormally,
      );
    });

    test('rechaza un pago parcial', () {
      expect(
        () => cuotaDePrueba()
            .validarPago(pagoDePrueba(importe: Dinero(20000)), const []),
        throwsArgumentError,
      );
    });

    test('rechaza un sobrepago', () {
      expect(
        () => cuotaDePrueba()
            .validarPago(pagoDePrueba(importe: Dinero(40000)), const []),
        throwsArgumentError,
      );
    });

    test('una cuota ya pagada no admite otro pago aunque el monto sea correcto', () {
      expect(
        () => cuotaDePrueba().validarPago(pagoDePrueba(), [pagoDePrueba()]),
        throwsStateError,
      );
    });

    test('rechaza un pago dirigido a otra cuota', () {
      expect(
        () => cuotaDePrueba().validarPago(pagoDePrueba(cuotaId: 'q2'), const []),
        throwsArgumentError,
      );
    });
  });

  group('Cuota: conservación al finalizar el contrato', () {
    // Día base 20, fin el 15/10/2026.
    final fechaFin = DateTime(2026, 10, 15);

    test('la que ya había vencido se conserva, pagada o no', () {
      final septiembre = cuotaDePrueba(fechaVencimiento: DateTime(2026, 9, 20));
      expect(septiembre.debeConservarseAlFinalizar(fechaFin, const []), isTrue);
    });

    test('la que vencía después del fin y no tiene pagos no se conserva', () {
      final octubre = cuotaDePrueba(fechaVencimiento: DateTime(2026, 10, 20));
      expect(octubre.debeConservarseAlFinalizar(fechaFin, const []), isFalse);
    });

    test('nunca se elimina una cuota con algún pago', () {
      final octubre = cuotaDePrueba(fechaVencimiento: DateTime(2026, 10, 20));
      expect(
        octubre.debeConservarseAlFinalizar(fechaFin, [pagoDePrueba()]),
        isTrue,
      );
    });

    test('la que vence justo el día del fin se conserva', () {
      final cuota = cuotaDePrueba(fechaVencimiento: fechaFin);
      expect(cuota.debeConservarseAlFinalizar(fechaFin, const []), isTrue);
    });
  });

  group('Cuota: solo cuentan sus propios pagos', () {
    final ajeno = pagoDePrueba(cuotaId: 'q2');

    test('el pago de otra cuota no la da por pagada', () {
      final cuota = cuotaDePrueba();
      expect(cuota.estaPagada([ajeno]), isFalse);
      expect(cuota.montoPendiente([ajeno]), monto);
      expect(
        cuota.estadoSegun([ajeno], DateTime(2026, 9, 21)),
        EstadoCuota.vencida,
      );
    });

    test('el pago de otra cuota no la salva de eliminarse al finalizar', () {
      final octubre = cuotaDePrueba(fechaVencimiento: DateTime(2026, 10, 20));
      expect(
        octubre.debeConservarseAlFinalizar(DateTime(2026, 10, 15), [ajeno]),
        isFalse,
      );
    });

    test('mezclando pagos, solo suma los propios', () {
      final cuota = cuotaDePrueba();
      expect(cuota.estaPagada([ajeno, pagoDePrueba()]), isTrue);
    });
  });
}
