import '../excepciones.dart';
import '../puertos/contratos_activos.dart';
import '../puertos/repositorio_de_habitaciones.dart';
import 'estado_de_ocupacion.dart';

/// Responde si una habitación concreta está ocupada o disponible.
///
/// Comprueba primero que la habitación existe: una habitación inexistente no
/// es "disponible", es un error de quien pregunta.
class ConsultarOcupacionDeHabitacion {
  final RepositorioDeHabitaciones _repositorio;
  final ContratosActivos _contratosActivos;

  ConsultarOcupacionDeHabitacion(this._repositorio, this._contratosActivos);

  Future<EstadoDeOcupacion> ejecutar(String id) async {
    if (await _repositorio.obtenerPorId(id) == null) {
      throw HabitacionNoEncontrada(id);
    }
    return await _contratosActivos.tieneContratoActivo(id)
        ? EstadoDeOcupacion.ocupada
        : EstadoDeOcupacion.disponible;
  }
}
