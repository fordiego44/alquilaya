import '../../dominio/entidades/habitacion.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_habitaciones.dart';

/// Devuelve una habitación archivada a las opciones disponibles.
///
/// No consulta los contratos: reactivar no tiene condiciones. Una habitación
/// archivada no puede tener un contrato activo —archivarla lo impedía—, así que
/// no hay nada que comprobar. Es idempotente.
class ReactivarHabitacion {
  final RepositorioDeHabitaciones _habitaciones;

  ReactivarHabitacion(this._habitaciones);

  Future<Habitacion> ejecutar(String habitacionId) async {
    final habitacion = await _habitaciones.obtenerPorId(habitacionId);
    if (habitacion == null) {
      throw HabitacionNoEncontrada(habitacionId);
    }

    final reactivada = habitacion.reactivar();
    await _habitaciones.guardar(reactivada);
    return reactivada;
  }
}
