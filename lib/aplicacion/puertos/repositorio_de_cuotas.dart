import '../../dominio/entidades/cuota.dart';

/// Almacén de cuotas.
abstract interface class RepositorioDeCuotas {
  /// Inserta o reemplaza en lote. Es la única forma de guardar: quien crea una
  /// sola cuota pasa una lista de un elemento.
  Future<void> guardarTodas(List<Cuota> cuotas);

  /// Devuelve `null` si no existe. Lo necesita el registro de un pago, que
  /// parte de la cuota que el usuario eligió y no de su contrato.
  Future<Cuota?> obtenerPorId(String id);

  Future<List<Cuota>> deContrato(String contratoId);

  /// Todas las cuotas, de cualquier contrato. Las consultas de deuda cruzan la
  /// cartera entera —incluidos los contratos finalizados, cuya deuda vencida
  /// se conserva (regla 12)—, así que filtrar por contrato no les sirve.
  Future<List<Cuota>> todas();

  /// Elimina las cuotas indicadas. Solo lo usa la finalización de un contrato,
  /// y únicamente sobre cuotas que la regla 12 manda no conservar.
  Future<void> eliminar(Iterable<String> cuotaIds);
}
