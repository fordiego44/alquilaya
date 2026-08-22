import '../../dominio/calendario_de_pagos.dart';
import '../../dominio/entidades/cuota.dart';
import '../excepciones.dart';
import '../puertos/generador_de_id.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_cuotas.dart';

/// Pone al día las cuotas de un contrato: genera las que faltan desde el mes de
/// inicio hasta el mes de [hoy] más uno, sin duplicar las que ya existen.
///
/// Cuántas cuotas corresponden lo decide `CalendarioDePagos.cuotasHasta`, que
/// además acota por la fecha de fin si el contrato está finalizado. Aquí no se
/// hace aritmética de fechas (regla 7).
class ActualizarCuotasDeContrato {
  final RepositorioDeContratos _contratos;
  final RepositorioDeCuotas _cuotas;
  final GeneradorDeId _generadorDeId;

  ActualizarCuotasDeContrato(
    this._contratos,
    this._cuotas,
    this._generadorDeId,
  );

  /// Devuelve **solo las cuotas creadas en esta ejecución**, ordenadas por
  /// vencimiento. Una segunda ejecución con el mismo [hoy] devuelve una lista
  /// vacía.
  Future<List<Cuota>> ejecutar({
    required String contratoId,
    required DateTime hoy,
  }) async {
    final contrato = await _contratos.obtenerPorId(contratoId);
    if (contrato == null) {
      throw ContratoNoEncontrado(contratoId);
    }

    // La identidad de una cuota dentro de su contrato es su período: es lo que
    // permite reconocer las que ya existen sin depender del vencimiento, que
    // se ajusta a fin de mes.
    final periodosExistentes = {
      for (final cuota in await _cuotas.deContrato(contratoId)) cuota.periodo,
    };

    final cantidad = CalendarioDePagos.cuotasHasta(
      fechaInicio: contrato.fechaInicio,
      hoy: hoy,
      fechaFin: contrato.fechaFin,
    );

    final nuevas = <Cuota>[];
    for (var indice = 0; indice < cantidad; indice++) {
      final periodo = CalendarioDePagos.periodoDeCuota(
        contrato.fechaInicio,
        indice,
      );
      if (periodosExistentes.contains(periodo)) continue;
      nuevas.add(
        Cuota(
          id: await _generadorDeId.nuevoId(),
          contratoId: contrato.id,
          periodo: periodo,
          monto: contrato.montoMensual,
          fechaVencimiento: CalendarioDePagos.vencimientoDeCuota(
            contrato.fechaInicio,
            indice,
          ),
        ),
      );
    }

    if (nuevas.isNotEmpty) {
      await _cuotas.guardarTodas(nuevas);
    }
    return nuevas;
  }
}
