import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/crear_contrato.dart';
import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/generador_de_id_secuencial.dart';
import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';
import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('ActualizarCuotasDeContrato', () {
    final montoMensual = Dinero(35000);

    late RepositorioDeContratosEnMemoria contratos;
    late RepositorioDeCuotasEnMemoria cuotas;
    late ActualizarCuotasDeContrato actualizar;

    setUp(() {
      contratos = RepositorioDeContratosEnMemoria();
      cuotas = RepositorioDeCuotasEnMemoria();
      actualizar = ActualizarCuotasDeContrato(
        contratos,
        cuotas,
        GeneradorDeIdSecuencial('cu'),
      );
    });

    /// Contrato con día base 20, iniciado en agosto de 2026.
    Future<Contrato> contratoDesdeAgosto({DateTime? fechaFin}) async {
      final contrato = Contrato(
        id: 'c1',
        habitacionId: 'h1',
        inquilinoId: 'i1',
        fechaInicio: DateTime(2026, 8, 20),
        montoMensual: montoMensual,
        fechaFin: fechaFin,
      );
      await contratos.guardar(contrato);
      return contrato;
    }

    Future<List<DateTime>> vencimientosGuardados(String contratoId) async {
      final guardadas = await cuotas.deContrato(contratoId);
      return guardadas.map((c) => c.fechaVencimiento).toList()..sort();
    }

    test('genera desde el mes de inicio hasta el mes actual más uno', () async {
      final contrato = await contratoDesdeAgosto();

      final nuevas = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 11, 5),
      );

      expect(nuevas.map((c) => c.fechaVencimiento), [
        DateTime(2026, 8, 20),
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 20),
        DateTime(2026, 11, 20),
        DateTime(2026, 12, 20),
      ]);
    });

    test('las cuotas generadas heredan el monto mensual del contrato',
        () async {
      final contrato = await contratoDesdeAgosto();

      final nuevas = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 9, 5),
      );

      expect(nuevas.map((c) => c.monto), everyElement(montoMensual));
      expect(nuevas.map((c) => c.contratoId), everyElement(contrato.id));
    });

    test('es idempotente: la segunda ejecución no devuelve ni crea nada',
        () async {
      final contrato = await contratoDesdeAgosto();
      final hoy = DateTime(2026, 11, 5);

      final primeras = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: hoy,
      );
      final segundas = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: hoy,
      );

      expect(segundas, isEmpty);
      expect(await cuotas.deContrato(contrato.id), hasLength(primeras.length));
    });

    test('avanzar un mes añade exactamente una cuota', () async {
      final contrato = await contratoDesdeAgosto();
      await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 11, 5),
      );

      final nuevas = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 12, 5),
      );

      expect(nuevas, hasLength(1));
      expect(nuevas.single.fechaVencimiento, DateTime(2027, 1, 20));
    });

    test('no duplica la primera cuota creada por CrearContrato', () async {
      final habitaciones = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
      ]);
      final crear = CrearContrato(
        contratos,
        cuotas,
        RepositorioDePagosEnMemoria(),
        habitaciones,
        RepositorioDeInquilinosEnMemoria([
          Inquilino(id: 'i1', nombre: 'Ana Torres'),
        ]),
        GeneradorDeIdSecuencial(),
      );
      final contrato = await crear.ejecutar(
        habitacionId: 'h1',
        inquilinoId: 'i1',
        fechaInicio: DateTime(2026, 8, 20),
        montoMensual: montoMensual,
      );

      final nuevas = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 9, 5),
      );

      // Agosto ya existía; solo se añaden septiembre y octubre.
      expect(nuevas.map((c) => c.fechaVencimiento), [
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 20),
      ]);
      expect(await vencimientosGuardados(contrato.id), [
        DateTime(2026, 8, 20),
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 20),
      ]);
    });

    test('un contrato finalizado no genera cuotas posteriores a su fecha de fin',
        () async {
      final contrato = await contratoDesdeAgosto(
        fechaFin: DateTime(2026, 10, 20),
      );

      final nuevas = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 11, 5),
      );

      expect(nuevas.map((c) => c.fechaVencimiento), [
        DateTime(2026, 8, 20),
        DateTime(2026, 9, 20),
        DateTime(2026, 10, 20),
      ]);
    });

    test('el día base no se arrastra cuando un mes es más corto', () async {
      final contrato = Contrato(
        id: 'c2',
        habitacionId: 'h1',
        inquilinoId: 'i1',
        fechaInicio: DateTime(2025, 12, 31),
        montoMensual: montoMensual,
      );
      await contratos.guardar(contrato);

      final nuevas = await actualizar.ejecutar(
        contratoId: contrato.id,
        hoy: DateTime(2026, 3, 10),
      );

      expect(nuevas.map((c) => c.fechaVencimiento), [
        DateTime(2025, 12, 31),
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });

    test('un contrato inexistente lanza ContratoNoEncontrado', () {
      expect(
        () => actualizar.ejecutar(
          contratoId: 'desconocido',
          hoy: DateTime(2026, 11, 5),
        ),
        throwsA(isA<ContratoNoEncontrado>()),
      );
    });
  });
}
