import '../../dominio/entidades/cuota.dart';

/// Almacén de cuotas.
///
/// Las cuotas solo se consultan y se guardan **por contrato**: no existe un
/// `obtenerPorId` porque nadie lo necesita todavía.
abstract interface class RepositorioDeCuotas {
  /// Inserta o reemplaza en lote. Es la única forma de guardar: quien crea una
  /// sola cuota pasa una lista de un elemento.
  Future<void> guardarTodas(List<Cuota> cuotas);

  Future<List<Cuota>> deContrato(String contratoId);

  /// Elimina las cuotas indicadas. Solo lo usa la finalización de un contrato,
  /// y únicamente sobre cuotas que la regla 12 manda no conservar.
  Future<void> eliminar(Iterable<String> cuotaIds);
}
