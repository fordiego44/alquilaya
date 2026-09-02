import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/editar_habitacion.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('EditarHabitacion', () {
    late RepositorioDeHabitacionesEnMemoria repositorio;
    late EditarHabitacion editar;

    setUp(() {
      repositorio = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
      ]);
      editar = EditarHabitacion(repositorio);
    });

    test('cambia el nombre conservando el id', () async {
      final editada = await editar.ejecutar(id: 'h1', nombre: 'Habitación A');

      expect(editada.id, 'h1');
      expect((await repositorio.obtenerPorId('h1'))!.nombre, 'Habitación A');
      expect(await repositorio.listar(), hasLength(1));
    });

    test('una habitación inexistente no se da de alta por la puerta de atrás',
        () async {
      expect(
        () => editar.ejecutar(id: 'desconocida', nombre: 'Habitación X'),
        throwsA(isA<HabitacionNoEncontrada>()),
      );
      expect(await repositorio.listar(), hasLength(1));
    });

    test('un nombre inválido deja intacto el valor anterior', () async {
      expect(
        () => editar.ejecutar(id: 'h1', nombre: ''),
        throwsArgumentError,
      );
      expect((await repositorio.obtenerPorId('h1'))!.nombre, 'Habitación 1');
    });

    test('editar una habitación archivada no la reactiva', () async {
      await repositorio.guardar(
        Habitacion(id: 'h1', nombre: 'Habitación 1').archivar(),
      );

      final editada = await editar.ejecutar(id: 'h1', nombre: 'Suite');

      expect(editada.archivada, isTrue);
      expect((await repositorio.obtenerPorId('h1'))!.archivada, isTrue);
      expect((await repositorio.obtenerPorId('h1'))!.nombre, 'Suite');
    });
  });
}
