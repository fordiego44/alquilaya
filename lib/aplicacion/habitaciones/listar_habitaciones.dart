import '../../dominio/entidades/habitacion.dart';
import '../puertos/contratos_activos.dart';
import '../puertos/repositorio_de_habitaciones.dart';
import 'estado_de_ocupacion.dart';

/// Una habitación junto a su estado de ocupación derivado.
///
/// Es un dato de salida de la aplicación, no una entidad: el estado no forma
/// parte de [Habitacion] y no debe poder guardarse.
class HabitacionListada {
  final Habitacion habitacion;
  final EstadoDeOcupacion estado;

  const HabitacionListada(this.habitacion, this.estado);

  @override
  String toString() => 'HabitacionListada(${habitacion.nombre}, ${estado.name})';
}

/// Lista todas las habitaciones indicando cuáles están ocupadas.
///
/// Consulta las habitaciones ocupadas **una sola vez** y cruza en memoria, en
/// lugar de preguntar por cada habitación.
class ListarHabitaciones {
  final RepositorioDeHabitaciones _repositorio;
  final ContratosActivos _contratosActivos;

  ListarHabitaciones(this._repositorio, this._contratosActivos);

  Future<List<HabitacionListada>> ejecutar() async {
    final habitaciones = await _repositorio.listar();
    final ocupadas = await _contratosActivos.habitacionesOcupadas();
    return [
      for (final habitacion in habitaciones)
        HabitacionListada(
          habitacion,
          ocupadas.contains(habitacion.id)
              ? EstadoDeOcupacion.ocupada
              : EstadoDeOcupacion.disponible,
        ),
    ];
  }
}
