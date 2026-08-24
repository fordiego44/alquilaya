import 'package:alquilaya/aplicacion/cuotas/listar_cuotas.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('ListarCuotas', () {
    final monto = Dinero(35000);

    /// Tres cuotas del contrato c1 —agosto, septiembre y octubre— y una de c2,
    /// para comprobar que la consulta cruza toda la cartera.
    Cuota cuota(String id, String contratoId, int mes) => Cuota(
      id: id,
      contratoId: contratoId,
      periodo: Periodo(2026, mes),
      monto: monto,
      fechaVencimiento: DateTime(2026, mes, 20),
    );

    late RepositorioDeCuotasEnMemoria cuotas;
    late RepositorioDePagosEnMemoria pagos;
    late ListarCuotas listar;

    setUp(() {
      cuotas = RepositorioDeCuotasEnMemoria([
        cuota('cu3', 'c1', 10),
        cuota('cu1', 'c1', 8),
        cuota('cu2', 'c1', 9),
        cuota('cu4', 'c2', 9),
      ]);
      pagos = RepositorioDePagosEnMemoria();
      listar = ListarCuotas(cuotas, pagos);
    });

    Future<void> pagar(String cuotaId, int mes) => pagos.guardar(
      Pago(
        id: 'p-$cuotaId',
        cuotaId: cuotaId,
        monto: monto,
        fechaPago: DateTime(2026, mes, 20),
      ),
    );

    test('sin filtro devuelve todas, ordenadas por vencimiento', () async {
      final resultado = await listar.ejecutar(hoy: DateTime(2026, 9, 25));

      expect(resultado.map((c) => c.cuota.id), ['cu1', 'cu2', 'cu4', 'cu3']);
    });

    test('deriva el estado a fecha de hoy', () async {
      await pagar('cu1', 8);

      final resultado = await listar.ejecutar(hoy: DateTime(2026, 9, 25));

      expect(
        {for (final c in resultado) c.cuota.id: c.estado},
        {
          'cu1': EstadoCuota.pagada,
          'cu2': EstadoCuota.vencida,
          'cu4': EstadoCuota.vencida,
          'cu3': EstadoCuota.pendiente,
        },
      );
    });

    test('filtra por vencidas', () async {
      await pagar('cu1', 8);

      final resultado = await listar.ejecutar(
        hoy: DateTime(2026, 9, 25),
        estado: EstadoCuota.vencida,
      );

      expect(resultado.map((c) => c.cuota.id), ['cu2', 'cu4']);
    });

    test('filtra por pagadas', () async {
      await pagar('cu1', 8);

      final resultado = await listar.ejecutar(
        hoy: DateTime(2026, 9, 25),
        estado: EstadoCuota.pagada,
      );

      expect(resultado.map((c) => c.cuota.id), ['cu1']);
    });

    test('próximos vencimientos: pendientes ordenadas por vencimiento',
        () async {
      final resultado = await listar.ejecutar(
        hoy: DateTime(2026, 8, 1),
        estado: EstadoCuota.pendiente,
      );

      expect(resultado.map((c) => c.cuota.id), ['cu1', 'cu2', 'cu4', 'cu3']);
    });

    test('expone el monto pendiente derivado', () async {
      await pagar('cu1', 8);

      final resultado = await listar.ejecutar(hoy: DateTime(2026, 9, 25));
      final porId = {for (final c in resultado) c.cuota.id: c.montoPendiente};

      expect(porId['cu1'], Dinero.cero);
      expect(porId['cu2'], monto);
    });

    test('un pago de otra cuota no da por saldada la propia', () async {
      await pagar('cu4', 9);

      final resultado = await listar.ejecutar(
        hoy: DateTime(2026, 9, 25),
        estado: EstadoCuota.pagada,
      );

      expect(resultado.map((c) => c.cuota.id), ['cu4']);
    });

    test('no persiste nada: es una consulta de solo lectura', () async {
      await listar.ejecutar(hoy: DateTime(2027, 1, 1));

      expect(await cuotas.todas(), hasLength(4));
      expect(await pagos.todos(), isEmpty);
    });
  });
}
