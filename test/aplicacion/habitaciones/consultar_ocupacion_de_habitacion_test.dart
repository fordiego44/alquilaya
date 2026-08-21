import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/consultar_ocupacion_de_habitacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/estado_de_ocupacion.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/contratos_activos_falsos.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('ConsultarOcupacionDeHabitacion', () {
    final consultar = ConsultarOcupacionDeHabitacion(
      RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
        Habitacion(id: 'h2', nombre: 'Habitación 2'),
      ]),
      ContratosActivosFalsos({'h1'}),
    );

    test('está ocupada si tiene un contrato activo', () async {
      expect(await consultar.ejecutar('h1'), EstadoDeOcupacion.ocupada);
    });

    test('está disponible si no lo tiene', () async {
      expect(await consultar.ejecutar('h2'), EstadoDeOcupacion.disponible);
    });

    test('una habitación inexistente es un error, no "disponible"', () {
      expect(
        () => consultar.ejecutar('desconocida'),
        throwsA(isA<HabitacionNoEncontrada>()),
      );
    });
  });
}
