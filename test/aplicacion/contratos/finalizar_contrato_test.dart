import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/crear_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/finalizar_contrato.dart';
import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/estado_de_ocupacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/listar_habitaciones.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/generador_de_id_secuencial.dart';
import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';
import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('FinalizarContrato', () {
    final montoMensual = Dinero(35000);
    final inicio = DateTime(2026, 8, 20); // día base de cobro: 20

    /// Fecha desde la que se finaliza en estos tests. Es posterior a todas las
    /// fechas de fin que usan, para que ninguna sea futura; se pasa explícita y
    /// nunca `DateTime.now()`, de modo que el resultado no dependa del reloj.
    final hoy = DateTime(2026, 12, 1);

    late RepositorioDeContratosEnMemoria contratos;
    late RepositorioDeCuotasEnMemoria cuotas;
    late RepositorioDePagosEnMemoria pagos;
    late RepositorioDeHabitacionesEnMemoria habitaciones;
    late ActualizarCuotasDeContrato actualizar;
    late CrearContrato crear;
    late FinalizarContrato finalizar;

    setUp(() {
      contratos = RepositorioDeContratosEnMemoria();
      cuotas = RepositorioDeCuotasEnMemoria();
      pagos = RepositorioDePagosEnMemoria();
      habitaciones = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
      ]);
      final generador = GeneradorDeIdSecuencial();
      actualizar = ActualizarCuotasDeContrato(contratos, cuotas, generador);
      crear = CrearContrato(
        contratos,
        cuotas,
        pagos,
        habitaciones,
        RepositorioDeInquilinosEnMemoria([
          Inquilino(id: 'i1', nombre: 'Ana Torres'),
        ]),
        generador,
      );
      finalizar = FinalizarContrato(contratos, cuotas, pagos, actualizar);
    });

    /// Crea el contrato con su primera cuota pagada, y nada más: es el estado
    /// de un contrato del que nunca se ejecutó la puesta al día.
    Future<Contrato> contratoRecienCreado() => crear.ejecutar(
      habitacionId: 'h1',
      inquilinoId: 'i1',
      fechaInicio: inicio,
      montoMensual: montoMensual,
    );

    Future<List<DateTime>> vencimientosDe(String contratoId) async {
      final guardadas = await cuotas.deContrato(contratoId);
      return guardadas.map((c) => c.fechaVencimiento).toList()..sort();
    }

    test('deja el contrato finalizado', () async {
      final contrato = await contratoRecienCreado();

      final finalizado = await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 11, 20),
        hoy: hoy,
      );

      expect(finalizado.estaActivo, isFalse);
      expect(finalizado.fechaFin, DateTime(2026, 11, 20));
      expect((await contratos.obtenerPorId(contrato.id))!.estaActivo, isFalse);
    });

    test('la habitación vuelve a estar disponible (regla 4)', () async {
      final contrato = await contratoRecienCreado();

      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 11, 20),
        hoy: hoy,
      );

      final listado = await ListarHabitaciones(habitaciones, contratos)
          .ejecutar();
      expect(listado.single.estado, EstadoDeOcupacion.disponible);
    });

    test('materializa la deuda vencida que nunca se llegó a generar', () async {
      final contrato = await contratoRecienCreado();
      // Solo existe la primera cuota: nadie ejecutó la puesta al día.
      expect(await cuotas.deContrato(contrato.id), hasLength(1));

      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 11, 20),
        hoy: hoy,
      );

      // Septiembre, octubre y noviembre se conservan como deuda impaga.
      expect(await vencimientosDe(contrato.id), [
        DateTime(2026, 8, 20),
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 20),
        DateTime(2026, 11, 20),
      ]);
    });

    test('finalizar a mitad de mes no materializa la cuota que aún no vencía',
        () async {
      final contrato = await contratoRecienCreado();

      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 11, 15),
        hoy: hoy,
      );

      // La de noviembre vencía el 20: aún no correspondía.
      expect(await vencimientosDe(contrato.id), [
        DateTime(2026, 8, 20),
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 20),
      ]);
    });

    test('no deja ninguna cuota con vencimiento posterior a la fecha de fin',
        () async {
      final contrato = await contratoRecienCreado();
      final fechaFin = DateTime(2026, 11, 20);

      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: fechaFin,
        hoy: hoy,
      );

      expect(
        await vencimientosDe(contrato.id),
        everyElement(predicate<DateTime>((v) => !v.isAfter(fechaFin))),
      );
    });

    test('materializar no duplica las cuotas que ya estaban al día', () async {
      final contrato = await contratoRecienCreado();
      await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 11, 5),
      );
      final idsPrevios = (await cuotas.deContrato(contrato.id))
          .map((c) => c.id)
          .toSet();

      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 11, 20),
        hoy: hoy,
      );

      // La de diciembre sobraba y se elimina; las demás son las mismas.
      final restantes = await cuotas.deContrato(contrato.id);
      expect(restantes, hasLength(4));
      expect(idsPrevios.containsAll(restantes.map((c) => c.id)), isTrue);
    });

    test('conserva la deuda vencida y elimina la cuota que aún no correspondía '
        '(regla 12, ejemplo de PROJECT.md)', () async {
      final contrato = await contratoRecienCreado();
      await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 10, 5),
      );

      // Día base 20, fin el 15/10: la cuota de octubre aún no correspondía.
      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 10, 15),
        hoy: hoy,
      );

      expect(await vencimientosDe(contrato.id), [
        DateTime(2026, 8, 20),
        DateTime(2026, 9, 20),
      ]);
    });

    test('una cuota posterior a la fecha de fin con pago se conserva, '
        'y ningún pago se elimina (reglas 3 y 12)', () async {
      final contrato = await contratoRecienCreado();
      await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 10, 5),
      );
      final octubre = (await cuotas.deContrato(contrato.id)).firstWhere(
        (c) => c.fechaVencimiento == DateTime(2026, 10, 20),
      );
      await pagos.guardar(
        Pago(
          id: 'pago-octubre',
          cuotaId: octubre.id,
          monto: montoMensual,
          fechaPago: DateTime(2026, 10, 1),
        ),
      );

      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 10, 15),
        hoy: hoy,
      );

      expect(await vencimientosDe(contrato.id), contains(DateTime(2026, 10, 20)));
      expect(await pagos.todos(), hasLength(2));
    });

    test('una cuota que vence exactamente el día de fin se conserva', () async {
      final contrato = await contratoRecienCreado();

      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 10, 20),
        hoy: hoy,
      );

      expect(
        await vencimientosDe(contrato.id),
        contains(DateTime(2026, 10, 20)),
      );
    });

    test('finalizar dos veces lanza el StateError del dominio sin cambiar nada',
        () async {
      final contrato = await contratoRecienCreado();
      await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 10, 20),
        hoy: hoy,
      );
      final vencimientosTrasFinalizar = await vencimientosDe(contrato.id);

      await expectLater(
        finalizar.ejecutar(
          contratoId: contrato.id,
          fechaFin: DateTime(2026, 11, 20),
          hoy: hoy,
        ),
        throwsStateError,
      );

      final guardado = (await contratos.obtenerPorId(contrato.id))!;
      expect(guardado.fechaFin, DateTime(2026, 10, 20));
      expect(await vencimientosDe(contrato.id), vencimientosTrasFinalizar);
    });

    test('una fecha de fin anterior al inicio propaga el error del dominio '
        'sin cambiar nada', () async {
      final contrato = await contratoRecienCreado();

      await expectLater(
        finalizar.ejecutar(
          contratoId: contrato.id,
          fechaFin: DateTime(2026, 7, 1),
          hoy: hoy,
        ),
        throwsArgumentError,
      );

      expect((await contratos.obtenerPorId(contrato.id))!.estaActivo, isTrue);
      expect(await cuotas.deContrato(contrato.id), hasLength(1));
    });

    test('un contrato inexistente lanza ContratoNoEncontrado', () {
      expect(
        () => finalizar.ejecutar(
          contratoId: 'desconocido',
          fechaFin: DateTime(2026, 11, 20),
          hoy: hoy,
        ),
        throwsA(isA<ContratoNoEncontrado>()),
      );
    });

    test('una fecha de fin futura se rechaza sin tocar nada', () async {
      final contrato = await contratoRecienCreado();

      // `Cuota` y `Pago` comparan por id, así que comparar las entidades no
      // detectaría un cambio de monto, período o fecha. Se retrata su
      // contenido campo a campo y se ordena para que no dependa del orden.
      Future<List<String>> retratoDeCuotas() async =>
          (await cuotas.deContrato(contrato.id))
              .map(
                (c) =>
                    '${c.id}|${c.contratoId}|${c.periodo}|'
                    '${c.monto}|${c.fechaVencimiento}',
              )
              .toList()
            ..sort();

      Future<List<String>> retratoDePagos() async => (await pagos.todos())
          .map((p) => '${p.id}|${p.cuotaId}|${p.monto}|${p.fechaPago}')
          .toList()
        ..sort();

      final cuotasAntes = await retratoDeCuotas();
      final pagosAntes = await retratoDePagos();
      expect(cuotasAntes, isNotEmpty);
      expect(pagosAntes, isNotEmpty);

      await expectLater(
        finalizar.ejecutar(
          contratoId: contrato.id,
          // Un día después de hoy: la salida todavía no ha ocurrido.
          fechaFin: DateTime(2026, 12, 2),
          hoy: hoy,
        ),
        throwsA(isA<FechaDeFinFutura>()),
      );

      // El contrato sigue vigente y la habitación ocupada.
      expect((await contratos.obtenerPorId(contrato.id))!.estaActivo, isTrue);
      final listado = await ListarHabitaciones(habitaciones, contratos)
          .ejecutar();
      expect(listado.single.estado, EstadoDeOcupacion.ocupada);

      // Ni una cuota ni un pago cambiaron, en número ni en contenido.
      expect(await retratoDeCuotas(), cuotasAntes);
      expect(await retratoDePagos(), pagosAntes);
    });

    test('finalizar hoy mismo se permite', () async {
      final contrato = await contratoRecienCreado();

      final finalizado = await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: hoy,
        hoy: hoy,
      );

      expect(finalizado.fechaFin, hoy);
      expect(finalizado.estaActivo, isFalse);
    });

    test('finalizar en una fecha pasada se permite', () async {
      final contrato = await contratoRecienCreado();

      final finalizado = await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 9, 30),
        hoy: hoy,
      );

      expect(finalizado.fechaFin, DateTime(2026, 9, 30));
      expect(finalizado.estaActivo, isFalse);
    });

    test('la hora no cuenta: finalizar hoy vale a cualquier hora', () async {
      final contrato = await contratoRecienCreado();

      // La fecha de fin lleva hora y es "posterior" a hoy como instante, pero
      // es el mismo día de calendario.
      final finalizado = await finalizar.ejecutar(
        contratoId: contrato.id,
        fechaFin: DateTime(2026, 12, 1, 23, 59),
        hoy: DateTime(2026, 12, 1),
      );

      expect(finalizado.estaActivo, isFalse);
    });
  });
}
