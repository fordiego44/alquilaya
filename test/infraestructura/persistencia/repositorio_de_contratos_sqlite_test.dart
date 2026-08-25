import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_contratos_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_cuotas_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_habitaciones_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_inquilinos_sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'base_de_datos_de_prueba.dart';

void main() {
  setUpAll(inicializarSqliteParaTests);

  group('RepositorioDeContratosSqlite', () {
    final montoMensual = Dinero(35000);
    final inicio = DateTime(2026, 8, 20);

    late Database db;
    late RepositorioDeContratosSqlite repositorio;

    Contrato contrato(String id, String habitacionId, {DateTime? fechaFin}) =>
        Contrato(
          id: id,
          habitacionId: habitacionId,
          inquilinoId: 'i1',
          fechaInicio: inicio,
          montoMensual: montoMensual,
          fechaFin: fechaFin,
        );

    setUp(() async {
      db = await abrirBaseEnMemoria();
      repositorio = RepositorioDeContratosSqlite(db);

      // Las claves foráneas están activas: sin habitación e inquilino no se
      // puede insertar ningún contrato.
      final habitaciones = RepositorioDeHabitacionesSqlite(db);
      await habitaciones.guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await habitaciones.guardar(Habitacion(id: 'h2', nombre: 'Habitación 2'));
      await RepositorioDeInquilinosSqlite(
        db,
      ).guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));
    });

    tearDown(() => db.close());

    test('guarda un contrato y lo recupera con todos sus datos', () async {
      await repositorio.guardar(contrato('c1', 'h1'));

      final recuperado = await repositorio.obtenerPorId('c1');

      expect(recuperado?.habitacionId, 'h1');
      expect(recuperado?.inquilinoId, 'i1');
      expect(recuperado?.fechaInicio, inicio);
      expect(recuperado?.montoMensual, montoMensual);
      expect(recuperado?.fechaFin, isNull);
      expect(recuperado?.estaActivo, isTrue);
    });

    test('devuelve null si no existe', () async {
      expect(await repositorio.obtenerPorId('inexistente'), isNull);
    });

    test('lista los contratos, activos y finalizados', () async {
      await repositorio.guardar(contrato('c1', 'h1'));
      await repositorio.guardar(
        contrato('c2', 'h2', fechaFin: DateTime(2026, 10, 15)),
      );

      expect((await repositorio.listar()).map((c) => c.id).toSet(), {
        'c1',
        'c2',
      });
    });

    test('tieneContratoActivo solo cuenta los que siguen vigentes', () async {
      await repositorio.guardar(contrato('c1', 'h1'));
      await repositorio.guardar(
        contrato('c2', 'h2', fechaFin: DateTime(2026, 10, 15)),
      );

      expect(await repositorio.tieneContratoActivo('h1'), isTrue);
      expect(await repositorio.tieneContratoActivo('h2'), isFalse);
      expect(await repositorio.tieneContratoActivo('h9'), isFalse);
    });

    test('habitacionesOcupadas devuelve las de contratos activos', () async {
      await repositorio.guardar(contrato('c1', 'h1'));
      await repositorio.guardar(
        contrato('c2', 'h2', fechaFin: DateTime(2026, 10, 15)),
      );

      expect(await repositorio.habitacionesOcupadas(), {'h1'});
    });

    test('finalizar un contrato lo saca de las habitaciones ocupadas',
        () async {
      await repositorio.guardar(contrato('c1', 'h1'));

      final finalizado = (await repositorio.obtenerPorId(
        'c1',
      ))!.finalizar(DateTime(2026, 10, 15));
      await repositorio.guardar(finalizado);

      expect(await repositorio.habitacionesOcupadas(), isEmpty);
      expect(
        (await repositorio.obtenerPorId('c1'))?.fechaFin,
        DateTime(2026, 10, 15),
      );
    });

    test('finalizar un contrato con cuotas no las elimina ni rompe la FK',
        () async {
      // Con INSERT OR REPLACE, guardar el contrato ya existente borraría su
      // fila para reinsertarla y arrastraría o invalidaría estas cuotas.
      await repositorio.guardar(contrato('c1', 'h1'));
      final cuotas = RepositorioDeCuotasSqlite(db);
      await cuotas.guardarTodas([
        Cuota(
          id: 'cu1',
          contratoId: 'c1',
          periodo: Periodo(2026, 8),
          monto: montoMensual,
          fechaVencimiento: DateTime(2026, 8, 20),
        ),
        Cuota(
          id: 'cu2',
          contratoId: 'c1',
          periodo: Periodo(2026, 9),
          monto: montoMensual,
          fechaVencimiento: DateTime(2026, 9, 20),
        ),
      ]);

      final finalizado = (await repositorio.obtenerPorId(
        'c1',
      ))!.finalizar(DateTime(2026, 10, 15));
      await repositorio.guardar(finalizado);

      expect(await cuotas.deContrato('c1'), hasLength(2));
      expect((await repositorio.obtenerPorId('c1'))?.estaActivo, isFalse);
    });

    test('no admite un contrato sobre una habitación inexistente', () async {
      expect(
        () => repositorio.guardar(contrato('c1', 'h9')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
