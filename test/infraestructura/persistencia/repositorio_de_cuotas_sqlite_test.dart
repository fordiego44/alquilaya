import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_contratos_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_cuotas_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_habitaciones_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_inquilinos_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_pagos_sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'base_de_datos_de_prueba.dart';

void main() {
  setUpAll(inicializarSqliteParaTests);

  group('RepositorioDeCuotasSqlite', () {
    final monto = Dinero(35000);

    late Database db;
    late RepositorioDeCuotasSqlite repositorio;

    Cuota cuota(String id, String contratoId, int mes) => Cuota(
      id: id,
      contratoId: contratoId,
      periodo: Periodo(2026, mes),
      monto: monto,
      fechaVencimiento: DateTime(2026, mes, 20),
    );

    setUp(() async {
      db = await abrirBaseEnMemoria();
      repositorio = RepositorioDeCuotasSqlite(db);

      await RepositorioDeHabitacionesSqlite(
        db,
      ).guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await RepositorioDeInquilinosSqlite(
        db,
      ).guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));
      final contratos = RepositorioDeContratosSqlite(db);
      for (final id in ['c1', 'c2']) {
        await contratos.guardar(
          Contrato(
            id: id,
            habitacionId: 'h1',
            inquilinoId: 'i1',
            fechaInicio: DateTime(2026, 8, 20),
            montoMensual: monto,
          ),
        );
      }
    });

    tearDown(() => db.close());

    test('guarda un lote y recupera por id', () async {
      await repositorio.guardarTodas([
        cuota('cu1', 'c1', 8),
        cuota('cu2', 'c1', 9),
      ]);

      final recuperada = await repositorio.obtenerPorId('cu1');

      expect(recuperada?.contratoId, 'c1');
      expect(recuperada?.periodo, Periodo(2026, 8));
      expect(recuperada?.monto, monto);
      expect(recuperada?.fechaVencimiento, DateTime(2026, 8, 20));
    });

    test('devuelve null si la cuota no existe', () async {
      expect(await repositorio.obtenerPorId('inexistente'), isNull);
    });

    test('deContrato devuelve solo las de ese contrato', () async {
      await repositorio.guardarTodas([
        cuota('cu1', 'c1', 8),
        cuota('cu2', 'c1', 9),
        cuota('cu3', 'c2', 8),
      ]);

      expect((await repositorio.deContrato('c1')).map((c) => c.id).toSet(), {
        'cu1',
        'cu2',
      });
    });

    test('todas devuelve las de cualquier contrato', () async {
      await repositorio.guardarTodas([
        cuota('cu1', 'c1', 8),
        cuota('cu3', 'c2', 8),
      ]);

      expect(await repositorio.todas(), hasLength(2));
    });

    test('elimina solo las cuotas indicadas', () async {
      await repositorio.guardarTodas([
        cuota('cu1', 'c1', 8),
        cuota('cu2', 'c1', 9),
        cuota('cu3', 'c2', 8),
      ]);

      await repositorio.eliminar(['cu1', 'cu3']);

      expect((await repositorio.todas()).map((c) => c.id), ['cu2']);
    });

    test('un lote vacío y una eliminación vacía no fallan', () async {
      await repositorio.guardarTodas([]);
      await repositorio.eliminar([]);

      expect(await repositorio.todas(), isEmpty);
    });

    test('volver a guardar una cuota con pagos los conserva y respeta la FK',
        () async {
      // Con INSERT OR REPLACE, la cuota se borraría y reinsertaría, dejando el
      // pago huérfano o haciendo fallar la clave foránea.
      await repositorio.guardarTodas([cuota('cu1', 'c1', 8)]);
      final pagos = RepositorioDePagosSqlite(db);
      await pagos.guardar(
        Pago(
          id: 'p1',
          cuotaId: 'cu1',
          monto: monto,
          fechaPago: DateTime(2026, 8, 20),
        ),
      );

      // La puesta al día vuelve a pasar por la misma cuota.
      await repositorio.guardarTodas([cuota('cu1', 'c1', 8)]);

      expect(await pagos.deCuotas(['cu1']), hasLength(1));
      expect(await repositorio.todas(), hasLength(1));
    });

    test('guardar una cuota existente la actualiza sin duplicar', () async {
      await repositorio.guardarTodas([cuota('cu1', 'c1', 8)]);
      await repositorio.guardarTodas([
        Cuota(
          id: 'cu1',
          contratoId: 'c1',
          periodo: Periodo(2026, 8),
          monto: Dinero(40000),
          fechaVencimiento: DateTime(2026, 8, 20),
        ),
      ]);

      expect(await repositorio.todas(), hasLength(1));
      expect((await repositorio.obtenerPorId('cu1'))?.monto, Dinero(40000));
    });
  });
}
