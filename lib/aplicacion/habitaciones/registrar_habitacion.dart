import '../../dominio/entidades/habitacion.dart';
import '../puertos/generador_de_id.dart';
import '../puertos/repositorio_de_habitaciones.dart';

/// Da de alta una habitación.
///
/// La validación del nombre no se repite aquí: la hace el constructor de
/// [Habitacion]. Si falla, se propaga el `ArgumentError` y no se guarda nada.
class RegistrarHabitacion {
  final RepositorioDeHabitaciones _repositorio;
  final GeneradorDeId _generadorDeId;

  RegistrarHabitacion(this._repositorio, this._generadorDeId);

  Future<Habitacion> ejecutar({required String nombre}) async {
    final habitacion = Habitacion(
      id: await _generadorDeId.nuevoId(),
      nombre: nombre,
    );
    await _repositorio.guardar(habitacion);
    return habitacion;
  }
}
