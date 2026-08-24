import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_todos_los_contratos.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/valores/dinero.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/generador_de_id_secuencial.dart';
import '../../dobles/repositorio_de_contratos_en_memoria.dart';
import '../../dobles/repositorio_de_cuotas_en_memoria.dart';

void main() {
  group('ActualizarCuotasDeTodosLosContratos', () {
    final montoMensual = Dinero(35000);

    late RepositorioDeContratosEnMemoria contratos;
    late RepositorioDeCuotasEnMemoria cuotas;
    late ActualizarCuotasDeTodosLosContratos actualizar;

    Contrato contrato(String id, String habitacionId, {DateTime? fechaFin}) =>
        Contrato(
          id: id,
          habitacionId: habitacionId,
          inquilinoId: 'i1',
          fechaInicio: DateTime(2026, 8, 20),
          montoMensual: montoMensual,
          fechaFin: fechaFin,
        );

    setUp(() {
      contratos = RepositorioDeContratosEnMemoria();
      cuotas = RepositorioDeCuotasEnMemoria();
      actualizar = ActualizarCuotasDeTodosLosContratos(
        contratos,
        ActualizarCuotasDeContrato(
          contratos,
          cuotas,
          GeneradorDeIdSecuencial('cu'),
        ),
      );
    });

    test('genera las cuotas de todos los contratos', () async {
      await contratos.guardar(contrato('c1', 'h1'));
      await contratos.guardar(contrato('c2', 'h2'));

      final nuevas = await actualizar.ejecutar(hoy: DateTime(2026, 9, 5));

      // Agosto, septiembre y octubre (un mes por delante) para cada contrato.
      expect(nuevas, hasLength(6));
      expect(await cuotas.deContrato('c1'), hasLength(3));
      expect(await cuotas.deContrato('c2'), hasLength(3));
    });

    test('una segunda ejecución con el mismo hoy no duplica', () async {
      await contratos.guardar(contrato('c1', 'h1'));
      await contratos.guardar(contrato('c2', 'h2'));
      await actualizar.ejecutar(hoy: DateTime(2026, 9, 5));

      final nuevas = await actualizar.ejecutar(hoy: DateTime(2026, 9, 5));

      expect(nuevas, isEmpty);
      expect(await cuotas.todas(), hasLength(6));
    });

    test('avanzar la fecha genera solo las cuotas que faltan', () async {
      await contratos.guardar(contrato('c1', 'h1'));
      await actualizar.ejecutar(hoy: DateTime(2026, 9, 5));

      final nuevas = await actualizar.ejecutar(hoy: DateTime(2026, 10, 5));

      expect(nuevas.map((c) => c.fechaVencimiento), [DateTime(2026, 11, 20)]);
    });

    test('un contrato finalizado se ignora por completo', () async {
      await contratos.guardar(contrato('c1', 'h1'));
      await contratos.guardar(
        contrato('c2', 'h2', fechaFin: DateTime(2026, 9, 30)),
      );

      final nuevas = await actualizar.ejecutar(hoy: DateTime(2026, 11, 5));

      // Ni una sola cuota para el finalizado: no basta con que no genere más
      // allá de su fecha de fin, es que no participa en esta actualización.
      // Materializar lo suyo fue cosa de FinalizarContrato durante el cierre.
      expect(await cuotas.deContrato('c2'), isEmpty);
      expect(nuevas.map((c) => c.contratoId), everyElement('c1'));
      expect(await cuotas.deContrato('c1'), hasLength(5));
    });

    test('sin contratos activos no genera nada', () async {
      await contratos.guardar(
        contrato('c1', 'h1', fechaFin: DateTime(2026, 9, 30)),
      );

      expect(await actualizar.ejecutar(hoy: DateTime(2026, 11, 5)), isEmpty);
      expect(await cuotas.todas(), isEmpty);
    });

    test('sin contratos no genera nada', () async {
      expect(await actualizar.ejecutar(hoy: DateTime(2026, 9, 5)), isEmpty);
      expect(await cuotas.todas(), isEmpty);
    });
  });
}
