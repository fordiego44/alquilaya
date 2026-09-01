import 'package:alquilaya/aplicacion/cuotas/listar_cuotas.dart';
import 'package:alquilaya/aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import 'package:alquilaya/aplicacion/excepciones.dart';
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
  group('ListarCuotasParaCobro', () {
    final monto = Dinero(35000);

    /// A 25 de septiembre: agosto ya pagada, septiembre vencida, octubre aún
    /// pendiente.
    final hoy = DateTime(2026, 9, 25);

    late RepositorioDeCuotasEnMemoria cuotas;
    late RepositorioDePagosEnMemoria pagos;
    late RepositorioDeContratosEnMemoria contratos;
    late RepositorioDeHabitacionesEnMemoria habitaciones;
    late RepositorioDeInquilinosEnMemoria inquilinos;

    Cuota cuota(String id, String contratoId, int mes) => Cuota(
      id: id,
      contratoId: contratoId,
      periodo: Periodo(2026, mes),
      monto: monto,
      fechaVencimiento: DateTime(2026, mes, 20),
    );

    Contrato contrato(String id, String habitacionId, String inquilinoId) =>
        Contrato(
          id: id,
          habitacionId: habitacionId,
          inquilinoId: inquilinoId,
          fechaInicio: DateTime(2026, 8, 20),
          montoMensual: monto,
        );

    ListarCuotasParaCobro casoDeUso() => ListarCuotasParaCobro(
      ListarCuotas(cuotas, pagos),
      contratos,
      habitaciones,
      inquilinos,
    );

    setUp(() async {
      // Las cuotas se guardan desordenadas a propósito: el orden lo pone
      // ListarCuotas, no el almacén.
      cuotas = RepositorioDeCuotasEnMemoria([
        cuota('cu3', 'c2', 10),
        cuota('cu1', 'c1', 8),
        cuota('cu2', 'c1', 9),
      ]);
      pagos = RepositorioDePagosEnMemoria([
        Pago(
          id: 'p1',
          cuotaId: 'cu1',
          monto: monto,
          fechaPago: DateTime(2026, 8, 20),
        ),
      ]);
      habitaciones = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
        Habitacion(id: 'h2', nombre: 'Habitación 2'),
      ]);
      inquilinos = RepositorioDeInquilinosEnMemoria([
        Inquilino(id: 'i1', nombre: 'Juan Pérez', telefono: '951234567'),
        // Sin teléfono: el dato no se conoce.
        Inquilino(id: 'i2', nombre: 'Ana Torres'),
      ]);
      contratos = RepositorioDeContratosEnMemoria([
        contrato('c1', 'h1', 'i1'),
        contrato('c2', 'h2', 'i2'),
      ]);
    });

    test('añade inquilino, habitación y teléfono a cada cuota', () async {
      final resultado = await casoDeUso().ejecutar(hoy: hoy);

      final septiembre = resultado.firstWhere((c) => c.cuota.cuota.id == 'cu2');
      expect(septiembre.nombreInquilino, 'Juan Pérez');
      expect(septiembre.nombreHabitacion, 'Habitación 1');
      expect(septiembre.telefono, '951234567');
      // Lo que ya traía la cuota sigue intacto.
      expect(septiembre.cuota.estado, EstadoCuota.vencida);
      expect(septiembre.cuota.montoPendiente, monto);
    });

    test('un inquilino sin teléfono llega con null', () async {
      final resultado = await casoDeUso().ejecutar(hoy: hoy);

      final octubre = resultado.firstWhere((c) => c.cuota.cuota.id == 'cu3');
      expect(octubre.nombreInquilino, 'Ana Torres');
      expect(octubre.nombreHabitacion, 'Habitación 2');
      expect(octubre.telefono, isNull);
    });

    test('conserva el orden por vencimiento y el filtro por estado', () async {
      final todas = await casoDeUso().ejecutar(hoy: hoy);
      expect(todas.map((c) => c.cuota.cuota.id), ['cu1', 'cu2', 'cu3']);

      final vencidas = await casoDeUso().ejecutar(
        hoy: hoy,
        estado: EstadoCuota.vencida,
      );
      expect(vencidas.map((c) => c.cuota.cuota.id), ['cu2']);

      final pagadas = await casoDeUso().ejecutar(
        hoy: hoy,
        estado: EstadoCuota.pagada,
      );
      expect(pagadas.single.cuota.cuota.id, 'cu1');
    });

    test('sin cuotas devuelve una lista vacía', () async {
      cuotas = RepositorioDeCuotasEnMemoria();

      expect(await casoDeUso().ejecutar(hoy: hoy), isEmpty);
    });

    test('una cuota cuyo contrato no existe es una inconsistencia', () async {
      await cuotas.guardarTodas([cuota('cu9', 'c9', 9)]);

      expect(
        () => casoDeUso().ejecutar(hoy: hoy),
        throwsA(isA<ReferenciaInconsistente>()),
      );
    });

    test('un contrato cuya habitación no existe es una inconsistencia',
        () async {
      await contratos.guardar(contrato('c3', 'h9', 'i1'));
      await cuotas.guardarTodas([cuota('cu4', 'c3', 9)]);

      expect(
        () => casoDeUso().ejecutar(hoy: hoy),
        throwsA(isA<ReferenciaInconsistente>()),
      );
    });

    test('un contrato cuyo inquilino no existe es una inconsistencia',
        () async {
      await contratos.guardar(contrato('c4', 'h1', 'i9'));
      await cuotas.guardarTodas([cuota('cu5', 'c4', 9)]);

      expect(
        () => casoDeUso().ejecutar(hoy: hoy),
        throwsA(isA<ReferenciaInconsistente>()),
      );
    });
  });
}
