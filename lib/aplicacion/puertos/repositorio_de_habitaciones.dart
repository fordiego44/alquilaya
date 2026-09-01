import '../../dominio/entidades/habitacion.dart';

/// Almacén de habitaciones. La infraestructura lo implementa cuando exista una
/// decisión de persistencia; los casos de uso solo conocen este contrato.
///
/// Es asíncrono porque un adaptador real hablará con disco o red.
abstract interface class RepositorioDeHabitaciones {
  /// Inserta o reemplaza por id.
  Future<void> guardar(Habitacion habitacion);

  /// Devuelve `null` si no existe. Informar de la ausencia es cosa del puerto;
  /// decidir qué hacer con ella es del caso de uso.
  Future<Habitacion?> obtenerPorId(String id);

  Future<List<Habitacion>> listar();

  /// Borra la habitación con [id]. Si no existe, no hace nada: repetir la
  /// llamada no es un error.
  ///
  /// El puerto **no comprueba si algo la referencia**: "no se puede borrar una
  /// habitación con contratos" es una regla de negocio y vive en el caso de
  /// uso, que es quien ve los contratos. Un adaptador con integridad
  /// referencial puede además rechazar el borrado por su cuenta, y esa segunda
  /// barrera es deliberada: la regla no depende de que alguien la recuerde.
  Future<void> eliminar(String id);
}
