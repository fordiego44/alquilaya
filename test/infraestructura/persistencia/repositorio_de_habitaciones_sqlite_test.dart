import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_contratos_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_habitaciones_sqlite.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_inquilinos_sqlite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'base_de_datos_de_prueba.dart';

void main() {
  setUpAll(inicializarSqliteParaTests);

  group('RepositorioDeHabitacionesSqlite', () {
    late Database db;
    late RepositorioDeHabitacionesSqlite repositorio;

    setUp(() async {
      db = await abrirBaseEnMemoria();
      repositorio = RepositorioDeHabitacionesSqlite(db);
    });

    tearDown(() => db.close());

    test('guarda una habitación y la recupera por id', () async {
      await repositorio.guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));

      final recuperada = await repositorio.obtenerPorId('h1');

      expect(recuperada?.id, 'h1');
      expect(recuperada?.nombre, 'Habitación 1');
    });

    test('devuelve null si no existe', () async {
      expect(await repositorio.obtenerPorId('inexistente'), isNull);
    });

    test('lista todas las habitaciones guardadas', () async {
      await repositorio.guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await repositorio.guardar(Habitacion(id: 'h2', nombre: 'Habitación 2'));

      final listado = await repositorio.listar();

      expect(listado.map((h) => h.id).toSet(), {'h1', 'h2'});
    });

    test('sin habitaciones el listado está vacío', () async {
      expect(await repositorio.listar(), isEmpty);
    });

    test('guardar con un id existente actualiza en lugar de duplicar',
        () async {
      await repositorio.guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await repositorio.guardar(Habitacion(id: 'h1', nombre: 'Suite'));

      expect(await repositorio.listar(), hasLength(1));
      expect((await repositorio.obtenerPorId('h1'))?.nombre, 'Suite');
    });

    test('eliminar quita una habitación sin contratos', () async {
      await repositorio.guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await repositorio.guardar(Habitacion(id: 'h2', nombre: 'Habitación 2'));

      await repositorio.eliminar('h1');

      expect(await repositorio.obtenerPorId('h1'), isNull);
      expect((await repositorio.listar()).map((h) => h.id), ['h2']);
    });

    test('eliminar un id inexistente no falla', () async {
      await repositorio.eliminar('inexistente');
      expect(await repositorio.listar(), isEmpty);
    });

    // La clave foránea es la última barrera: aunque el caso de uso fallara en
    // comprobarlo, el contrato nunca queda apuntando a una habitación borrada.
    test('no deja eliminar una habitación referenciada por un contrato', () async {
      await repositorio.guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
      await RepositorioDeInquilinosSqlite(
        db,
      ).guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));
      await RepositorioDeContratosSqlite(db).guardar(
        Contrato(
          id: 'c1',
          habitacionId: 'h1',
          inquilinoId: 'i1',
          fechaInicio: DateTime(2026, 8, 20),
          montoMensual: Dinero(35000),
        ),
      );

      await expectLater(
        repositorio.eliminar('h1'),
        throwsA(isA<DatabaseException>()),
      );

      expect(await repositorio.obtenerPorId('h1'), isNotNull);
    });

    test('una habitación nueva se recupera como no archivada', () async {
      await repositorio.guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));

      expect((await repositorio.obtenerPorId('h1'))?.archivada, isFalse);
    });

    test('una habitación archivada se guarda y se recupera archivada', () async {
      await repositorio.guardar(
        Habitacion(id: 'h1', nombre: 'Habitación 1').archivar(),
      );

      final recuperada = await repositorio.obtenerPorId('h1');

      expect(recuperada?.archivada, isTrue);
      // Archivar no toca el resto de los datos.
      expect(recuperada?.nombre, 'Habitación 1');
    });

    test('guardar la versión reactivada vuelve a persistir false', () async {
      final habitacion = Habitacion(id: 'h1', nombre: 'Habitación 1');
      await repositorio.guardar(habitacion.archivar());

      await repositorio.guardar(habitacion.archivar().reactivar());

      expect((await repositorio.obtenerPorId('h1'))?.archivada, isFalse);
      expect(await repositorio.listar(), hasLength(1));
    });
  });
}
