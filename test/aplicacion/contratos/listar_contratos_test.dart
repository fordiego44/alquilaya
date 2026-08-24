import 'package:alquilaya/aplicacion/contratos/listar_contratos.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/repositorio_de_contratos_en_memoria.dart';

void main() {
  group('ListarContratos', () {
    final montoMensual = Dinero(35000);

    Contrato contrato(
      String id,
      String habitacionId,
      String inquilinoId, {
      DateTime? fechaFin,
    }) => Contrato(
      id: id,
      habitacionId: habitacionId,
      inquilinoId: inquilinoId,
      fechaInicio: DateTime(2026, 8, 20),
      montoMensual: montoMensual,
      fechaFin: fechaFin,
    );

    late ListarContratos listar;

    setUp(() {
      listar = ListarContratos(
        RepositorioDeContratosEnMemoria([
          // h1 la ocupó Ana y ahora la ocupa Beto: dos contratos, uno cerrado.
          contrato('c1', 'h1', 'i1', fechaFin: DateTime(2026, 10, 15)),
          contrato('c2', 'h1', 'i2'),
          contrato('c3', 'h2', 'i1'),
        ]),
      );
    });

    test('sin filtros devuelve todos, activos y finalizados', () async {
      expect((await listar.ejecutar()).map((c) => c.id), ['c1', 'c2', 'c3']);
    });

    test('filtra por habitación', () async {
      final resultado = await listar.ejecutar(habitacionId: 'h1');

      expect(resultado.map((c) => c.id), ['c1', 'c2']);
    });

    test('filtra por inquilino', () async {
      final resultado = await listar.ejecutar(inquilinoId: 'i1');

      expect(resultado.map((c) => c.id), ['c1', 'c3']);
    });

    test('aplica ambos filtros a la vez', () async {
      final resultado = await listar.ejecutar(
        habitacionId: 'h1',
        inquilinoId: 'i1',
      );

      expect(resultado.map((c) => c.id), ['c1']);
    });

    test('devuelve vacío si nada coincide', () async {
      expect(await listar.ejecutar(habitacionId: 'h9'), isEmpty);
    });
  });
}
