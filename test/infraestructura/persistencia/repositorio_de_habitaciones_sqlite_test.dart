import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/infraestructura/persistencia/repositorio_de_habitaciones_sqlite.dart';
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
  });
}
