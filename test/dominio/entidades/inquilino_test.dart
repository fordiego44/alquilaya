import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Inquilino', () {
    test('basta con id y nombre; documento y telefono quedan en null', () {
      final inquilino = Inquilino(id: 'i1', nombre: 'Ana Torres');
      expect(inquilino.documento, isNull);
      expect(inquilino.telefono, isNull);
    });

    test('rechaza id o nombre vacíos', () {
      expect(() => Inquilino(id: '', nombre: 'Ana'), throwsArgumentError);
      expect(() => Inquilino(id: 'i1', nombre: '   '), throwsArgumentError);
    });

    test('un dato opcional presente no puede venir en blanco', () {
      expect(
        () => Inquilino(id: 'i1', nombre: 'Ana', documento: ''),
        throwsArgumentError,
      );
      expect(
        () => Inquilino(id: 'i1', nombre: 'Ana', telefono: '  '),
        throwsArgumentError,
      );
    });

    test('la igualdad es por id', () {
      expect(
        Inquilino(id: 'i1', nombre: 'Ana'),
        Inquilino(id: 'i1', nombre: 'Ana María', documento: '12345678'),
      );
      expect(
        Inquilino(id: 'i1', nombre: 'Ana'),
        isNot(Inquilino(id: 'i2', nombre: 'Ana')),
      );
    });
  });
}
