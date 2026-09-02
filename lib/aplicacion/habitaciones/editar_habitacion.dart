import '../../dominio/entidades/habitacion.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_habitaciones.dart';

/// Cambia los datos de una habitación existente.
///
/// [Habitacion] es inmutable: se construye una copia nueva con el mismo id en
/// lugar de mutar la original, lo que reutiliza su validación tal cual.
///
/// Editar **no cambia el archivado**: quien renombra una habitación archivada
/// no está reactivándola. Por eso se parte de la habitación guardada y solo se
/// reemplaza lo que la edición toca.
class EditarHabitacion {
  final RepositorioDeHabitaciones _repositorio;

  EditarHabitacion(this._repositorio);

  Future<Habitacion> ejecutar({
    required String id,
    required String nombre,
  }) async {
    final actual = await _repositorio.obtenerPorId(id);
    if (actual == null) {
      throw HabitacionNoEncontrada(id);
    }
    final editada = Habitacion(
      id: id,
      nombre: nombre,
      archivada: actual.archivada,
    );
    await _repositorio.guardar(editada);
    return editada;
  }
}
