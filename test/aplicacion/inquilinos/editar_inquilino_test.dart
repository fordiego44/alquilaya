import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/inquilinos/editar_inquilino.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';

void main() {
  group('EditarInquilino', () {
    late RepositorioDeInquilinosEnMemoria repositorio;
    late EditarInquilino editar;

    setUp(() {
      repositorio = RepositorioDeInquilinosEnMemoria([
        Inquilino(
          id: 'i1',
          nombre: 'Ana Torres',
          documento: '12345678',
          telefono: '999888777',
        ),
      ]);
      editar = EditarInquilino(repositorio);
    });

    test('cambia los datos conservando el id', () async {
      final editado = await editar.ejecutar(
        id: 'i1',
        nombre: 'Ana María Torres',
        documento: '87654321',
        telefono: '999888777',
      );

      expect(editado.id, 'i1');
      final guardado = (await repositorio.obtenerPorId('i1'))!;
      expect(guardado.nombre, 'Ana María Torres');
      expect(guardado.documento, '87654321');
    });

    test('omitir un dato opcional lo borra: la edición reemplaza el inquilino',
        () async {
      await editar.ejecutar(id: 'i1', nombre: 'Ana Torres');

      final guardado = (await repositorio.obtenerPorId('i1'))!;
      expect(guardado.documento, isNull);
      expect(guardado.telefono, isNull);
    });

    test('un inquilino inexistente lanza InquilinoNoEncontrado', () async {
      expect(
        () => editar.ejecutar(id: 'desconocido', nombre: 'Ana'),
        throwsA(isA<InquilinoNoEncontrado>()),
      );
      expect(await repositorio.listar(), hasLength(1));
    });

    test('un dato inválido deja intacto el valor anterior', () async {
      expect(
        () => editar.ejecutar(id: 'i1', nombre: 'Ana', documento: ''),
        throwsArgumentError,
      );
      expect((await repositorio.obtenerPorId('i1'))!.documento, '12345678');
    });
  });
}
