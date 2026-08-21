import 'package:alquilaya/dominio/calendario_de_pagos.dart';
import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('vencimientoDeCuota', () {
    test('la primera cuota vence el mismo día de inicio: se cobra por adelantado', () {
      final inicio = DateTime(2026, 8, 20);
      expect(CalendarioDePagos.vencimientoDeCuota(inicio, 0), inicio);
    });

    test('con día base 20 vence el 20 de cada mes', () {
      final inicio = DateTime(2026, 8, 20);
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 1),
        DateTime(2026, 9, 20),
      );
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 5),
        DateTime(2027, 1, 20),
      );
    });

    test('día base 31: ajusta al último día del mes sin arrastrar el ajuste', () {
      final inicio = DateTime(2026, 1, 31);
      final serie = List.generate(
        5,
        (indice) => CalendarioDePagos.vencimientoDeCuota(inicio, indice),
      );
      expect(serie, [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 31),
      ]);
    });

    test('día base 29 en año bisiesto se respeta', () {
      final inicio = DateTime(2024, 1, 29);
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 1),
        DateTime(2024, 2, 29),
      );
    });

    test('día base 29 en año no bisiesto se ajusta y luego se recupera', () {
      final inicio = DateTime(2026, 1, 29);
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 1),
        DateTime(2026, 2, 28),
      );
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 2),
        DateTime(2026, 3, 29),
      );
    });

    test('día base 30 se ajusta en febrero', () {
      final inicio = DateTime(2026, 1, 30);
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 1),
        DateTime(2026, 2, 28),
      );
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 3),
        DateTime(2026, 4, 30),
      );
    });

    test('el vencimiento se normaliza a medianoche aunque el inicio tenga hora', () {
      final inicio = DateTime(2026, 8, 20, 15, 30);
      expect(
        CalendarioDePagos.vencimientoDeCuota(inicio, 1),
        DateTime(2026, 9, 20),
      );
    });

    test('rechaza índices negativos', () {
      expect(
        () => CalendarioDePagos.vencimientoDeCuota(DateTime(2026, 8, 20), -1),
        throwsArgumentError,
      );
    });
  });

  group('periodoDeCuota', () {
    test('avanza mes a mes cruzando el año', () {
      final inicio = DateTime(2026, 8, 20);
      expect(CalendarioDePagos.periodoDeCuota(inicio, 0), Periodo(2026, 8));
      expect(CalendarioDePagos.periodoDeCuota(inicio, 4), Periodo(2026, 12));
      expect(CalendarioDePagos.periodoDeCuota(inicio, 5), Periodo(2027, 1));
      expect(CalendarioDePagos.periodoDeCuota(inicio, 17), Periodo(2028, 1));
    });
  });

  group('ultimoDiaDelMes', () {
    test('conoce los meses cortos y los bisiestos', () {
      expect(CalendarioDePagos.ultimoDiaDelMes(2026, 2), 28);
      expect(CalendarioDePagos.ultimoDiaDelMes(2024, 2), 29);
      expect(CalendarioDePagos.ultimoDiaDelMes(2026, 4), 30);
      expect(CalendarioDePagos.ultimoDiaDelMes(2026, 12), 31);
    });
  });

  group('cuotasHasta', () {
    final inicio = DateTime(2026, 8, 20);

    test('el mismo día de inicio ya corresponden dos: la actual y una por delante', () {
      expect(
        CalendarioDePagos.cuotasHasta(fechaInicio: inicio, hoy: inicio),
        2,
      );
    });

    test('cubre hasta el mes actual más uno', () {
      expect(
        CalendarioDePagos.cuotasHasta(
          fechaInicio: inicio,
          hoy: DateTime(2026, 10, 15),
        ),
        4, // agosto, septiembre, octubre y noviembre
      );
    });

    test('un contrato finalizado no genera cuotas posteriores a su fin', () {
      expect(
        CalendarioDePagos.cuotasHasta(
          fechaInicio: inicio,
          hoy: DateTime(2026, 10, 15),
          fechaFin: DateTime(2026, 10, 15),
        ),
        2, // la de octubre vencía el 20: aún no correspondía
      );
    });

    test('la primera cuota siempre cuenta: se paga al crear el contrato', () {
      expect(
        CalendarioDePagos.cuotasHasta(
          fechaInicio: inicio,
          hoy: inicio,
          fechaFin: inicio,
        ),
        1,
      );
    });
  });
}
