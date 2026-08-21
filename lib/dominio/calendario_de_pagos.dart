import 'valores/periodo.dart';

/// Único punto del dominio donde viven las reglas de fechas de cobro.
///
/// El alquiler se cobra **por adelantado**: la cuota de índice 0 vence el mismo
/// día de inicio del contrato y se paga al ingresar. Las siguientes vencen
/// mensualmente el *día base*, que es el día de la fecha de inicio.
///
/// Si el día base no existe en un mes, el vencimiento se ajusta al último día
/// de ese mes **sin arrastrar el ajuste**: el día base original se conserva
/// para los meses siguientes (31/01 → 28/02 → 31/03 → 30/04).
class CalendarioDePagos {
  const CalendarioDePagos._();

  /// Vencimiento de la cuota número [indice] (0 = primera cuota).
  ///
  /// El día base de cobro es `fechaInicio.day`, el mismo que publica
  /// `Contrato.diaBaseDeCobro`.
  static DateTime vencimientoDeCuota(DateTime fechaInicio, int indice) {
    if (indice < 0) {
      throw ArgumentError.value(indice, 'indice', 'No puede ser negativo');
    }
    final periodo = periodoDeCuota(fechaInicio, indice);
    final dia = _menor(
      fechaInicio.day,
      ultimoDiaDelMes(periodo.anio, periodo.mes),
    );
    return DateTime(periodo.anio, periodo.mes, dia);
  }

  /// Período (mes/año) al que corresponde la cuota número [indice].
  static Periodo periodoDeCuota(DateTime fechaInicio, int indice) {
    final mesesTotales = fechaInicio.month - 1 + indice;
    return Periodo(fechaInicio.year + mesesTotales ~/ 12, mesesTotales % 12 + 1);
  }

  static int ultimoDiaDelMes(int anio, int mes) => DateTime(anio, mes + 1, 0).day;

  /// Cuántas cuotas corresponde que existan a fecha de [hoy]: desde el mes de
  /// inicio hasta el mes actual, más un mes por delante para que "próximos
  /// vencimientos" tenga algo que mostrar.
  ///
  /// Un contrato finalizado no genera cuotas con vencimiento posterior a
  /// [fechaFin]. La primera cuota siempre cuenta: se paga al crear el contrato.
  static int cuotasHasta({
    required DateTime fechaInicio,
    required DateTime hoy,
    DateTime? fechaFin,
  }) {
    final limite = Periodo.deFecha(hoy).siguiente();
    var cantidad = 1;
    while (periodoDeCuota(fechaInicio, cantidad).compareTo(limite) <= 0) {
      if (fechaFin != null &&
          vencimientoDeCuota(fechaInicio, cantidad).isAfter(fechaFin)) {
        break;
      }
      cantidad++;
    }
    return cantidad;
  }

  static int _menor(int a, int b) => a < b ? a : b;
}
