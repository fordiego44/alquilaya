import '../excepciones.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_habitaciones.dart';

/// Borra físicamente una habitación que nunca se usó.
///
/// Solo se elimina lo que no deja huella: basta **un** contrato, activo o
/// finalizado, para que la habitación pertenezca al historial y el borrado deje
/// de ser una opción. Para ese caso está `ArchivarHabitacion`.
///
/// La comprobación se hace aquí, no en la base: la clave foránea también lo
/// impediría, pero es la última barrera y solo sabe decir "constraint failed".
/// La regla, y el error que se puede enseñar a alguien, viven en este caso de
/// uso.
class EliminarHabitacion {
  final RepositorioDeHabitaciones _habitaciones;
  final RepositorioDeContratos _contratos;

  EliminarHabitacion(this._habitaciones, this._contratos);

  Future<void> ejecutar(String habitacionId) async {
    if (await _habitaciones.obtenerPorId(habitacionId) == null) {
      throw HabitacionNoEncontrada(habitacionId);
    }

    // Una vivienda tiene decenas de contratos, no millones: traerlos y filtrar
    // en memoria evita comprometer al puerto con una consulta que solo usaría
    // este caso de uso.
    final contratos = await _contratos.listar();
    if (contratos.any((c) => c.habitacionId == habitacionId)) {
      throw HabitacionConContratos(habitacionId);
    }

    await _habitaciones.eliminar(habitacionId);
  }
}
