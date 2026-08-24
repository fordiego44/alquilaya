import '../../dominio/entidades/contrato.dart';
import '../../dominio/entidades/pago.dart';
import '../cuotas/cuota_con_estado.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_cuotas.dart';
import '../puertos/repositorio_de_pagos.dart';

/// El historial completo de un contrato: la serie de cuotas con su estado y los
/// pagos que las saldaron.
///
/// Es un modelo de salida de la aplicación, no una entidad de dominio: agrupa
/// lo que una pantalla de historial necesita leer de una vez, y no se guarda.
class HistorialDeContrato {
  final Contrato contrato;

  /// Ordenadas por vencimiento, de la más antigua a la más reciente.
  final List<CuotaConEstado> cuotas;

  /// Los pagos de esas cuotas. Se conservan aunque el contrato esté finalizado:
  /// la regla 12 nunca elimina pagos.
  final List<Pago> pagos;

  const HistorialDeContrato(this.contrato, this.cuotas, this.pagos);

  @override
  String toString() =>
      'HistorialDeContrato(${contrato.id}, ${cuotas.length} cuotas, '
      '${pagos.length} pagos)';
}

/// Reconstruye el historial de un contrato. De **solo lectura**: no genera
/// cuotas que falten ni persiste nada.
///
/// Sirve igual para un contrato finalizado, que es justo cuando el historial
/// importa (regla 3).
class ConsultarHistorialDeContrato {
  final RepositorioDeContratos _contratos;
  final RepositorioDeCuotas _cuotas;
  final RepositorioDePagos _pagos;

  ConsultarHistorialDeContrato(this._contratos, this._cuotas, this._pagos);

  Future<HistorialDeContrato> ejecutar({
    required String contratoId,
    required DateTime hoy,
  }) async {
    final contrato = await _contratos.obtenerPorId(contratoId);
    if (contrato == null) {
      throw ContratoNoEncontrado(contratoId);
    }

    final cuotas = await _cuotas.deContrato(contratoId);

    // Los pagos hacen falta de todos modos para derivar el estado, así que
    // devolverlos no cuesta ninguna lectura extra.
    final pagos = await _pagos.deCuotas(cuotas.map((cuota) => cuota.id));

    final derivadas = [
      for (final cuota in cuotas) CuotaConEstado.derivar(cuota, pagos, hoy),
    ];
    derivadas.sort(
      (a, b) => a.cuota.fechaVencimiento.compareTo(b.cuota.fechaVencimiento),
    );

    return HistorialDeContrato(contrato, derivadas, pagos);
  }
}
