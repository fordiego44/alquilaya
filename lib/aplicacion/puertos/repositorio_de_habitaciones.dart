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
}
