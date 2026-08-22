import '../../dominio/calendario_de_pagos.dart';
import '../../dominio/entidades/contrato.dart';
import '../../dominio/entidades/cuota.dart';
import '../../dominio/entidades/pago.dart';
import '../../dominio/valores/dinero.dart';
import '../excepciones.dart';
import '../puertos/generador_de_id.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_cuotas.dart';
import '../puertos/repositorio_de_habitaciones.dart';
import '../puertos/repositorio_de_inquilinos.dart';
import '../puertos/repositorio_de_pagos.dart';

/// Crea un contrato sobre una habitación disponible y registra el pago de su
/// primera cuota (regla 9).
///
/// Genera **solo** la primera cuota: la puesta al día del resto es de
/// `ActualizarCuotasDeContrato`.
class CrearContrato {
  final RepositorioDeContratos _contratos;
  final RepositorioDeCuotas _cuotas;
  final RepositorioDePagos _pagos;
  final RepositorioDeHabitaciones _habitaciones;
  final RepositorioDeInquilinos _inquilinos;
  final GeneradorDeId _generadorDeId;

  CrearContrato(
    this._contratos,
    this._cuotas,
    this._pagos,
    this._habitaciones,
    this._inquilinos,
    this._generadorDeId,
  );

  Future<Contrato> ejecutar({
    required String habitacionId,
    required String inquilinoId,
    required DateTime fechaInicio,
    required Dinero montoMensual,
  }) async {
    if (await _habitaciones.obtenerPorId(habitacionId) == null) {
      throw HabitacionNoEncontrada(habitacionId);
    }
    if (await _inquilinos.obtenerPorId(inquilinoId) == null) {
      throw InquilinoNoEncontrado(inquilinoId);
    }
    // Regla 1: una habitación no puede tener dos contratos activos.
    if (await _contratos.tieneContratoActivo(habitacionId)) {
      throw HabitacionOcupada(habitacionId);
    }

    final contrato = Contrato(
      id: await _generadorDeId.nuevoId(),
      habitacionId: habitacionId,
      inquilinoId: inquilinoId,
      fechaInicio: fechaInicio,
      montoMensual: montoMensual,
    );

    // Primera cuota: índice 0, vence el mismo día de inicio (reglas 8 y 9).
    final primeraCuota = Cuota(
      id: await _generadorDeId.nuevoId(),
      contratoId: contrato.id,
      periodo: CalendarioDePagos.periodoDeCuota(fechaInicio, 0),
      monto: montoMensual,
      fechaVencimiento: CalendarioDePagos.vencimientoDeCuota(fechaInicio, 0),
    );

    final pagoInicial = Pago(
      id: await _generadorDeId.nuevoId(),
      cuotaId: primeraCuota.id,
      monto: montoMensual,
      fechaPago: fechaInicio,
    );
    // Que el pago salda la cuota entera lo decide el dominio, no este caso de
    // uso: la cuota es nueva, así que no tiene pagos previos.
    primeraCuota.validarPago(pagoInicial, const []);

    // De menos a más dependiente: nada guardado apunta a lo que aún no existe.
    await _contratos.guardar(contrato);
    await _cuotas.guardarTodas([primeraCuota]);
    await _pagos.guardar(pagoInicial);

    return contrato;
  }
}
