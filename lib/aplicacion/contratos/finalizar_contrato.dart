import '../../dominio/entidades/contrato.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_cuotas.dart';
import '../puertos/repositorio_de_pagos.dart';
import 'actualizar_cuotas_de_contrato.dart';

/// Finaliza un contrato conservando su historial (reglas 3 y 12).
///
/// Antes de decidir qué cuotas se conservan hay que **materializar** las que
/// corresponden hasta la fecha de fin: si nadie ejecutó la puesta al día, las
/// cuotas vencidas e impagas de los meses intermedios no existen todavía, y
/// aplicar la regla 12 solo sobre lo guardado haría desaparecer esa deuda.
class FinalizarContrato {
  final RepositorioDeContratos _contratos;
  final RepositorioDeCuotas _cuotas;
  final RepositorioDePagos _pagos;
  final ActualizarCuotasDeContrato _actualizarCuotas;

  FinalizarContrato(
    this._contratos,
    this._cuotas,
    this._pagos,
    this._actualizarCuotas,
  );

  Future<Contrato> ejecutar({
    required String contratoId,
    required DateTime fechaFin,
  }) async {
    final contrato = await _contratos.obtenerPorId(contratoId);
    if (contrato == null) {
      throw ContratoNoEncontrado(contratoId);
    }

    // El dominio rechaza finalizar dos veces o con una fecha anterior al
    // inicio; esos errores se propagan tal cual.
    final finalizado = contrato.finalizar(fechaFin);
    await _contratos.guardar(finalizado);

    // Se materializa con el contrato ya guardado: al tener fechaFin, el
    // calendario genera exactamente hasta esa fecha y ni una cuota más.
    await _actualizarCuotas.ejecutar(contratoId: contratoId, hoy: fechaFin);

    // Aun así puede haber cuotas posteriores a fechaFin creadas por puestas al
    // día anteriores, que sí llegaban hasta el mes siguiente al actual.
    final cuotas = await _cuotas.deContrato(contratoId);
    final pagos = await _pagos.deCuotas(cuotas.map((cuota) => cuota.id));
    final aEliminar = [
      for (final cuota in cuotas)
        if (!cuota.debeConservarseAlFinalizar(fechaFin, pagos)) cuota.id,
    ];
    if (aEliminar.isNotEmpty) {
      await _cuotas.eliminar(aEliminar);
    }

    return finalizado;
  }
}
