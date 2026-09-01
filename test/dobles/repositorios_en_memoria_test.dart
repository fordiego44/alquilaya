import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'repositorio_de_habitaciones_en_memoria.dart';
import 'repositorio_de_inquilinos_en_memoria.dart';

/// Los dobles se ejercitan de sobra desde los tests de casos de uso, pero
/// `eliminar` todavía no tiene ningún consumidor: estas pruebas fijan su
/// contrato mientras llega.
void main() {
  group('RepositorioDeHabitacionesEnMemoria', () {
    test('guarda, obtiene y lista', () async {
      final repo = RepositorioDeHabitacionesEnMemoria();
      final habitacion = Habitacion(id: 'h1', nombre: 'Habitación 1');

      await repo.guardar(habitacion);

      expect(await repo.obtenerPorId('h1'), habitacion);
      expect(await repo.listar(), [habitacion]);
    });

    test('eliminar quita la habitación', () async {
      final repo = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
        Habitacion(id: 'h2', nombre: 'Habitación 2'),
      ]);

      await repo.eliminar('h1');

      expect(await repo.obtenerPorId('h1'), isNull);
      expect((await repo.listar()).map((h) => h.id), ['h2']);
    });

    test('eliminar un id inexistente no falla y es idempotente', () async {
      final repo = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
      ]);

      await repo.eliminar('no-existe');
      await repo.eliminar('h1');
      await repo.eliminar('h1');

      expect(await repo.listar(), isEmpty);
    });
  });

  group('RepositorioDeInquilinosEnMemoria', () {
    test('guarda, obtiene y lista', () async {
      final repo = RepositorioDeInquilinosEnMemoria();
      final inquilino = Inquilino(id: 'i1', nombre: 'Juan Pérez');

      await repo.guardar(inquilino);

      expect(await repo.obtenerPorId('i1'), inquilino);
      expect(await repo.listar(), [inquilino]);
    });

    test('eliminar quita al inquilino', () async {
      final repo = RepositorioDeInquilinosEnMemoria([
        Inquilino(id: 'i1', nombre: 'Juan Pérez'),
        Inquilino(id: 'i2', nombre: 'Ana Torres'),
      ]);

      await repo.eliminar('i1');

      expect(await repo.obtenerPorId('i1'), isNull);
      expect((await repo.listar()).map((i) => i.id), ['i2']);
    });

    test('eliminar un id inexistente no falla y es idempotente', () async {
      final repo = RepositorioDeInquilinosEnMemoria([
        Inquilino(id: 'i1', nombre: 'Juan Pérez'),
      ]);

      await repo.eliminar('no-existe');
      await repo.eliminar('i1');
      await repo.eliminar('i1');

      expect(await repo.listar(), isEmpty);
    });
  });
}
