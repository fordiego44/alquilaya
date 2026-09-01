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

    test('un inquilino nuevo no está archivado', () {
      expect(Inquilino(id: 'i1', nombre: 'Ana').archivado, isFalse);
    });

    test('archivar devuelve una copia archivada sin tocar el original', () {
      final original = Inquilino(
        id: 'i1',
        nombre: 'Ana',
        documento: '12345678',
        telefono: '951234567',
      );

      final archivado = original.archivar();

      expect(original.archivado, isFalse);
      expect(archivado.archivado, isTrue);
      // El resto de los datos viaja intacto: archivar no edita.
      expect(archivado.nombre, 'Ana');
      expect(archivado.documento, '12345678');
      expect(archivado.telefono, '951234567');
    });

    test('reactivar devuelve una copia activa', () {
      final archivado = Inquilino(id: 'i1', nombre: 'Ana').archivar();
      expect(archivado.reactivar().archivado, isFalse);
    });

    test('archivar dos veces no falla y sigue archivado', () {
      expect(
        Inquilino(id: 'i1', nombre: 'Ana').archivar().archivar().archivado,
        isTrue,
      );
    });

    test('archivar no cambia la identidad', () {
      final original = Inquilino(id: 'i1', nombre: 'Ana');
      expect(original.archivar(), original);
    });
  });
}
