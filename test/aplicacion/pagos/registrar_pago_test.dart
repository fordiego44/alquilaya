import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/pagos/registrar_pago.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/generador_de_id_secuencial.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';
import '../../dobles/repositorio_de_pagos_en_memoria.dart';

void main() {
  group('RegistrarPago', () {
    final monto = Dinero(35000);
    final fechaPago = DateTime(2026, 8, 20);

    late RepositorioDeCuotasEnMemoria cuotas;
    late RepositorioDePagosEnMemoria pagos;
    late RegistrarPago registrar;

    Cuota cuotaDeAgosto() => Cuota(
      id: 'cu1',
      contratoId: 'c1',
      periodo: Periodo(2026, 8),
      monto: monto,
      fechaVencimiento: DateTime(2026, 8, 20),
    );

    setUp(() {
      cuotas = RepositorioDeCuotasEnMemoria([cuotaDeAgosto()]);
      pagos = RepositorioDePagosEnMemoria();
      registrar = RegistrarPago(cuotas, pagos, GeneradorDeIdSecuencial('p'));
    });

    test('guarda el pago y lo devuelve', () async {
      final pago = await registrar.ejecutar(
        cuotaId: 'cu1',
        monto: monto,
        fechaPago: fechaPago,
      );

      expect(pago.id, 'p1');
      expect(pago.cuotaId, 'cu1');
      expect(pago.monto, monto);
      expect(pago.fechaPago, fechaPago);
      expect(await pagos.todos(), [pago]);
    });

    test('la cuota queda pagada tras registrar el pago', () async {
      await registrar.ejecutar(
        cuotaId: 'cu1',
        monto: monto,
        fechaPago: fechaPago,
      );

      final cuota = (await cuotas.obtenerPorId('cu1'))!;
      expect(cuota.estadoSegun(await pagos.todos(), fechaPago),
          EstadoCuota.pagada);
    });

    test('falla si la cuota no existe', () async {
      expect(
        () => registrar.ejecutar(
          cuotaId: 'inexistente',
          monto: monto,
          fechaPago: fechaPago,
        ),
        throwsA(isA<CuotaNoEncontrada>()),
      );
      expect(await pagos.todos(), isEmpty);
    });

    test('rechaza el pago parcial sin guardar nada', () async {
      expect(
        () => registrar.ejecutar(
          cuotaId: 'cu1',
          monto: Dinero(10000),
          fechaPago: fechaPago,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await pagos.todos(), isEmpty);
    });

    test('rechaza el sobrepago sin guardar nada', () async {
      expect(
        () => registrar.ejecutar(
          cuotaId: 'cu1',
          monto: Dinero(50000),
          fechaPago: fechaPago,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(await pagos.todos(), isEmpty);
    });

    test('una cuota ya pagada no admite un segundo pago', () async {
      await registrar.ejecutar(
        cuotaId: 'cu1',
        monto: monto,
        fechaPago: fechaPago,
      );

      expect(
        () => registrar.ejecutar(
          cuotaId: 'cu1',
          monto: monto,
          fechaPago: DateTime(2026, 8, 25),
        ),
        throwsA(isA<StateError>()),
      );
      expect(await pagos.todos(), hasLength(1));
    });

    test('un pago de otra cuota no da la cuota por saldada', () async {
      // La deuda vencida de un contrato finalizado (regla 12) tiene que poder
      // saldarse: el caso de uso no comprueba el contrato, solo la cuota.
      await cuotas.guardarTodas([
        Cuota(
          id: 'cu2',
          contratoId: 'c1',
          periodo: Periodo(2026, 9),
          monto: monto,
          fechaVencimiento: DateTime(2026, 9, 20),
        ),
      ]);
      await registrar.ejecutar(
        cuotaId: 'cu2',
        monto: monto,
        fechaPago: DateTime(2026, 9, 20),
      );

      final pago = await registrar.ejecutar(
        cuotaId: 'cu1',
        monto: monto,
        fechaPago: fechaPago,
      );

      expect(pago.cuotaId, 'cu1');
      expect(await pagos.todos(), hasLength(2));
    });
  });
}
