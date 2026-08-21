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
  });
}
