import 'package:alquilaya/aplicacion/inquilinos/registrar_inquilino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/generador_de_id_secuencial.dart';
import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';

void main() {
  group('RegistrarInquilino', () {
    late RepositorioDeInquilinosEnMemoria repositorio;
    late RegistrarInquilino registrar;

    setUp(() {
      repositorio = RepositorioDeInquilinosEnMemoria();
      registrar = RegistrarInquilino(repositorio, GeneradorDeIdSecuencial('i'));
    });

    test('toma el id del generador y deja el inquilino recuperable', () async {
      final inquilino = await registrar.ejecutar(
        nombre: 'Ana Torres',
        documento: '12345678',
      );

      expect(inquilino.id, 'i1');
      expect(inquilino.documento, '12345678');
      expect(await repositorio.obtenerPorId('i1'), inquilino);
    });

    test('los datos opcionales pueden omitirse', () async {
      final inquilino = await registrar.ejecutar(nombre: 'Ana Torres');

      expect(inquilino.documento, isNull);
      expect(inquilino.telefono, isNull);
    });

    test('un nombre inválido propaga el error del dominio sin guardar nada',
        () async {
      expect(() => registrar.ejecutar(nombre: '  '), throwsArgumentError);
      expect(await repositorio.listar(), isEmpty);
    });
  });
}
