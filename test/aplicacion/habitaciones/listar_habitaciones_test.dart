import 'package:alquilaya/aplicacion/habitaciones/estado_de_ocupacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/listar_habitaciones.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/contratos_activos_falsos.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('ListarHabitaciones', () {
    final habitaciones = [
      Habitacion(id: 'h1', nombre: 'Habitación 1'),
      Habitacion(id: 'h2', nombre: 'Habitación 2'),
    ];

    ListarHabitaciones listarCon(Set<String> ocupadas) => ListarHabitaciones(
      RepositorioDeHabitacionesEnMemoria(habitaciones),
      ContratosActivosFalsos(ocupadas),
    );

    /// El puerto no promete ningún orden; las comprobaciones buscan por id.
    EstadoDeOcupacion estadoDe(List<HabitacionListada> listado, String id) =>
        listado.singleWhere((h) => h.habitacion.id == id).estado;

    test('marca ocupada la que tiene contrato activo', () async {
      final listado = await listarCon({'h1'}).ejecutar();

      expect(listado, hasLength(2));
      expect(estadoDe(listado, 'h1'), EstadoDeOcupacion.ocupada);
      expect(estadoDe(listado, 'h2'), EstadoDeOcupacion.disponible);
    });

    test('sin contratos activos, todas están disponibles', () async {
      final listado = await listarCon({}).ejecutar();

      expect(listado, hasLength(2));
      expect(
        listado.map((h) => h.estado),
        everyElement(EstadoDeOcupacion.disponible),
      );
    });

    test('sin habitaciones devuelve una lista vacía', () async {
      final listar = ListarHabitaciones(
        RepositorioDeHabitacionesEnMemoria(),
        ContratosActivosFalsos(),
      );

      expect(await listar.ejecutar(), isEmpty);
    });
  });
}
