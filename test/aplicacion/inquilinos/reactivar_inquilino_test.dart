import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/inquilinos/reactivar_inquilino.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';

void main() {
  group('ReactivarInquilino', () {
    late RepositorioDeInquilinosEnMemoria inquilinos;
    late ReactivarInquilino reactivar;

    setUp(() {
      inquilinos = RepositorioDeInquilinosEnMemoria([
        Inquilino(
          id: 'i1',
          nombre: 'Ana Torres',
          documento: '12345678',
        ).archivar(),
      ]);
      // Sin repositorio de contratos: reactivar no los consulta.
      reactivar = ReactivarInquilino(inquilinos);
    });

    test('reactiva a un inquilino archivado', () async {
      final reactivado = await reactivar.ejecutar('i1');

      expect(reactivado.archivado, isFalse);
      expect((await inquilinos.obtenerPorId('i1'))!.archivado, isFalse);
    });

    test('reactivar a un inquilino que ya está activo no falla', () async {
      await inquilinos.guardar(Inquilino(id: 'i2', nombre: 'Juan Pérez'));

      await reactivar.ejecutar('i2');

      expect((await inquilinos.obtenerPorId('i2'))!.archivado, isFalse);
    });

    test('reactivar dos veces es idempotente y conserva los datos', () async {
      await reactivar.ejecutar('i1');
      await reactivar.ejecutar('i1');

      final guardado = (await inquilinos.obtenerPorId('i1'))!;
      expect(guardado.archivado, isFalse);
      expect(guardado.nombre, 'Ana Torres');
      expect(guardado.documento, '12345678');
      expect(await inquilinos.listar(), hasLength(1));
    });

    test('un inquilino inexistente lanza InquilinoNoEncontrado', () async {
      await expectLater(
        reactivar.ejecutar('desconocido'),
        throwsA(isA<InquilinoNoEncontrado>()),
      );
    });
  });
}
