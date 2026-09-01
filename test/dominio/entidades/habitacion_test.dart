import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Habitacion', () {
    test('rechaza id o nombre vacíos', () {
      expect(
        () => Habitacion(id: '', nombre: 'Habitación 1'),
        throwsArgumentError,
      );
      expect(() => Habitacion(id: 'h1', nombre: '   '), throwsArgumentError);
    });

    test('la igualdad es por id', () {
      expect(
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
        Habitacion(id: 'h1', nombre: 'Otro nombre'),
      );
      expect(
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
        isNot(Habitacion(id: 'h2', nombre: 'Habitación 1')),
      );
    });

    test('una habitación nueva no está archivada', () {
      expect(Habitacion(id: 'h1', nombre: 'Habitación 1').archivada, isFalse);
    });

    test('archivar devuelve una copia archivada sin tocar el original', () {
      final original = Habitacion(id: 'h1', nombre: 'Habitación 1');

      final archivada = original.archivar();

      expect(original.archivada, isFalse);
      expect(archivada.archivada, isTrue);
      expect(archivada.nombre, 'Habitación 1');
    });

    test('reactivar devuelve una copia activa', () {
      final archivada = Habitacion(id: 'h1', nombre: 'Habitación 1').archivar();
      expect(archivada.reactivar().archivada, isFalse);
    });

    test('archivar dos veces no falla y sigue archivada', () {
      expect(
        Habitacion(id: 'h1', nombre: 'H1').archivar().archivar().archivada,
        isTrue,
      );
    });

    test('archivar no cambia la identidad', () {
      final original = Habitacion(id: 'h1', nombre: 'Habitación 1');
      expect(original.archivar(), original);
    });
  });
}
