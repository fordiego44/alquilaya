import '../../dominio/entidades/habitacion.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_habitaciones.dart';

/// Retira una habitación de las opciones para contratos nuevos, conservándola.
///
/// Se puede archivar una habitación que nunca se usó y una con contratos ya
/// cerrados. Lo único que lo impide es un **contrato activo**: archivar a un
/// inquilino que sigue viviendo allí dejaría la vivienda descrita de forma
/// falsa.
///
/// Es idempotente: archivar lo ya archivado vuelve a guardar el mismo estado.
class ArchivarHabitacion {
  final RepositorioDeHabitaciones _habitaciones;
  final RepositorioDeContratos _contratos;

  ArchivarHabitacion(this._habitaciones, this._contratos);

  Future<Habitacion> ejecutar(String habitacionId) async {
    final habitacion = await _habitaciones.obtenerPorId(habitacionId);
    if (habitacion == null) {
      throw HabitacionNoEncontrada(habitacionId);
    }

    final contratos = await _contratos.listar();
    if (contratos.any((c) => c.habitacionId == habitacionId && c.estaActivo)) {
      throw HabitacionConContratoActivo(habitacionId);
    }

    final archivada = habitacion.archivar();
    await _habitaciones.guardar(archivada);
    return archivada;
  }
}
