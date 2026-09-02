import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/reactivar_habitacion.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('ReactivarHabitacion', () {
    late RepositorioDeHabitacionesEnMemoria habitaciones;
    late ReactivarHabitacion reactivar;

    setUp(() {
      habitaciones = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1').archivar(),
      ]);
      // Sin repositorio de contratos: reactivar no los consulta.
      reactivar = ReactivarHabitacion(habitaciones);
    });

    test('reactiva una habitación archivada', () async {
      final reactivada = await reactivar.ejecutar('h1');

      expect(reactivada.archivada, isFalse);
      expect((await habitaciones.obtenerPorId('h1'))!.archivada, isFalse);
    });

    test('reactivar una habitación que ya está activa no falla', () async {
      await habitaciones.guardar(Habitacion(id: 'h2', nombre: 'Habitación 2'));

      await reactivar.ejecutar('h2');

      expect((await habitaciones.obtenerPorId('h2'))!.archivada, isFalse);
    });

    test('reactivar dos veces es idempotente y conserva el nombre', () async {
      await reactivar.ejecutar('h1');
      await reactivar.ejecutar('h1');

      final guardada = (await habitaciones.obtenerPorId('h1'))!;
      expect(guardada.archivada, isFalse);
      expect(guardada.nombre, 'Habitación 1');
      expect(await habitaciones.listar(), hasLength(1));
    });

    test('una habitación inexistente lanza HabitacionNoEncontrada', () async {
      await expectLater(
        reactivar.ejecutar('desconocida'),
        throwsA(isA<HabitacionNoEncontrada>()),
      );
    });
  });
}
