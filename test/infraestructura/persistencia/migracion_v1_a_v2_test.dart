import 'dart:io';

import 'package:alquilaya/infraestructura/persistencia/base_de_datos.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_contratos_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_habitaciones_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_inquilinos_sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'base_de_datos_de_prueba.dart';

/// El esquema **v1**, copiado tal y como se distribuyó: sin las columnas de
/// archivado y con las mismas claves foráneas.
///
/// Se escribe aquí a propósito en lugar de reutilizar el de producción, que ya
/// es v2. Una migración solo se prueba de verdad partiendo del esquema viejo
/// real, así que esta copia queda congelada y no debe seguir su evolución.
Future<void> _crearEsquemaV1(Database db, int version) async {
  await db.execute('''
    CREATE TABLE habitaciones (
      id      TEXT PRIMARY KEY,
      nombre  TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE inquilinos (
      id         TEXT PRIMARY KEY,
      nombre     TEXT NOT NULL,
      documento  TEXT,
      telefono   TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE contratos (
      id                      TEXT PRIMARY KEY,
      habitacion_id           TEXT NOT NULL REFERENCES habitaciones(id),
      inquilino_id            TEXT NOT NULL REFERENCES inquilinos(id),
      fecha_inicio            TEXT NOT NULL,
      monto_mensual_centavos  INTEGER NOT NULL,
      fecha_fin               TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE cuotas (
      id                 TEXT PRIMARY KEY,
      contrato_id        TEXT NOT NULL REFERENCES contratos(id),
      periodo_anio       INTEGER NOT NULL,
      periodo_mes        INTEGER NOT NULL,
      monto_centavos     INTEGER NOT NULL,
      fecha_vencimiento  TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE pagos (
      id              TEXT PRIMARY KEY,
      cuota_id        TEXT NOT NULL REFERENCES cuotas(id),
      monto_centavos  INTEGER NOT NULL,
      fecha_pago      TEXT NOT NULL
    )
  ''');
}

void main() {
  setUpAll(inicializarSqliteParaTests);

  group('migración v1 -> v2', () {
    late Directory carpeta;
    late String ruta;

    setUp(() async {
      carpeta = await Directory.systemTemp.createTemp('alquilaya_migracion_');
      ruta = '${carpeta.path}${Platform.pathSeparator}alquilaya.db';
    });

    tearDown(() => carpeta.delete(recursive: true));

    /// Deja en [ruta] una base v1 con datos, como la de alguien que ya tenía la
    /// app instalada. Escribe por SQL directo: los repositorios de hoy ya
    /// esperan columnas que en v1 no existen.
    Future<void> instalacionV1ConDatos() async {
      final db = await openDatabase(
        ruta,
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _crearEsquemaV1,
      );

      await db.insert('habitaciones', {'id': 'h1', 'nombre': 'Habitación 1'});
      await db.insert('inquilinos', {
        'id': 'i1',
        'nombre': 'Ana Torres',
        'documento': '12345678',
        'telefono': null,
      });
      await db.insert('contratos', {
        'id': 'c1',
        'habitacion_id': 'h1',
        'inquilino_id': 'i1',
        'fecha_inicio': '2026-08-20T00:00:00.000',
        'monto_mensual_centavos': 35000,
        'fecha_fin': null,
      });

      expect(await db.getVersion(), 1);
      await db.close();
    }

    test('la base queda en la versión 2 tras abrirla', () async {
      await instalacionV1ConDatos();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      expect(await db.getVersion(), 2);
    });

    test('las filas que ya existían se conservan', () async {
      await instalacionV1ConDatos();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      final habitacion = await RepositorioDeHabitacionesSqlite(
        db,
      ).obtenerPorId('h1');
      final inquilino = await RepositorioDeInquilinosSqlite(
        db,
      ).obtenerPorId('i1');

      expect(habitacion?.nombre, 'Habitación 1');
      expect(inquilino?.nombre, 'Ana Torres');
      expect(inquilino?.documento, '12345678');
      expect(inquilino?.telefono, isNull);
    });

    test('lo que ya existía queda activo, no archivado', () async {
      await instalacionV1ConDatos();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      expect(
        (await RepositorioDeHabitacionesSqlite(
          db,
        ).obtenerPorId('h1'))?.archivada,
        isFalse,
      );
      expect(
        (await RepositorioDeInquilinosSqlite(db).obtenerPorId('i1'))?.archivado,
        isFalse,
      );
    });

    // Añadir una columna no debe tocar las relaciones: el contrato que ya
    // existía sigue apuntando a la misma habitación y al mismo inquilino.
    test('el contrato existente sobrevive con sus referencias', () async {
      await instalacionV1ConDatos();

      final db = await abrirBaseDeDatos(ruta: ruta);
      addTearDown(db.close);

      final contratos = RepositorioDeContratosSqlite(db);
      final contrato = await contratos.obtenerPorId('c1');

      expect(contrato, isNotNull);
      expect(contrato!.habitacionId, 'h1');
      expect(contrato.inquilinoId, 'i1');
      expect(contrato.estaActivo, isTrue);
      expect(await contratos.habitacionesOcupadas(), {'h1'});
    });
  });

  group('instalación nueva', () {
    late Directory carpeta;

    setUp(() async {
      carpeta = await Directory.systemTemp.createTemp('alquilaya_nueva_');
    });

    tearDown(() => carpeta.delete(recursive: true));

    // onCreate tiene que crear ya el esquema v2: una instalación nueva nunca
    // pasa por onUpgrade, así que si se quedara en v1 nacería incompleta.
    test('crea directamente el esquema v2, sin migrar', () async {
      final db = await abrirBaseDeDatos(
        ruta: '${carpeta.path}${Platform.pathSeparator}alquilaya.db',
      );
      addTearDown(db.close);

      expect(await db.getVersion(), 2);

      final habitaciones = await db.rawQuery('PRAGMA table_info(habitaciones)');
      final archivada = habitaciones.firstWhere((c) => c['name'] == 'archivada');
      expect(archivada['notnull'], 1);
      expect(archivada['dflt_value'], '0');

      final inquilinos = await db.rawQuery('PRAGMA table_info(inquilinos)');
      final archivado = inquilinos.firstWhere((c) => c['name'] == 'archivado');
      expect(archivado['notnull'], 1);
      expect(archivado['dflt_value'], '0');
    });
  });
}
