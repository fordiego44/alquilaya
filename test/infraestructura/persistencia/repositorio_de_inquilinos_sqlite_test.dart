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

  group('RepositorioDeInquilinosSqlite', () {
    late Database db;
    late RepositorioDeInquilinosSqlite repositorio;

    setUp(() async {
      db = await abrirBaseEnMemoria();
      repositorio = RepositorioDeInquilinosSqlite(db);
    });

    tearDown(() => db.close());

    test('guarda un inquilino completo y lo recupera por id', () async {
      await repositorio.guardar(
        Inquilino(
          id: 'i1',
          nombre: 'Ana Torres',
          documento: '12345678',
          telefono: '987654321',
        ),
      );

      final recuperado = await repositorio.obtenerPorId('i1');

      expect(recuperado?.nombre, 'Ana Torres');
      expect(recuperado?.documento, '12345678');
      expect(recuperado?.telefono, '987654321');
    });

    test('los datos no conocidos vuelven como null, no como cadena vacía',
        () async {
      await repositorio.guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));

      final recuperado = await repositorio.obtenerPorId('i1');

      expect(recuperado?.documento, isNull);
      expect(recuperado?.telefono, isNull);
    });

    test('devuelve null si no existe', () async {
      expect(await repositorio.obtenerPorId('inexistente'), isNull);
    });

    test('lista todos los inquilinos guardados', () async {
      await repositorio.guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));
      await repositorio.guardar(Inquilino(id: 'i2', nombre: 'Beto Ruiz'));

      expect((await repositorio.listar()).map((i) => i.id).toSet(), {
        'i1',
        'i2',
      });
    });

    test('guardar con un id existente actualiza, incluso a null', () async {
      await repositorio.guardar(
        Inquilino(id: 'i1', nombre: 'Ana Torres', telefono: '987654321'),
      );
      await repositorio.guardar(Inquilino(id: 'i1', nombre: 'Ana Torres Gil'));

      final recuperado = await repositorio.obtenerPorId('i1');

      expect(await repositorio.listar(), hasLength(1));
      expect(recuperado?.nombre, 'Ana Torres Gil');
      expect(recuperado?.telefono, isNull);
    });

    test('eliminar quita al inquilino sin contratos', () async {
      await repositorio.guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));
      await repositorio.guardar(Inquilino(id: 'i2', nombre: 'Juan Pérez'));

      await repositorio.eliminar('i1');

      expect(await repositorio.obtenerPorId('i1'), isNull);
      expect((await repositorio.listar()).map((i) => i.id), ['i2']);
    });

    test('eliminar un id inexistente no falla', () async {
      await repositorio.eliminar('inexistente');
      expect(await repositorio.listar(), isEmpty);
    });

    // Igual que en habitaciones: la clave foránea impide que un contrato quede
    // apuntando a un inquilino borrado.
    test('no deja eliminar un inquilino referenciado por un contrato', () async {
      await repositorio.guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));
      await RepositorioDeHabitacionesSqlite(
        db,
      ).guardar(Habitacion(id: 'h1', nombre: 'Habitación 1'));
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
        repositorio.eliminar('i1'),
        throwsA(isA<DatabaseException>()),
      );

      expect(await repositorio.obtenerPorId('i1'), isNotNull);
    });

    test('un inquilino nuevo se recupera como no archivado', () async {
      await repositorio.guardar(Inquilino(id: 'i1', nombre: 'Ana Torres'));

      expect((await repositorio.obtenerPorId('i1'))?.archivado, isFalse);
    });

    test('un inquilino archivado se guarda y se recupera archivado', () async {
      await repositorio.guardar(
        Inquilino(
          id: 'i1',
          nombre: 'Ana Torres',
          documento: '12345678',
          telefono: '951234567',
        ).archivar(),
      );

      final recuperado = await repositorio.obtenerPorId('i1');

      expect(recuperado?.archivado, isTrue);
      // Archivar no toca el resto de los datos.
      expect(recuperado?.nombre, 'Ana Torres');
      expect(recuperado?.documento, '12345678');
      expect(recuperado?.telefono, '951234567');
    });

    test('guardar la versión reactivada vuelve a persistir false', () async {
      final inquilino = Inquilino(id: 'i1', nombre: 'Ana Torres');
      await repositorio.guardar(inquilino.archivar());

      await repositorio.guardar(inquilino.archivar().reactivar());

      expect((await repositorio.obtenerPorId('i1'))?.archivado, isFalse);
      expect(await repositorio.listar(), hasLength(1));
    });
  });
}
