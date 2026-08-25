import 'package:alquilaya/dominio/entidades/inquilino.dart';
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
  });
}
