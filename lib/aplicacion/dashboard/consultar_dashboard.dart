import '../../dominio/entidades/cuota.dart';
import '../../dominio/valores/dinero.dart';
import '../../dominio/valores/periodo.dart';
import '../cuotas/cuota_con_estado.dart';
import '../cuotas/listar_cuotas.dart';
import '../habitaciones/estado_de_ocupacion.dart';
import '../habitaciones/listar_habitaciones.dart';
import '../puertos/repositorio_de_pagos.dart';

/// Estado consolidado de la vivienda en un instante.
///
/// Es un modelo de salida de la aplicación, no una entidad: todas sus cifras
/// son derivadas y ninguna se guarda.
class ResumenDelDashboard {
  /// Mes al que corresponde [cobrosDelPeriodo]. Viaja en el resumen para que
  /// el consumidor sepa qué mes está mirando sin recalcular el valor por
  /// defecto.
  final Periodo periodo;

  final int habitacionesOcupadas;
  final int habitacionesDisponibles;

  /// Dinero **recibido** durante [periodo], por fecha de pago. Un pago tardío
  /// cuenta en el mes en que entró, no en el de la cuota que salda: es caja,
  /// no devengo.
  final Dinero cobrosDelPeriodo;

  /// Lo que falta por cobrar de toda la cartera a fecha de hoy: la suma de los
  /// montos pendientes de las cuotas pendientes y vencidas.
  final Dinero deudaAcumulada;

  /// Cuotas pendientes ordenadas por vencimiento, sin ventana temporal ni
  /// tope: quien las muestra decide cuántas caben en pantalla.
  final List<CuotaConEstado> proximosVencimientos;

  const ResumenDelDashboard({
    required this.periodo,
    required this.habitacionesOcupadas,
    required this.habitacionesDisponibles,
    required this.cobrosDelPeriodo,
    required this.deudaAcumulada,
    required this.proximosVencimientos,
  });

  @override
  String toString() =>
      'ResumenDelDashboard($periodo, $habitacionesOcupadas ocupadas, '
      'cobrado $cobrosDelPeriodo, debe $deudaAcumulada)';
}

/// Arma el resumen del estado de la vivienda.
///
/// **Agrega, no calcula**: cada cifra la produce ya alguien —`ListarHabitaciones`
/// sabe qué habitación está ocupada, `ListarCuotas` sabe derivar y ordenar—, así
/// que aquí solo se componen. Ninguna regla de negocio se reescribe.
///
/// Es de **solo lectura**. En particular no pone al día las cuotas: si nadie ha
/// ejecutado `ActualizarCuotasDeTodosLosContratos`, el resumen mostrará menos
/// deuda de la real. Es deliberado — consultar no escribe—, y es el consumidor
/// quien decide cuándo pedir la puesta al día.
class ConsultarDashboard {
  final ListarHabitaciones _listarHabitaciones;
  final ListarCuotas _listarCuotas;
  final RepositorioDePagos _pagos;

  ConsultarDashboard(this._listarHabitaciones, this._listarCuotas, this._pagos);

  /// [periodo] nulo consulta el mes de [hoy]. El resto de cifras —deuda y
  /// próximos vencimientos— se derivan siempre de [hoy], no del período: mirar
  /// los cobros de un mes pasado no cambia cuánto se debe hoy.
  Future<ResumenDelDashboard> ejecutar({
    required DateTime hoy,
    Periodo? periodo,
  }) async {
    final mes = periodo ?? Periodo.deFecha(hoy);

    final habitaciones = await _listarHabitaciones.ejecutar();
    final ocupadas = habitaciones
        .where((h) => h.estado == EstadoDeOcupacion.ocupada)
        .length;

    // Una sola consulta sin filtro: ya viene derivada y ordenada por
    // vencimiento, y de ella salen tanto la deuda como los vencimientos.
    final cuotas = await _listarCuotas.ejecutar(hoy: hoy);

    var deuda = Dinero.cero;
    final proximosVencimientos = <CuotaConEstado>[];
    for (final cuota in cuotas) {
      if (cuota.estado == EstadoCuota.pagada) continue;
      deuda += cuota.montoPendiente;
      if (cuota.estado == EstadoCuota.pendiente) {
        proximosVencimientos.add(cuota);
      }
    }

    // Todo pago pertenece a una cuota y la regla 12 nunca elimina una cuota con
    // pagos, así que preguntar por todas las cuotas alcanza todos los pagos.
    // Evita añadir al puerto una lectura global que nadie más necesita.
    final pagos = await _pagos.deCuotas(cuotas.map((c) => c.cuota.id));
    var cobros = Dinero.cero;
    for (final pago in pagos) {
      if (Periodo.deFecha(pago.fechaPago) == mes) {
        cobros += pago.monto;
      }
    }

    return ResumenDelDashboard(
      periodo: mes,
      habitacionesOcupadas: ocupadas,
      habitacionesDisponibles: habitaciones.length - ocupadas,
      cobrosDelPeriodo: cobros,
      deudaAcumulada: deuda,
      proximosVencimientos: proximosVencimientos,
    );
  }
}
