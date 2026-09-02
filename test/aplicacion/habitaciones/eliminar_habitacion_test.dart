import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/eliminar_habitacion.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_habitaciones_en_memoria.dart';

void main() {
  group('EliminarHabitacion', () {
    late RepositorioDeHabitacionesEnMemoria habitaciones;
    late RepositorioDeContratosEnMemoria contratos;
    late EliminarHabitacion eliminar;

    Contrato contrato({DateTime? fechaFin}) => Contrato(
      id: 'c1',
      habitacionId: 'h1',
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
      eliminar = EliminarHabitacion(habitaciones, contratos);
    });

    test('elimina una habitación que nunca tuvo contratos', () async {
      await eliminar.ejecutar('h1');

      expect(await habitaciones.obtenerPorId('h1'), isNull);
      expect(await habitaciones.listar(), isEmpty);
    });

    test('una habitación inexistente lanza HabitacionNoEncontrada', () async {
      await expectLater(
        eliminar.ejecutar('desconocida'),
        throwsA(isA<HabitacionNoEncontrada>()),
      );
      expect(await habitaciones.listar(), hasLength(1));
    });

    test('no elimina una habitación con contrato activo', () async {
      await contratos.guardar(contrato());

      await expectLater(
        eliminar.ejecutar('h1'),
        throwsA(isA<HabitacionConContratos>()),
      );
      expect(await habitaciones.obtenerPorId('h1'), isNotNull);
    });

    test('tampoco la elimina si el contrato ya está finalizado', () async {
      await contratos.guardar(contrato(fechaFin: DateTime(2026, 9, 30)));

      await expectLater(
        eliminar.ejecutar('h1'),
        throwsA(isA<HabitacionConContratos>()),
      );
      expect(await habitaciones.obtenerPorId('h1'), isNotNull);
    });

    test('un contrato de otra habitación no impide eliminar', () async {
      await habitaciones.guardar(Habitacion(id: 'h2', nombre: 'Habitación 2'));
      await contratos.guardar(contrato());

      await eliminar.ejecutar('h2');

      expect(await habitaciones.obtenerPorId('h2'), isNull);
      expect(await habitaciones.obtenerPorId('h1'), isNotNull);
    });
  });
}
