import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/archivar_habitacion.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('ArchivarHabitacion', () {
    late RepositorioDeHabitacionesEnMemoria habitaciones;
    late RepositorioDeContratosEnMemoria contratos;
    late ArchivarHabitacion archivar;

    Contrato contrato({
      String id = 'c1',
      String habitacionId = 'h1',
      DateTime? fechaFin,
    }) => Contrato(
      id: id,
      habitacionId: habitacionId,
      inquilinoId: 'i1',
      fechaInicio: DateTime(2026, 8, 20),
      montoMensual: Dinero(35000),
      fechaFin: fechaFin,
    );

    setUp(() {
      habitaciones = RepositorioDeHabitacionesEnMemoria([
        Habitacion(id: 'h1', nombre: 'Habitación 1'),
      ]);
      contratos = RepositorioDeContratosEnMemoria();
      archivar = ArchivarHabitacion(habitaciones, contratos);
    });

    test('archiva una habitación que nunca tuvo contratos', () async {
      final archivada = await archivar.ejecutar('h1');

      expect(archivada.archivada, isTrue);
      expect((await habitaciones.obtenerPorId('h1'))!.archivada, isTrue);
    });

    test('archiva una habitación con solo contratos finalizados', () async {
      await contratos.guardar(contrato(fechaFin: DateTime(2026, 9, 30)));

      await archivar.ejecutar('h1');

      expect((await habitaciones.obtenerPorId('h1'))!.archivada, isTrue);
    });

    test('rechaza archivar si tiene un contrato activo', () async {
      await contratos.guardar(contrato());

      await expectLater(
        archivar.ejecutar('h1'),
        throwsA(isA<HabitacionConContratoActivo>()),
      );
      // Al fallar, la habitación queda exactamente como estaba.
      expect((await habitaciones.obtenerPorId('h1'))!.archivada, isFalse);
    });

    test('un contrato activo de otra habitación no lo impide', () async {
      await habitaciones.guardar(Habitacion(id: 'h2', nombre: 'Habitación 2'));
      await contratos.guardar(contrato(habitacionId: 'h2'));

      await archivar.ejecutar('h1');

      expect((await habitaciones.obtenerPorId('h1'))!.archivada, isTrue);
      expect((await habitaciones.obtenerPorId('h2'))!.archivada, isFalse);
    });

    test('una habitación inexistente lanza HabitacionNoEncontrada', () async {
      await expectLater(
        archivar.ejecutar('desconocida'),
        throwsA(isA<HabitacionNoEncontrada>()),
      );
    });

    test('archivar dos veces no falla y conserva el nombre', () async {
      await archivar.ejecutar('h1');
      await archivar.ejecutar('h1');

      final guardada = (await habitaciones.obtenerPorId('h1'))!;
      expect(guardada.archivada, isTrue);
      expect(guardada.nombre, 'Habitación 1');
      expect(await habitaciones.listar(), hasLength(1));
    });
  });
}
