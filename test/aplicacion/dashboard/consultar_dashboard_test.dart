import 'package:alquilaya/aplicacion/cuotas/listar_cuotas.dart';
import 'package:alquilaya/aplicacion/dashboard/consultar_dashboard.dart';
import 'package:alquilaya/aplicacion/habitaciones/listar_habitaciones.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/contratos_activos_falsos.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('ConsultarDashboard', () {
    final monto = Dinero(35000);

    /// Vivienda de dos habitaciones, h1 ocupada por el contrato c1.
    ///
    /// Cuotas de c1: agosto pagada (tarde), septiembre vencida e impaga,
    /// octubre pagada por adelantado, noviembre y diciembre pendientes.
    /// El contrato c2 aporta una cuota de octubre pagada, para que los cobros
    /// del mes crucen más de un contrato.
    ///
    /// A 5 de octubre de 2026: deuda = septiembre + noviembre + diciembre.
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

    ConsultarDashboard dashboardCon({
      required List<Habitacion> habitaciones,
      required Set<String> ocupadas,
      required List<Cuota> cuotasIniciales,
      required List<Pago> pagosIniciales,
    }) {
      cuotas = RepositorioDeCuotasEnMemoria(cuotasIniciales);
      pagos = RepositorioDePagosEnMemoria(pagosIniciales);
      return ConsultarDashboard(
        ListarHabitaciones(
          RepositorioDeHabitacionesEnMemoria(habitaciones),
          ContratosActivosFalsos(ocupadas),
        ),
        ListarCuotas(cuotas, pagos),
        pagos,
      );
    }

    setUp(() {
      consultar = dashboardCon(
        habitaciones: [
          Habitacion(id: 'h1', nombre: 'Habitación 1'),
          Habitacion(id: 'h2', nombre: 'Habitación 2'),
        ],
        ocupadas: {'h1'},
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

    test('consultar otro período no altera la deuda ni los vencimientos',
        () async {
      final octubre = await consultar.ejecutar(hoy: hoy);
      final septiembre = await consultar.ejecutar(
        hoy: hoy,
        periodo: Periodo(2026, 9),
      );

      // Mirar los cobros de un mes pasado no cambia cuánto se debe hoy.
      expect(septiembre.periodo, Periodo(2026, 9));
      expect(septiembre.deudaAcumulada, octubre.deudaAcumulada);
      expect(
        septiembre.proximosVencimientos.map((c) => c.cuota.id),
        octubre.proximosVencimientos.map((c) => c.cuota.id),
      );
    });

    test('la deuda suma las cuotas vencidas y pendientes, no las pagadas',
        () async {
      final resumen = await consultar.ejecutar(hoy: hoy);

      // cu2 vencida + cu4 y cu5 pendientes; cu1, cu3 y cu6 están pagadas.
      expect(resumen.deudaAcumulada, Dinero(105000));
    });

    test('próximos vencimientos: solo pendientes, por fecha de vencimiento',
        () async {
      final resumen = await consultar.ejecutar(hoy: hoy);

      // cu2 está vencida y no cuenta como próximo vencimiento.
      expect(resumen.proximosVencimientos.map((c) => c.cuota.id), [
        'cu4',
        'cu5',
      ]);
      expect(
        resumen.proximosVencimientos.map((c) => c.estado),
        everyElement(EstadoCuota.pendiente),
      );
    });

    test('sin datos devuelve ceros y listas vacías', () async {
      final vacio = dashboardCon(
        habitaciones: const [],
        ocupadas: const {},
        cuotasIniciales: const [],
        pagosIniciales: const [],
      );

      final resumen = await vacio.ejecutar(hoy: hoy);

      expect(resumen.habitacionesOcupadas, 0);
      expect(resumen.habitacionesDisponibles, 0);
      expect(resumen.cobrosDelPeriodo, Dinero.cero);
      expect(resumen.deudaAcumulada, Dinero.cero);
      expect(resumen.proximosVencimientos, isEmpty);
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
