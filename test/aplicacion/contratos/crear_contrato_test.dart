import 'package:alquilaya/aplicacion/contratos/crear_contrato.dart';
import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/estado_de_ocupacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/listar_habitaciones.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/generador_de_id_secuencial.dart';
import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';
import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('CrearContrato', () {
    late RepositorioDeContratosEnMemoria contratos;
    late RepositorioDeCuotasEnMemoria cuotas;
    late RepositorioDePagosEnMemoria pagos;
    late RepositorioDeHabitacionesEnMemoria habitaciones;
    late CrearContrato crear;

    final montoMensual = Dinero(35000);
    final inicio = DateTime(2026, 8, 20);

    setUp(() {
      contratos = RepositorioDeContratosEnMemoria();
      cuotas = RepositorioDeCuotasEnMemoria();
      pagos = RepositorioDePagosEnMemoria();
      habitaciones = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
      ]);
      crear = CrearContrato(
        contratos,
        cuotas,
        pagos,
        habitaciones,
        RepositorioDeInquilinosEnMemoria([
          Inquilino(id: 'i1', nombre: 'Ana Torres'),
        ]),
        GeneradorDeIdSecuencial(),
      );
    });

    Future<void> esperarAlmacenVacio() async {
      expect(await contratos.listar(), isEmpty);
      expect(await cuotas.todas(), isEmpty);
      expect(await pagos.todos(), isEmpty);
    }

    Future<Contrato> crearSobreH1() => crear.ejecutar(
      habitacionId: 'h1',
      inquilinoId: 'i1',
      fechaInicio: inicio,
      montoMensual: montoMensual,
    );

    test('guarda el contrato con sus datos', () async {
      final contrato = await crearSobreH1();

      expect(contrato.habitacionId, 'h1');
      expect(contrato.inquilinoId, 'i1');
      expect(contrato.montoMensual, montoMensual);
      expect(contrato.estaActivo, isTrue);
      expect(await contratos.obtenerPorId(contrato.id), contrato);
    });

    test('genera una única cuota, la primera, que vence el día de inicio',
        () async {
      final contrato = await crearSobreH1();

      final generadas = await cuotas.deContrato(contrato.id);
      expect(generadas, hasLength(1));
      expect(generadas.single.periodo, Periodo(2026, 8));
      expect(generadas.single.fechaVencimiento, inicio);
      expect(generadas.single.monto, montoMensual);
    });

    test('registra el pago íntegro de la primera cuota con fecha de inicio '
        '(regla 9)', () async {
      final contrato = await crearSobreH1();

      final primeraCuota = (await cuotas.deContrato(contrato.id)).single;
      final registrados = await pagos.deCuotas([primeraCuota.id]);
      expect(registrados, hasLength(1));
      expect(registrados.single.monto, montoMensual);
      expect(registrados.single.fechaPago, inicio);
      expect(primeraCuota.estaPagada(registrados), isTrue);
    });

    test('la habitación pasa a verse ocupada (regla 1, lado de lectura)',
        () async {
      await crearSobreH1();

      expect(await contratos.tieneContratoActivo('h1'), isTrue);
      final listado = await ListarHabitaciones(habitaciones, contratos)
          .ejecutar();
      expect(listado.single.estado, EstadoDeOcupacion.ocupada);
    });

    test('rechaza un segundo contrato activo sobre la misma habitación '
        'y no guarda nada (regla 1)', () async {
      final primero = await crearSobreH1();
      final cuotaOriginal = (await cuotas.deContrato(primero.id)).single;

      await expectLater(crearSobreH1(), throwsA(isA<HabitacionOcupada>()));

      // Sigue existiendo solo el contrato original, con su cuota y su pago.
      expect(await contratos.listar(), [primero]);
      expect(await cuotas.todas(), [cuotaOriginal]);
      final registrados = await pagos.todos();
      expect(registrados, hasLength(1));
      expect(registrados.single.cuotaId, cuotaOriginal.id);
    });

    test('una habitación con contrato finalizado admite uno nuevo', () async {
      final primero = await crearSobreH1();
      await contratos.guardar(primero.finalizar(DateTime(2026, 10, 20)));

      final segundo = await crear.ejecutar(
        habitacionId: 'h1',
        inquilinoId: 'i1',
        fechaInicio: DateTime(2026, 11, 1),
        montoMensual: montoMensual,
      );

      expect(segundo.estaActivo, isTrue);
      expect(await contratos.tieneContratoActivo('h1'), isTrue);
    });

    test('una habitación inexistente no crea nada', () async {
      await expectLater(
        crear.ejecutar(
          habitacionId: 'desconocida',
          inquilinoId: 'i1',
          fechaInicio: inicio,
          montoMensual: montoMensual,
        ),
        throwsA(isA<HabitacionNoEncontrada>()),
      );
      await esperarAlmacenVacio();
    });

    test('un inquilino inexistente no crea nada', () async {
      await expectLater(
        crear.ejecutar(
          habitacionId: 'h1',
          inquilinoId: 'desconocido',
          fechaInicio: inicio,
          montoMensual: montoMensual,
        ),
        throwsA(isA<InquilinoNoEncontrado>()),
      );
      await esperarAlmacenVacio();
    });

    test('un monto no positivo propaga el error del dominio sin guardar nada',
        () async {
      await expectLater(
        crear.ejecutar(
          habitacionId: 'h1',
          inquilinoId: 'i1',
          fechaInicio: inicio,
          montoMensual: Dinero.cero,
        ),
        throwsArgumentError,
      );
      await esperarAlmacenVacio();
    });

    test('inicio el 31/01 vence el 31/01, no arrastra a febrero', () async {
      final contrato = await crear.ejecutar(
        habitacionId: 'h1',
        inquilinoId: 'i1',
        fechaInicio: DateTime(2026, 1, 31),
        montoMensual: montoMensual,
      );

      final primeraCuota = (await cuotas.deContrato(contrato.id)).single;
      expect(primeraCuota.fechaVencimiento, DateTime(2026, 1, 31));
    });
  });
}
