import '../valores/dinero.dart';

/// Relación entre una habitación y un inquilino en el tiempo.
///
/// La fecha de inicio fija además el día base de cobro de todas sus cuotas: no
/// existe un día de cobro configurable aparte.
class Contrato {
  final String id;
  final String habitacionId;
  final String inquilinoId;
  final DateTime fechaInicio;
  final Dinero montoMensual;
  final DateTime? fechaFin;

  Contrato({
    required this.id,
    required this.habitacionId,
    required this.inquilinoId,
    required this.fechaInicio,
    required this.montoMensual,
    this.fechaFin,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'No puede estar vacío');
    }
    if (habitacionId.isEmpty) {
      throw ArgumentError.value(
        habitacionId,
        'habitacionId',
        'No puede estar vacío',
      );
    }
    if (inquilinoId.isEmpty) {
      throw ArgumentError.value(
        inquilinoId,
        'inquilinoId',
        'No puede estar vacío',
      );
    }
    if (!montoMensual.esPositivo) {
      throw ArgumentError.value(
        montoMensual,
        'montoMensual',
        'Debe ser positivo',
      );
    }
    final fin = fechaFin;
    if (fin != null && fin.isBefore(fechaInicio)) {
      throw ArgumentError.value(
        fin,
        'fechaFin',
        'No puede ser anterior a la fecha de inicio',
      );
    }
  }

  /// Estado derivado: un contrato está activo mientras no tenga fecha de fin.
  bool get estaActivo => fechaFin == null;

  /// Día del mes en que vencen sus cuotas. Se deriva de la fecha de inicio;
  /// `CalendarioDePagos` es quien lo usa para calcular los vencimientos.
  int get diaBaseDeCobro => fechaInicio.day;

  /// Finaliza el contrato devolviendo una copia nueva. No borra el original ni
  /// su historial: las cuotas y los pagos siguen siendo consultables.
  Contrato finalizar(DateTime fecha) {
    if (!estaActivo) {
      throw StateError('El contrato $id ya está finalizado');
    }
    return Contrato(
      id: id,
      habitacionId: habitacionId,
      inquilinoId: inquilinoId,
      fechaInicio: fechaInicio,
      montoMensual: montoMensual,
      fechaFin: fecha,
    );
  }

  @override
  bool operator ==(Object other) => other is Contrato && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Contrato($id, habitacion $habitacionId, inquilino $inquilinoId, '
      '$montoMensual, activo: $estaActivo)';
}
