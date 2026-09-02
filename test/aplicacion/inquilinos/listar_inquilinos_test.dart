import 'package:alquilaya/aplicacion/inquilinos/listar_inquilinos.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';

void main() {
  group('ListarInquilinos', () {
    test('devuelve todos los inquilinos', () async {
      final ana = Inquilino(id: 'i1', nombre: 'Ana Torres');
      final luis = Inquilino(id: 'i2', nombre: 'Luis Vega');
      final listar = ListarInquilinos(
        RepositorioDeInquilinosEnMemoria([ana, luis]),
      );

      final listado = await listar.ejecutar();

      // El puerto no promete ningún orden.
      expect(listado, hasLength(2));
      expect(listado, containsAll([ana, luis]));
    });

    test('sin inquilinos devuelve una lista vacía', () async {
      final listar = ListarInquilinos(RepositorioDeInquilinosEnMemoria());

      expect(await listar.ejecutar(), isEmpty);
    });

    test('por defecto excluye a los inquilinos archivados', () async {
      final listar = ListarInquilinos(
        RepositorioDeInquilinosEnMemoria([
          Inquilino(id: 'i1', nombre: 'Ana Torres'),
          Inquilino(id: 'i2', nombre: 'Luis Vega').archivar(),
        ]),
      );

      final listado = await listar.ejecutar();

      expect(listado.map((i) => i.id), ['i1']);
    });

    test('incluirArchivados devuelve activos y archivados', () async {
      final listar = ListarInquilinos(
        RepositorioDeInquilinosEnMemoria([
          Inquilino(id: 'i1', nombre: 'Ana Torres'),
          Inquilino(id: 'i2', nombre: 'Luis Vega').archivar(),
        ]),
      );

      final listado = await listar.ejecutar(incluirArchivados: true);

      expect(listado.map((i) => i.id).toSet(), {'i1', 'i2'});
      // El estado viaja en la entidad; el listado no lo reinterpreta.
      expect(listado.singleWhere((i) => i.id == 'i2').archivado, isTrue);
    });

    test('si todos están archivados el listado por defecto queda vacío', () async {
      final listar = ListarInquilinos(
        RepositorioDeInquilinosEnMemoria([
          Inquilino(id: 'i1', nombre: 'Ana Torres').archivar(),
        ]),
      );

      expect(await listar.ejecutar(), isEmpty);
    });

    // Listar es de solo lectura: filtrar no puede archivar ni borrar nada.
    test('filtrar no modifica el repositorio ni las entidades', () async {
      final repositorio = RepositorioDeInquilinosEnMemoria([
        Inquilino(id: 'i1', nombre: 'Ana Torres'),
        Inquilino(id: 'i2', nombre: 'Luis Vega').archivar(),
      ]);
      final listar = ListarInquilinos(repositorio);

      await listar.ejecutar();

      expect(await repositorio.listar(), hasLength(2));
      expect((await repositorio.obtenerPorId('i2'))!.archivado, isTrue);
      expect((await repositorio.obtenerPorId('i1'))!.archivado, isFalse);
    });
  });
}
