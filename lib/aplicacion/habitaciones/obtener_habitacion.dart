import '../../dominio/entidades/habitacion.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_habitaciones.dart';

/// Recupera una habitación por su id.
class ObtenerHabitacion {
  final RepositorioDeHabitaciones _repositorio;

  ObtenerHabitacion(this._repositorio);

  Future<Habitacion> ejecutar(String id) async {
    final habitacion = await _repositorio.obtenerPorId(id);
    if (habitacion == null) {
      throw HabitacionNoEncontrada(id);
    }
    return habitacion;
  }
}
