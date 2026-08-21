import 'package:alquilaya/aplicacion/habitaciones/registrar_habitacion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/generador_de_id_secuencial.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('RegistrarHabitacion', () {
    late RepositorioDeHabitacionesEnMemoria repositorio;
    late RegistrarHabitacion registrar;

    setUp(() {
      repositorio = RepositorioDeHabitacionesEnMemoria();
      registrar = RegistrarHabitacion(
        repositorio,
        GeneradorDeIdSecuencial('h'),
      );
    });

    test('toma el id del generador y deja la habitación recuperable', () async {
      final habitacion = await registrar.ejecutar(nombre: 'Habitación 1');

      expect(habitacion.id, 'h1');
      expect(habitacion.nombre, 'Habitación 1');
      expect(await repositorio.obtenerPorId('h1'), habitacion);
    });

    test('cada registro recibe un id distinto', () async {
      final primera = await registrar.ejecutar(nombre: 'Habitación 1');
      final segunda = await registrar.ejecutar(nombre: 'Habitación 2');

      expect(primera.id, isNot(segunda.id));
      expect(await repositorio.listar(), hasLength(2));
    });

    test('un nombre inválido propaga el error del dominio sin guardar nada',
        () async {
      expect(
        () => registrar.ejecutar(nombre: '   '),
        throwsArgumentError,
      );
      expect(await repositorio.listar(), isEmpty);
    });
  });
}
