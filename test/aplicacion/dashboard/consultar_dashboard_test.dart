import 'package:alquilaya/aplicacion/cuotas/listar_cuotas.dart';
import 'package:alquilaya/aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import 'package:alquilaya/aplicacion/dashboard/consultar_dashboard.dart';
import 'package:alquilaya/aplicacion/habitaciones/listar_habitaciones.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';
import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('ConsultarDashboard', () {
    final monto = Dinero(35000);
    final inicio = DateTime(2026, 8, 20);

    /// Vivienda de dos habitaciones. Juan Pérez sigue en la h1 con el contrato
    /// c1; Ana Torres estuvo en la h2 con el c2, ya finalizado, así que esa
    /// habitación está libre. La ocupación se deriva de los contratos reales,
    /// como en producción.
    ///
    /// Cuotas de c1: agosto pagada (tarde), septiembre vencida e impaga,
    /// octubre pagada por adelantado, noviembre y diciembre pendientes.
    /// El contrato c2 aporta una cuota de octubre pagada, para que los cobros
    /// del mes crucen más de un contrato.
    ///
    /// A 5 de octubre de 2026: deudaVencida = septiembre; proximosCobros =
    /// noviembre y diciembre.
    late RepositorioDeCuotasEnMemoria cuotas;
    late RepositorioDePagosEnMemoria pagos;
    late ConsultarDashboard consultar;

    final hoy = DateTime(2026, 10, 5);

    Cuota cuota(String id, String contratoId, int mes) => Cuota(
      id: id,
      contratoId: contratoId,
      periodo: Periodo(2026, mes),
      monto: monto,
      fechaVencimiento: DateTime(2026, mes, 20),
    );

    Pago pago(String id, String cuotaId, DateTime fechaPago) =>
        Pago(id: id, cuotaId: cuotaId, monto: monto, fechaPago: fechaPago);

    Contrato contrato(
      String id,
      String habitacionId,
      String inquilinoId, {
      DateTime? fechaFin,
    }) => Contrato(
      id: id,
      habitacionId: habitacionId,
      inquilinoId: inquilinoId,
      fechaInicio: inicio,
      montoMensual: monto,
      fechaFin: fechaFin,
    );

    ConsultarDashboard dashboardCon({
      required List<Habitacion> habitaciones,
      required List<Inquilino> inquilinos,
      required List<Contrato> contratos,
      required List<Cuota> cuotasIniciales,
      required List<Pago> pagosIniciales,
    }) {
      cuotas = RepositorioDeCuotasEnMemoria(cuotasIniciales);
      pagos = RepositorioDePagosEnMemoria(pagosIniciales);
      final repoHabitaciones = RepositorioDeHabitacionesEnMemoria(habitaciones);
      final repoInquilinos = RepositorioDeInquilinosEnMemoria(inquilinos);
      final repoContratos = RepositorioDeContratosEnMemoria(contratos);

      final listarHabitaciones = ListarHabitaciones(
        repoHabitaciones,
        repoContratos,
      );
      final listarCuotas = ListarCuotas(cuotas, pagos);
      final listarCuotasParaCobro = ListarCuotasParaCobro(
        listarCuotas,
        repoContratos,
        repoHabitaciones,
        repoInquilinos,
      );

      return ConsultarDashboard(
        listarHabitaciones,
        listarCuotasParaCobro,
        pagos,
      );
    }

    setUp(() {
      consultar = dashboardCon(
        habitaciones: [
          Habitacion(id: 'h1', nombre: 'Habitación 1'),
          Habitacion(id: 'h2', nombre: 'Habitación 2'),
        ],
        inquilinos: [
          Inquilino(id: 'i1', nombre: 'Juan Pérez', telefono: '951234567'),
          Inquilino(id: 'i2', nombre: 'Ana Torres'),
        ],
        contratos: [
          contrato('c1', 'h1', 'i1'),
          // Finalizado antes de cualquier `hoy` de estos tests, como exige la
          // aplicación: la h2 vuelve a estar disponible.
          contrato('c2', 'h2', 'i2', fechaFin: DateTime(2026, 8, 31)),
        ],
        cuotasIniciales: [
          cuota('cu1', 'c1', 8),
          cuota('cu2', 'c1', 9),
          cuota('cu3', 'c1', 10),
          cuota('cu5', 'c1', 12),
          cuota('cu4', 'c1', 11),
          cuota('cu6', 'c2', 10),
        ],
        pagosIniciales: [
          // La cuota de agosto se cobró en septiembre: pago tardío.
          pago('p1', 'cu1', DateTime(2026, 9, 5)),
          pago('p2', 'cu3', DateTime(2026, 10, 1)),
          pago('p3', 'cu6', DateTime(2026, 10, 3)),
        ],
      );
    });

    test('cuenta las habitaciones ocupadas y disponibles', () async {
      final resumen = await consultar.ejecutar(hoy: hoy);

      expect(resumen.habitacionesOcupadas, 1);
      expect(resumen.habitacionesDisponibles, 1);
    });

    test('los cobros suman los pagos recibidos en el período', () async {
      final resumen = await consultar.ejecutar(
        hoy: hoy,
        periodo: Periodo(2026, 10),
      );

      // p2 y p3, de contratos distintos; p1 entró en septiembre.
      expect(resumen.cobrosDelPeriodo, Dinero(70000));
    });

    test('un pago tardío cuenta en el mes en que se recibió', () async {
      final agosto = await consultar.ejecutar(
        hoy: hoy,
        periodo: Periodo(2026, 8),
      );
      final septiembre = await consultar.ejecutar(
        hoy: hoy,
        periodo: Periodo(2026, 9),
      );

      // La cuota es de agosto, pero el dinero entró en septiembre.
      expect(agosto.cobrosDelPeriodo, Dinero.cero);
      expect(septiembre.cobrosDelPeriodo, monto);
    });

    test('sin período explícito usa el mes de hoy', () async {
      final resumen = await consultar.ejecutar(hoy: hoy);

      expect(resumen.periodo, Periodo(2026, 10));
      expect(resumen.cobrosDelPeriodo, Dinero(70000));
    });

    test('consultar otro período no altera la deuda ni los próximos cobros',
        () async {
      final octubre = await consultar.ejecutar(hoy: hoy);
      final septiembre = await consultar.ejecutar(
        hoy: hoy,
        periodo: Periodo(2026, 9),
      );

      // Mirar los cobros de un mes pasado no cambia cuánto se debe hoy.
      expect(septiembre.periodo, Periodo(2026, 9));
      expect(septiembre.deudaVencida, octubre.deudaVencida);
      expect(
        septiembre.proximosCobros.map((c) => c.cuota.cuota.id),
        octubre.proximosCobros.map((c) => c.cuota.cuota.id),
      );
    });

    test('la deuda vencida suma solo las cuotas vencidas',
        () async {
      final resumen = await consultar.ejecutar(hoy: hoy);

      // Solo cu2 está vencida. cu4 y cu5 aún no toca cobrarlas y cu1, cu3 y
      // cu6 están pagadas: ninguna suma aquí.
      expect(resumen.deudaVencida, Dinero(35000));
    });

    test('próximos cobros: solo pendientes, por fecha de cobro', () async {
      final resumen = await consultar.ejecutar(hoy: hoy);

      // cu2 está vencida y no cuenta como próximo cobro.
      expect(resumen.proximosCobros.map((c) => c.cuota.cuota.id), [
        'cu4',
        'cu5',
      ]);
      expect(
        resumen.proximosCobros.map((c) => c.cuota.estado),
        everyElement(EstadoCuota.pendiente),
      );
    });

    test('cada cobro dice a quién cobrar y en qué habitación', () async {
      final resumen = await consultar.ejecutar(hoy: hoy);

      // cu4 y cu5 son del contrato c1: Juan Pérez, en la habitación 1.
      expect(
        resumen.proximosCobros.map((c) => c.nombreInquilino),
        everyElement('Juan Pérez'),
      );
      expect(
        resumen.proximosCobros.map((c) => c.nombreHabitacion),
        everyElement('Habitación 1'),
      );
      expect(
        resumen.proximosCobros.map((c) => c.telefono),
        everyElement('951234567'),
      );
    });

    test('un inquilino sin teléfono llega con null', () async {
      // Ana Torres no tiene teléfono; su cuota de noviembre sigue pendiente.
      final dashboard = dashboardCon(
        habitaciones: [Habitacion(id: 'h2', nombre: 'Habitación 2')],
        inquilinos: [Inquilino(id: 'i2', nombre: 'Ana Torres')],
        contratos: [contrato('c2', 'h2', 'i2')],
        cuotasIniciales: [cuota('cu7', 'c2', 11)],
        pagosIniciales: const [],
      );

      final resumen = await dashboard.ejecutar(hoy: hoy);

      final vencimiento = resumen.proximosCobros.single;
      expect(vencimiento.nombreInquilino, 'Ana Torres');
      expect(vencimiento.nombreHabitacion, 'Habitación 2');
      expect(vencimiento.telefono, isNull);
    });

    test('sin datos devuelve ceros y listas vacías', () async {
      final vacio = dashboardCon(
        habitaciones: const [],
        inquilinos: const [],
        contratos: const [],
        cuotasIniciales: const [],
        pagosIniciales: const [],
      );

      final resumen = await vacio.ejecutar(hoy: hoy);

      expect(resumen.habitacionesOcupadas, 0);
      expect(resumen.habitacionesDisponibles, 0);
      expect(resumen.cobrosDelPeriodo, Dinero.cero);
      expect(resumen.deudaVencida, Dinero.cero);
      expect(resumen.proximosCobros, isEmpty);
    });

    test('es de solo lectura: no materializa cuotas ni escribe pagos',
        () async {
      // Un hoy muy posterior: si el dashboard pusiera al día, aparecerían
      // cuotas nuevas de todos los meses intermedios.
      await consultar.ejecutar(hoy: DateTime(2028, 3, 1));

      expect(await cuotas.todas(), hasLength(6));
      expect(await pagos.todos(), hasLength(3));
    });
  });
}
