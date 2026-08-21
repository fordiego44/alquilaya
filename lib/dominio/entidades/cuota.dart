import '../valores/dinero.dart';
import '../valores/periodo.dart';
import 'pago.dart';

/// Situación de una cuota. Se deriva siempre de sus pagos y de la fecha
/// actual; nunca se almacena ni se marca a mano.
enum EstadoCuota { pendiente, pagada, vencida }

/// Obligación mensual de pago generada por un contrato para un período.
///
/// No guarda sus pagos: los recibe como argumento y se queda solo con los
/// suyos, de modo que una colección que arrastre pagos de otras cuotas no
/// pueda darla por saldada.
class Cuota {
  final String id;
  final String contratoId;
  final Periodo periodo;
  final Dinero monto;
  final DateTime fechaVencimiento;

  Cuota({
    required this.id,
    required this.contratoId,
    required this.periodo,
    required this.monto,
    required this.fechaVencimiento,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'No puede estar vacío');
    }
    if (contratoId.isEmpty) {
      throw ArgumentError.value(
        contratoId,
        'contratoId',
        'No puede estar vacío',
      );
    }
    if (!monto.esPositivo) {
      throw ArgumentError.value(monto, 'monto', 'Debe ser positivo');
    }
  }

  /// Importe que falta para saldar la cuota.
  Dinero montoPendiente(Iterable<Pago> pagos) {
    final pagado = _totalPagado(pagos);
    return pagado >= monto ? Dinero.cero : monto - pagado;
  }

  bool estaPagada(Iterable<Pago> pagos) => _totalPagado(pagos) >= monto;

  /// Estado a fecha de [hoy]: vencida si no está pagada y su vencimiento ya
  /// pasó. El día del vencimiento aún no cuenta como vencido.
  EstadoCuota estadoSegun(Iterable<Pago> pagos, DateTime hoy) {
    if (estaPagada(pagos)) return EstadoCuota.pagada;
    return _soloDia(fechaVencimiento).isBefore(_soloDia(hoy))
        ? EstadoCuota.vencida
        : EstadoCuota.pendiente;
  }

  /// Comprueba que [pago] puede aplicarse a esta cuota. Un pago salda la cuota
  /// entera: no se admiten pagos parciales, sobrepagos ni un segundo pago.
  ///
  /// A diferencia del resto de métodos, un pago ajeno no se ignora: se rechaza.
  void validarPago(Pago pago, Iterable<Pago> pagosPrevios) {
    if (pago.cuotaId != id) {
      throw ArgumentError.value(
        pago.cuotaId,
        'pago.cuotaId',
        'El pago no corresponde a la cuota $id',
      );
    }
    if (estaPagada(pagosPrevios)) {
      throw StateError('La cuota $id ya está pagada');
    }
    final pendiente = montoPendiente(pagosPrevios);
    if (pago.monto != pendiente) {
      throw ArgumentError.value(
        pago.monto,
        'pago.monto',
        'Debe ser exactamente el monto pendiente ($pendiente)',
      );
    }
  }

  /// Regla de conservación al finalizar un contrato: se conserva si ya había
  /// vencido a la fecha de fin o si tiene algún pago. La decisión se toma por
  /// fecha de vencimiento, no por período.
  bool debeConservarseAlFinalizar(DateTime fechaFin, Iterable<Pago> pagos) =>
      !_soloDia(fechaVencimiento).isAfter(_soloDia(fechaFin)) ||
      _pagosPropios(pagos).isNotEmpty;

  /// Solo los pagos de esta cuota; los demás no le incumben.
  Iterable<Pago> _pagosPropios(Iterable<Pago> pagos) =>
      pagos.where((pago) => pago.cuotaId == id);

  Dinero _totalPagado(Iterable<Pago> pagos) => _pagosPropios(
    pagos,
  ).fold(Dinero.cero, (total, pago) => total + pago.monto);

  static DateTime _soloDia(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  @override
  bool operator ==(Object other) => other is Cuota && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Cuota($id, $periodo, $monto, vence $fechaVencimiento)';
}
