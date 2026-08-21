import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dinero', () {
    test('rechaza importes negativos', () {
      expect(() => Dinero(-1), throwsArgumentError);
    });

    test('admite cero, que es el pendiente de una cuota saldada', () {
      expect(Dinero(0), Dinero.cero);
      expect(Dinero.cero.esPositivo, isFalse);
      expect(Dinero(1).esPositivo, isTrue);
    });

    test('suma y resta en centavos exactos', () {
      expect(Dinero(35050) + Dinero(35050), Dinero(70100));
      expect(Dinero(35050) - Dinero(50), Dinero(35000));
    });

    test('una resta que quedaría negativa lanza', () {
      expect(() => Dinero(100) - Dinero(101), throwsArgumentError);
    });

    test('la igualdad es por valor', () {
      expect(Dinero(35050), Dinero(35050));
      expect(Dinero(35050).hashCode, Dinero(35050).hashCode);
      expect(Dinero(35050), isNot(Dinero(35051)));
    });

    test('se ordena por importe', () {
      final importes = [Dinero(300), Dinero(100), Dinero(200)]..sort();
      expect(importes, [Dinero(100), Dinero(200), Dinero(300)]);
      expect(Dinero(100) < Dinero(200), isTrue);
      expect(Dinero(200) >= Dinero(200), isTrue);
    });

    test('se muestra con dos decimales', () {
      expect(Dinero(35050).toString(), 'S/ 350.50');
      expect(Dinero(35005).toString(), 'S/ 350.05');
      expect(Dinero.cero.toString(), 'S/ 0.00');
    });
  });
}
