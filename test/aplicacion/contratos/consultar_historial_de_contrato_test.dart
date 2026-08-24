import 'package:alquilaya/aplicacion/contratos/consultar_historial_de_contrato.dart';
import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('ConsultarHistorialDeContrato', () {
    final monto = Dinero(35000);

    Cuota cuota(String id, String contratoId, int mes) => Cuota(
      id: id,
      contratoId: contratoId,
      periodo: Periodo(2026, mes),
      monto: monto,
      fechaVencimiento: DateTime(2026, mes, 20),
    );

    late RepositorioDePagosEnMemoria pagos;
    late ConsultarHistorialDeContrato consultar;

    setUp(() {
      pagos = RepositorioDePagosEnMemoria([
        Pago(
          id: 'p1',
          cuotaId: 'cu1',
          monto: monto,
          fechaPago: DateTime(2026, 8, 20),
        ),
        // Pago de otro contrato: no debe aparecer en este historial.
        Pago(
          id: 'p2',
          cuotaId: 'cu9',
          monto: monto,
          fechaPago: DateTime(2026, 9, 20),
        ),
      ]);
      consultar = ConsultarHistorialDeContrato(
        RepositorioDeContratosEnMemoria([
          Contrato(
            id: 'c1',
            habitacionId: 'h1',
            inquilinoId: 'i1',
            fechaInicio: DateTime(2026, 8, 20),
            montoMensual: monto,
          ),
        ]),
        RepositorioDeCuotasEnMemoria([
          cuota('cu2', 'c1', 9),
          cuota('cu1', 'c1', 8),
          cuota('cu9', 'c2', 9),
        ]),
        pagos,
      );
    });

    test('devuelve el contrato con sus cuotas y sus pagos', () async {
      final historial = await consultar.ejecutar(
        contratoId: 'c1',
        hoy: DateTime(2026, 9, 25),
      );

      expect(historial.contrato.id, 'c1');
      expect(historial.cuotas.map((c) => c.cuota.id), ['cu1', 'cu2']);
      expect(historial.pagos.map((p) => p.id), ['p1']);
    });

    test('las cuotas van ordenadas por vencimiento y con su estado', () async {
      final historial = await consultar.ejecutar(
        contratoId: 'c1',
        hoy: DateTime(2026, 9, 25),
      );

      expect(historial.cuotas.map((c) => c.estado), [
        EstadoCuota.pagada,
        EstadoCuota.vencida,
      ]);
      expect(historial.cuotas.map((c) => c.montoPendiente), [
        Dinero.cero,
        monto,
      ]);
    });

    test('no incluye cuotas ni pagos de otros contratos', () async {
      final historial = await consultar.ejecutar(
        contratoId: 'c1',
        hoy: DateTime(2026, 9, 25),
      );

      expect(
        historial.cuotas.map((c) => c.cuota.contratoId),
        everyElement('c1'),
      );
      expect(historial.pagos.map((p) => p.cuotaId), isNot(contains('cu9')));
    });

    test('falla si el contrato no existe', () {
      expect(
        () => consultar.ejecutar(
          contratoId: 'inexistente',
          hoy: DateTime(2026, 9, 25),
        ),
        throwsA(isA<ContratoNoEncontrado>()),
      );
    });

    test('no genera cuotas que falten: es de solo lectura', () async {
      final historial = await consultar.ejecutar(
        contratoId: 'c1',
        hoy: DateTime(2027, 6, 1),
      );

      expect(historial.cuotas, hasLength(2));
    });
  });
}
