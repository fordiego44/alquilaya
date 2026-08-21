import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/inquilinos/obtener_inquilino.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';

void main() {
  group('ObtenerInquilino', () {
    final inquilino = Inquilino(id: 'i1', nombre: 'Ana Torres');
    final obtener = ObtenerInquilino(
      RepositorioDeInquilinosEnMemoria([inquilino]),
    );

    test('devuelve el inquilino existente', () async {
      expect(await obtener.ejecutar('i1'), inquilino);
    });

    test('un id desconocido lanza InquilinoNoEncontrado', () {
      expect(
        () => obtener.ejecutar('desconocido'),
        throwsA(isA<InquilinoNoEncontrado>()),
      );
    });
  });
}
