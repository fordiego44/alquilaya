import '../../dominio/entidades/inquilino.dart';

/// Almacén de inquilinos. Mismo contrato mínimo que el de habitaciones: solo
/// los métodos con un consumidor real en esta fase.
abstract interface class RepositorioDeInquilinos {
  /// Inserta o reemplaza por id.
  Future<void> guardar(Inquilino inquilino);

  /// Devuelve `null` si no existe.
  Future<Inquilino?> obtenerPorId(String id);

  Future<List<Inquilino>> listar();

  /// Borra el inquilino con [id]. Si no existe, no hace nada.
  ///
  /// Igual que en habitaciones, el puerto no sabe nada de contratos: quién
  /// puede borrarse lo decide el caso de uso, y un adaptador con claves
  /// foráneas lo respalda rechazando el borrado de un inquilino referenciado.
  Future<void> eliminar(String id);
}
