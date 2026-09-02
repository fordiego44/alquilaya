import 'package:alquilaya/aplicacion/excepciones.dart';
import 'package:alquilaya/aplicacion/inquilinos/archivar_inquilino.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_inquilinos_en_memoria.dart';

void main() {
  group('ArchivarInquilino', () {
    late RepositorioDeInquilinosEnMemoria inquilinos;
    late RepositorioDeContratosEnMemoria contratos;
    late ArchivarInquilino archivar;

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
        Inquilino(
          id: 'i1',
          nombre: 'Ana Torres',
          documento: '12345678',
          telefono: '951234567',
        ),
      ]);
      contratos = RepositorioDeContratosEnMemoria();
      archivar = ArchivarInquilino(inquilinos, contratos);
    });

    test('archiva a un inquilino que nunca tuvo contratos', () async {
      final archivado = await archivar.ejecutar('i1');

      expect(archivado.archivado, isTrue);
      expect((await inquilinos.obtenerPorId('i1'))!.archivado, isTrue);
    });

    test('archiva a un inquilino con solo contratos finalizados', () async {
      await contratos.guardar(contrato(fechaFin: DateTime(2026, 9, 30)));

      await archivar.ejecutar('i1');

      expect((await inquilinos.obtenerPorId('i1'))!.archivado, isTrue);
    });

    test('rechaza archivar si tiene un contrato activo', () async {
      await contratos.guardar(contrato());

      await expectLater(
        archivar.ejecutar('i1'),
        throwsA(isA<InquilinoConContratoActivo>()),
      );
      // Al fallar, el inquilino queda exactamente como estaba.
      expect((await inquilinos.obtenerPorId('i1'))!.archivado, isFalse);
    });

    test('un contrato activo de otro inquilino no lo impide', () async {
      await inquilinos.guardar(Inquilino(id: 'i2', nombre: 'Juan Pérez'));
      await contratos.guardar(contrato(inquilinoId: 'i2'));

      await archivar.ejecutar('i1');

      expect((await inquilinos.obtenerPorId('i1'))!.archivado, isTrue);
      expect((await inquilinos.obtenerPorId('i2'))!.archivado, isFalse);
    });

    test('un inquilino inexistente lanza InquilinoNoEncontrado', () async {
      await expectLater(
        archivar.ejecutar('desconocido'),
        throwsA(isA<InquilinoNoEncontrado>()),
      );
    });

    test('archivar dos veces no falla y conserva los datos', () async {
      await archivar.ejecutar('i1');
      await archivar.ejecutar('i1');

      final guardado = (await inquilinos.obtenerPorId('i1'))!;
      expect(guardado.archivado, isTrue);
      expect(guardado.nombre, 'Ana Torres');
      expect(guardado.documento, '12345678');
      expect(guardado.telefono, '951234567');
      expect(await inquilinos.listar(), hasLength(1));
    });
  });
}
