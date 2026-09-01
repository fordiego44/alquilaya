import '../../dominio/entidades/cuota.dart';
import '../../dominio/valores/dinero.dart';
import '../../dominio/valores/periodo.dart';
import '../cuotas/listar_cuotas_para_cobro.dart';
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

  /// Lo que ya se debería haber cobrado y no se cobró: la suma de los montos
  /// pendientes de las cuotas **vencidas**.
  ///
  /// No incluye lo que aún no toca cobrar. Una cuota cuya fecha de cobro es hoy
  /// o posterior sigue pendiente y aparece en [proximosCobros], no aquí:
  /// mezclarlas haría parecer moroso a un inquilino que está al día.
  final Dinero deudaVencida;

  /// Cuotas cuya fecha de cobro no ha pasado todavía, ordenadas por esa fecha y
  /// sin ventana temporal ni tope: quien las muestra decide cuántas caben en
  /// pantalla.
  ///
  /// Traen a quién y dónde cobrar, para que el panel sirva sin abrir nada más.
  final List<CuotaParaCobro> proximosCobros;

  const ResumenDelDashboard({
    required this.periodo,
    required this.habitacionesOcupadas,
    required this.habitacionesDisponibles,
    required this.cobrosDelPeriodo,
    required this.deudaVencida,
    required this.proximosCobros,
  });

  @override
  String toString() =>
      'ResumenDelDashboard($periodo, $habitacionesOcupadas ocupadas, '
      'cobrado $cobrosDelPeriodo, vencido $deudaVencida)';
}

/// Arma el resumen del estado de la vivienda.
///
/// **Agrega, no calcula**: cada cifra la produce ya alguien —`ListarHabitaciones`
/// sabe qué habitación está ocupada, `ListarCuotasParaCobro` sabe derivar,
/// ordenar y decir a quién se cobra—, así que aquí solo se componen. Ninguna
/// regla de negocio se reescribe.
///
/// Es de **solo lectura**. En particular no pone al día las cuotas: si nadie ha
/// ejecutado `ActualizarCuotasDeTodosLosContratos`, el resumen mostrará menos
/// deuda de la real. Es deliberado — consultar no escribe—, y es el consumidor
/// quien decide cuándo pedir la puesta al día.
class ConsultarDashboard {
  final ListarHabitaciones _listarHabitaciones;
  final ListarCuotasParaCobro _listarCuotasParaCobro;
  final RepositorioDePagos _pagos;

  ConsultarDashboard(
    this._listarHabitaciones,
    this._listarCuotasParaCobro,
    this._pagos,
  );

  /// [periodo] nulo consulta el mes de [hoy]. El resto de cifras —deuda vencida
  /// y próximos cobros— se derivan siempre de [hoy], no del período: mirar los
  /// cobros de un mes pasado no cambia cuánto se debe hoy.
  Future<ResumenDelDashboard> ejecutar({
    required DateTime hoy,
    Periodo? periodo,
  }) async {
    final mes = periodo ?? Periodo.deFecha(hoy);

    final habitaciones = await _listarHabitaciones.ejecutar();
    final ocupadas = habitaciones
        .where((h) => h.estado == EstadoDeOcupacion.ocupada)
        .length;

    // Una sola consulta sin filtro: ya viene derivada y ordenada por fecha de
    // cobro, y de ella salen tanto la deuda como los cobros por venir.
    final cuotas = await _listarCuotasParaCobro.ejecutar(hoy: hoy);

    var deudaVencida = Dinero.cero;
    final proximosCobros = <CuotaParaCobro>[];
    for (final paraCobro in cuotas) {
      // Cada cuota cae en un único sitio: o ya se debía cobrar y no se cobró, o
      // está por cobrarse, o está saldada. Contarla en dos la duplicaría en
      // pantalla.
      switch (paraCobro.cuota.estado) {
        case EstadoCuota.pagada:
          break;
        case EstadoCuota.vencida:
          deudaVencida += paraCobro.cuota.montoPendiente;
        case EstadoCuota.pendiente:
          proximosCobros.add(paraCobro);
      }
    }

    // Todo pago pertenece a una cuota y la regla 12 nunca elimina una cuota con
    // pagos, así que preguntar por todas las cuotas alcanza todos los pagos.
    // Evita añadir al puerto una lectura global que nadie más necesita.
    final pagos = await _pagos.deCuotas(cuotas.map((c) => c.cuota.cuota.id));
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
      deudaVencida: deudaVencida,
      proximosCobros: proximosCobros,
    );
  }
}
