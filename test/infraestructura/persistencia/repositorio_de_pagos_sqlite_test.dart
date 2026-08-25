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

  group('RepositorioDePagosSqlite', () {
    final monto = Dinero(35000);

    late Database db;
    late RepositorioDePagosSqlite repositorio;

    setUp(() async {
      db = await abrirBaseEnMemoria();
      repositorio = RepositorioDePagosSqlite(db);

      await RepositorioDeHabitacionesSqlite(
        db,
      ).guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await RepositorioDeInquilinosSqlite(
        db,
      ).guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));
      await RepositorioDeContratosSqlite(db).guardar(
        Contrato(
          id: 'c1',
          habitacionId: 'h1',
          inquilinoId: 'i1',
          fechaInicio: DateTime(2026, 8, 20),
          montoMensual: monto,
        ),
      );
      await RepositorioDeCuotasSqlite(db).guardarTodas([
        for (final (id, mes) in [('cu1', 8), ('cu2', 9)])
          Cuota(
            id: id,
            contratoId: 'c1',
            periodo: Periodo(2026, mes),
            monto: monto,
            fechaVencimiento: DateTime(2026, mes, 20),
          ),
      ]);
    });

    tearDown(() => db.close());

    test('guarda un pago y lo recupera por su cuota', () async {
      await repositorio.guardar(
        Pago(
          id: 'p1',
          cuotaId: 'cu1',
          monto: monto,
          fechaPago: DateTime(2026, 8, 20),
        ),
      );

      final recuperados = await repositorio.deCuotas(['cu1']);

      expect(recuperados, hasLength(1));
      expect(recuperados.single.id, 'p1');
      expect(recuperados.single.monto, monto);
      expect(recuperados.single.fechaPago, DateTime(2026, 8, 20));
    });

    test('deCuotas no devuelve pagos de otras cuotas', () async {
      await repositorio.guardar(
        Pago(
          id: 'p1',
          cuotaId: 'cu1',
          monto: monto,
          fechaPago: DateTime(2026, 8, 20),
        ),
      );
      await repositorio.guardar(
        Pago(
          id: 'p2',
          cuotaId: 'cu2',
          monto: monto,
          fechaPago: DateTime(2026, 9, 20),
        ),
      );

      expect((await repositorio.deCuotas(['cu2'])).single.id, 'p2');
      expect(
        (await repositorio.deCuotas(['cu1', 'cu2'])).map((p) => p.id).toSet(),
        {'p1', 'p2'},
      );
    });

    test('sin cuotas por las que preguntar devuelve una lista vacía', () async {
      // Ocurre de verdad: ListarCuotas y ConsultarDashboard llaman con el
      // resultado de cuotas.todas(), vacío en una base recién creada.
      expect(await repositorio.deCuotas([]), isEmpty);
    });

    test('no admite un pago sobre una cuota inexistente', () async {
      expect(
        () => repositorio.guardar(
          Pago(
            id: 'p1',
            cuotaId: 'inexistente',
            monto: monto,
            fechaPago: DateTime(2026, 8, 20),
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
