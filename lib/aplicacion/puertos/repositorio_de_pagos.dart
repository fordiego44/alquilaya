import '../../dominio/entidades/pago.dart';

/// Almacén de pagos.
///
/// La consulta es por cuotas y no por contrato porque [Pago] solo conoce su
/// `cuotaId`: quien pregunta ya tiene las cuotas en la mano.
abstract interface class RepositorioDePagos {
  Future<void> guardar(Pago pago);

  Future<List<Pago>> deCuotas(Iterable<String> cuotaIds);
}
