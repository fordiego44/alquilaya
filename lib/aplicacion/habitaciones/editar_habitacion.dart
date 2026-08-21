import '../../dominio/entidades/habitacion.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_habitaciones.dart';

/// Cambia los datos de una habitación existente.
///
/// [Habitacion] es inmutable: se construye una copia nueva con el mismo id en
/// lugar de mutar la original, lo que reutiliza su validación tal cual.
class EditarHabitacion {
  final RepositorioDeHabitaciones _repositorio;

  EditarHabitacion(this._repositorio);

  Future<Habitacion> ejecutar({
    required String id,
    required String nombre,
  }) async {
    if (await _repositorio.obtenerPorId(id) == null) {
      throw HabitacionNoEncontrada(id);
    }
    final editada = Habitacion(id: id, nombre: nombre);
    await _repositorio.guardar(editada);
    return editada;
  }
}
