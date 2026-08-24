import '../../dominio/entidades/cuota.dart';
import '../puertos/repositorio_de_cuotas.dart';
import '../puertos/repositorio_de_pagos.dart';
import 'cuota_con_estado.dart';

/// Lista las cuotas de toda la cartera, con su estado derivado a fecha de
/// [hoy] y ordenadas por vencimiento.
///
/// Es de **solo lectura**: no genera cuotas ni las persiste. Poner al día la
/// serie es cosa de `ActualizarCuotasDeTodosLosContratos`; mezclarlo aquí haría
/// que una consulta escribiera.
///
/// Un único caso de uso cubre las tres consultas del MVP, que solo se
/// diferencian en el filtro: pendientes, vencidas y —con `EstadoCuota.pendiente`
/// y el orden por vencimiento— los próximos vencimientos, sin ventana temporal
/// ni límite fijo.
class ListarCuotas {
  final RepositorioDeCuotas _cuotas;
  final RepositorioDePagos _pagos;

  ListarCuotas(this._cuotas, this._pagos);

  /// [estado] nulo devuelve todas. El filtro se aplica **después** de derivar:
  /// el estado no está almacenado, así que no puede consultarse al almacén.
  Future<List<CuotaConEstado>> ejecutar({
    required DateTime hoy,
    EstadoCuota? estado,
  }) async {
    final cuotas = await _cuotas.todas();

    // Una sola lectura de pagos para toda la cartera, en vez de una por cuota.
    // Cada cuota se queda con los suyos: el dominio ignora los ajenos.
    final pagos = await _pagos.deCuotas(cuotas.map((cuota) => cuota.id));

    final derivadas = [
      for (final cuota in cuotas) CuotaConEstado.derivar(cuota, pagos, hoy),
    ];
    derivadas.sort(
      (a, b) => a.cuota.fechaVencimiento.compareTo(b.cuota.fechaVencimiento),
    );

    if (estado == null) return derivadas;
    return derivadas.where((cuota) => cuota.estado == estado).toList();
  }
}
