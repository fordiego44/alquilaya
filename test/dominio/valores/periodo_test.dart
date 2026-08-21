import 'package:alquilaya/dominio/valores/periodo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Periodo', () {
    test('rechaza meses fuera de 1..12', () {
      expect(() => Periodo(2026, 0), throwsArgumentError);
      expect(() => Periodo(2026, 13), throwsArgumentError);
    });

    test('se construye desde una fecha ignorando el día', () {
      expect(Periodo.deFecha(DateTime(2026, 8, 20)), Periodo(2026, 8));
    });

    test('siguiente y anterior cruzan el año', () {
      expect(Periodo(2026, 12).siguiente(), Periodo(2027, 1));
      expect(Periodo(2026, 1).anterior(), Periodo(2025, 12));
    });

    test('mesesDesde cuenta en ambos sentidos', () {
      expect(Periodo(2027, 1).mesesDesde(Periodo(2026, 8)), 5);
      expect(Periodo(2026, 8).mesesDesde(Periodo(2027, 1)), -5);
      expect(Periodo(2026, 8).mesesDesde(Periodo(2026, 8)), 0);
    });

    test('se ordena cronológicamente', () {
      final periodos = [Periodo(2027, 1), Periodo(2026, 8), Periodo(2026, 12)]
        ..sort();
      expect(periodos, [Periodo(2026, 8), Periodo(2026, 12), Periodo(2027, 1)]);
    });

    test('se muestra como anio-mes', () {
      expect(Periodo(2026, 8).toString(), '2026-08');
      expect(Periodo(2026, 11).toString(), '2026-11');
    });
  });
}
