import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/obtener_habitacion.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('ObtenerHabitacion', () {
    final habitacion = Habitacion(id: 'h1', nombre: 'Habitación 1');
    final obtener = ObtenerHabitacion(
      RepositorioDeHabitacionesEnMemoria([habitacion]),
    );

    test('devuelve la habitación existente', () async {
      expect(await obtener.ejecutar('h1'), habitacion);
    });

    test('un id desconocido lanza HabitacionNoEncontrada', () {
      expect(
        () => obtener.ejecutar('desconocida'),
        throwsA(isA<HabitacionNoEncontrada>()),
      );
    });
  });
}
