import '../../dominio/entidades/pago.dart';
import '../../dominio/valores/dinero.dart';
import '../excepciones.dart';
import '../puertos/generador_de_id.dart';
import '../puertos/repositorio_de_cuotas.dart';
import '../puertos/repositorio_de_pagos.dart';

/// Registra el pago de una cuota.
///
/// El monto llega desde fuera y no se deduce del pendiente: es la confirmación
/// de lo que el usuario vio en pantalla, y `Cuota.validarPago` es quien decide
/// si coincide (reglas 10 y 11). Aquí no se comprueba nada de eso.
///
/// Tampoco se exige que el contrato siga activo: la regla 12 conserva la deuda
/// vencida al finalizar, luego esa deuda tiene que poder saldarse después.
class RegistrarPago {
  final RepositorioDeCuotas _cuotas;
  final RepositorioDePagos _pagos;
  final GeneradorDeId _generadorDeId;

  RegistrarPago(this._cuotas, this._pagos, this._generadorDeId);

  Future<Pago> ejecutar({
    required String cuotaId,
    required Dinero monto,
    required DateTime fechaPago,
  }) async {
    final cuota = await _cuotas.obtenerPorId(cuotaId);
    if (cuota == null) {
      throw CuotaNoEncontrada(cuotaId);
    }

    final pagosPrevios = await _pagos.deCuotas([cuotaId]);
    final pago = Pago(
      id: await _generadorDeId.nuevoId(),
      cuotaId: cuotaId,
      monto: monto,
      fechaPago: fechaPago,
    );

    // El dominio rechaza el pago parcial, el sobrepago y la cuota ya pagada;
    // esos errores se propagan tal cual, antes de guardar nada.
    cuota.validarPago(pago, pagosPrevios);

    await _pagos.guardar(pago);
    return pago;
  }
}
