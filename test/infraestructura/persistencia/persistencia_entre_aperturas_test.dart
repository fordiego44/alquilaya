import 'dart:io';

import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:alquilaya/infraestructura/persistencia/base_de_datos.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_contratos_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_cuotas_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_habitaciones_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_inquilinos_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_pagos_sqlite.dart';
import 'package:flutter_test/flutter_test.dart';

import 'base_de_datos_de_prueba.dart';

/// La razón de ser de la Fase 5: los datos tienen que seguir ahí cuando la app
/// se cierra y se vuelve a abrir.
///
/// Estos tests usan un fichero real —no una base en memoria— porque es lo único
/// que prueba de verdad que el estado cruza el cierre.
void main() {
  setUpAll(inicializarSqliteParaTests);

  group('persistencia entre aperturas', () {
    // Día base 31 para que el vencimiento de febrero caiga en el ajuste a fin
    // de mes (regla 8): si el round-trip de fechas alterara algo, se vería.
    final inicio = DateTime(2026, 1, 31);
    final montoMensual = Dinero(35050);

    late Directory carpeta;
    late String ruta;

    setUp(() async {
      carpeta = await Directory.systemTemp.createTemp('alquilaya_');
      ruta = '${carpeta.path}${Platform.pathSeparator}alquilaya.db';
    });

    tearDown(() => carpeta.delete(recursive: true));

    /// Escribe una vivienda completa y cierra la base, como haría la app al
    /// salir.
    Future<void> escribirYCerrar() async {
      final db = await abrirBaseDeDatos(ruta: ruta);

      await RepositorioDeHabitacionesSqlite(
        db,
      ).guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await RepositorioDeInquilinosSqlite(db).guardar(
        Inquilino(id: 'i1', nombre: 'Ana Torres', documento: '12345678'),
      );
      await RepositorioDeContratosSqlite(db).guardar(
        Contrato(
          id: 'c1',
          habitacionId: 'h1',
          inquilinoId: 'i1',
          fechaInicio: inicio,
          montoMensual: montoMensual,
        ),
      );
      await RepositorioDeCuotasSqlite(db).guardarTodas([
        Cuota(
          id: 'cu1',
          contratoId: 'c1',
          periodo: Periodo(2026, 1),
          monto: montoMensual,
          fechaVencimiento: DateTime(2026, 1, 31),
        ),
        Cuota(
          id: 'cu2',
          contratoId: 'c1',
          periodo: Periodo(2026, 2),
          monto: montoMensual,
          fechaVencimiento: DateTime(2026, 2, 28),
        ),
      ]);
      await RepositorioDePagosSqlite(db).guardar(
        Pago(
          id: 'p1',
          cuotaId: 'cu1',
          monto: montoMensual,
          fechaPago: inicio,
        ),
      );

      await db.close();
    }

    test('las cinco entidades siguen ahí tras reabrir la base', () async {
      await escribirYCerrar();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      expect(
        (await RepositorioDeHabitacionesSqlite(db).obtenerPorId('h1'))?.nombre,
        'Habitación 1',
      );
      final inquilino = await RepositorioDeInquilinosSqlite(
        db,
      ).obtenerPorId('i1');
      expect(inquilino?.nombre, 'Ana Torres');
      expect(inquilino?.documento, '12345678');
      expect(inquilino?.telefono, isNull);
      expect(
        await RepositorioDeContratosSqlite(db).obtenerPorId('c1'),
        isNotNull,
      );
      expect(await RepositorioDeCuotasSqlite(db).todas(), hasLength(2));
      expect(await RepositorioDePagosSqlite(db).deCuotas(['cu1']), hasLength(1));
    });

    test('las relaciones se conservan', () async {
      await escribirYCerrar();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      final contrato = (await RepositorioDeContratosSqlite(
        db,
      ).obtenerPorId('c1'))!;
      expect(contrato.habitacionId, 'h1');
      expect(contrato.inquilinoId, 'i1');

      final cuotas = await RepositorioDeCuotasSqlite(db).deContrato('c1');
      expect(cuotas.map((c) => c.contratoId), everyElement('c1'));

      final pagos = await RepositorioDePagosSqlite(db).deCuotas(['cu1']);
      expect(pagos.single.cuotaId, 'cu1');
    });

    test('la habitación sigue ocupada tras reabrir', () async {
      await escribirYCerrar();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      final contratos = RepositorioDeContratosSqlite(db);
      expect(await contratos.habitacionesOcupadas(), {'h1'});
      expect(await contratos.tieneContratoActivo('h1'), isTrue);
    });

    test('el dinero conserva los centavos exactos', () async {
      await escribirYCerrar();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      final contrato = (await RepositorioDeContratosSqlite(
        db,
      ).obtenerPorId('c1'))!;
      final pago = (await RepositorioDePagosSqlite(db).deCuotas(['cu1'])).single;

      // 35050 centavos = S/ 350.50. Nunca pasa por coma flotante.
      expect(contrato.montoMensual.centavos, 35050);
      expect(contrato.montoMensual, montoMensual);
      expect(pago.monto.centavos, 35050);
    });

    test('fechas y períodos hacen round-trip sin alterarse', () async {
      await escribirYCerrar();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      final contrato = (await RepositorioDeContratosSqlite(
        db,
      ).obtenerPorId('c1'))!;
      expect(contrato.fechaInicio, inicio);
      expect(contrato.diaBaseDeCobro, 31);
      expect(contrato.fechaFin, isNull);

      final cuotas = await RepositorioDeCuotasSqlite(db).deContrato('c1');
      final porId = {for (final cuota in cuotas) cuota.id: cuota};
      expect(porId['cu1']!.periodo, Periodo(2026, 1));
      expect(porId['cu1']!.fechaVencimiento, DateTime(2026, 1, 31));
      // El ajuste a fin de mes de la regla 8 vuelve tal cual.
      expect(porId['cu2']!.periodo, Periodo(2026, 2));
      expect(porId['cu2']!.fechaVencimiento, DateTime(2026, 2, 28));
    });

    test('un contrato finalizado antes de cerrar sigue finalizado', () async {
      await escribirYCerrar();

      final primera = await abrirBaseDeDatos(ruta: ruta);
      final contratos = RepositorioDeContratosSqlite(primera);
      await contratos.guardar(
        (await contratos.obtenerPorId('c1'))!.finalizar(DateTime(2026, 3, 15)),
      );
      await primera.close();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      final contrato = (await RepositorioDeContratosSqlite(
        db,
      ).obtenerPorId('c1'))!;
      expect(contrato.estaActivo, isFalse);
      expect(contrato.fechaFin, DateTime(2026, 3, 15));
      // Y sus cuotas y pagos siguen ahí (reglas 3 y 12).
      expect(await RepositorioDeCuotasSqlite(db).deContrato('c1'), hasLength(2));
      expect(await RepositorioDePagosSqlite(db).deCuotas(['cu1']), hasLength(1));
    });
  });
}
