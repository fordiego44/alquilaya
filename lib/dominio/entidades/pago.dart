import '../valores/dinero.dart';

/// Dinero efectivamente recibido para saldar una cuota.
///
/// Es una entidad propia y no un campo de `Cuota`: así admitir pagos parciales
/// en el futuro no obliga a rehacer el modelo.
class Pago {
  final String id;
  final String cuotaId;
  final Dinero monto;
  final DateTime fechaPago;

  Pago({
    required this.id,
    required this.cuotaId,
    required this.monto,
    required this.fechaPago,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'No puede estar vacío');
    }
    if (cuotaId.isEmpty) {
      throw ArgumentError.value(cuotaId, 'cuotaId', 'No puede estar vacío');
    }
    if (!monto.esPositivo) {
      throw ArgumentError.value(monto, 'monto', 'Debe ser positivo');
    }
  }

  @override
  bool operator ==(Object other) => other is Pago && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Pago($id, cuota $cuotaId, $monto)';
}
