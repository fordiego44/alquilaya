import '../../dominio/entidades/inquilino.dart';

/// Almacén de inquilinos. Mismo contrato mínimo que el de habitaciones: solo
/// los métodos con un consumidor real en esta fase.
abstract interface class RepositorioDeInquilinos {
  /// Inserta o reemplaza por id.
  Future<void> guardar(Inquilino inquilino);

  /// Devuelve `null` si no existe.
  Future<Inquilino?> obtenerPorId(String id);

  Future<List<Inquilino>> listar();
}
