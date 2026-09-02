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
///
/// Las **archivadas se excluyen por defecto**: lo seguro es lo que ocurre si
/// nadie hace nada, de modo que ninguna pantalla las ofrezca por olvidar un
/// filtro. Quien necesite verlas —una vista de archivadas, o resolver el nombre
/// de una habitación de un contrato antiguo— las pide explícitamente.
class ListarHabitaciones {
  final RepositorioDeHabitaciones _repositorio;
  final ContratosActivos _contratosActivos;

  ListarHabitaciones(this._repositorio, this._contratosActivos);

  /// Con [incluirArchivadas] en `true` devuelve activas **y** archivadas, sin
  /// distinguirlas: el estado va en cada `Habitacion` y lo interpreta quien las
  /// muestra.
  ///
  /// El filtro se aplica aquí y no en el repositorio: el puerto sigue
  /// devolviendo todo, y qué se oculta es una decisión de la aplicación.
  Future<List<HabitacionListada>> ejecutar({
    bool incluirArchivadas = false,
  }) async {
    final habitaciones = await _repositorio.listar();
    final ocupadas = await _contratosActivos.habitacionesOcupadas();
    return [
      for (final habitacion in habitaciones)
        if (incluirArchivadas || !habitacion.archivada)
          HabitacionListada(
            habitacion,
            ocupadas.contains(habitacion.id)
                ? EstadoDeOcupacion.ocupada
                : EstadoDeOcupacion.disponible,
          ),
    ];
  }
}
