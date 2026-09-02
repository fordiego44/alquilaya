import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/inquilinos/eliminar_inquilino.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';

void main() {
  group('EliminarInquilino', () {
    late RepositorioDeInquilinosEnMemoria inquilinos;
    late RepositorioDeContratosEnMemoria contratos;
    late EliminarInquilino eliminar;

    Contrato contrato({
      String id = 'c1',
      String inquilinoId = 'i1',
      DateTime? fechaFin,
    }) => Contrato(
      id: id,
      habitacionId: 'h1',
      inquilinoId: inquilinoId,
      fechaInicio: DateTime(2026, 8, 20),
      montoMensual: Dinero(35000),
      fechaFin: fechaFin,
    );

    setUp(() {
      inquilinos = RepositorioDeInquilinosEnMemoria([
        Inquilino(id: 'i1', nombre: 'Ana Torres'),
      ]);
      contratos = RepositorioDeContratosEnMemoria();
      eliminar = EliminarInquilino(inquilinos, contratos);
    });

    test('elimina un inquilino que nunca tuvo contratos', () async {
      await eliminar.ejecutar('i1');

      expect(await inquilinos.obtenerPorId('i1'), isNull);
      expect(await inquilinos.listar(), isEmpty);
    });

    test('un inquilino inexistente lanza InquilinoNoEncontrado', () async {
      await expectLater(
        eliminar.ejecutar('desconocido'),
        throwsA(isA<InquilinoNoEncontrado>()),
      );
      expect(await inquilinos.listar(), hasLength(1));
    });

    test('no elimina un inquilino con contrato activo', () async {
      await contratos.guardar(contrato());

      await expectLater(
        eliminar.ejecutar('i1'),
        throwsA(isA<InquilinoConContratos>()),
      );
      expect(await inquilinos.obtenerPorId('i1'), isNotNull);
    });

    test('tampoco lo elimina si el contrato ya está finalizado', () async {
      await contratos.guardar(contrato(fechaFin: DateTime(2026, 9, 30)));

      await expectLater(
        eliminar.ejecutar('i1'),
        throwsA(isA<InquilinoConContratos>()),
      );
      expect(await inquilinos.obtenerPorId('i1'), isNotNull);
    });

    test('un contrato de otro inquilino no impide eliminar', () async {
      await inquilinos.guardar(Inquilino(id: 'i2', nombre: 'Juan Pérez'));
      await contratos.guardar(contrato());

      await eliminar.ejecutar('i2');

      expect(await inquilinos.obtenerPorId('i2'), isNull);
      expect(await inquilinos.obtenerPorId('i1'), isNotNull);
    });
  });
}
