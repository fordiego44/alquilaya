// Errores de la capa de aplicación.
//
// "No existe en el almacén" no es una regla de negocio, sino una condición de
// orquestación: por eso viven aquí y no en el dominio.

/// La habitación pedida no existe en el almacén.
class HabitacionNoEncontrada implements Exception {
  final String id;

  HabitacionNoEncontrada(this.id);

  @override
  String toString() => 'No existe la habitación $id';
}

/// El inquilino pedido no existe en el almacén.
class InquilinoNoEncontrado implements Exception {
  final String id;

  InquilinoNoEncontrado(this.id);

  @override
  String toString() => 'No existe el inquilino $id';
}

/// El contrato pedido no existe en el almacén.
class ContratoNoEncontrado implements Exception {
  final String id;

  ContratoNoEncontrado(this.id);

  @override
  String toString() => 'No existe el contrato $id';
}

/// La cuota pedida no existe en el almacén.
class CuotaNoEncontrada implements Exception {
  final String id;

  CuotaNoEncontrada(this.id);

  @override
  String toString() => 'No existe la cuota $id';
}

/// Los datos guardados se contradicen: algo apunta a algo que no existe.
///
/// No es lo mismo que las excepciones de "no encontrado" de arriba. Aquellas
/// responden a que alguien pidió algo que no está —una situación normal—;
/// esta significa que un invariante se ha roto, algo que las claves foráneas
/// deberían impedir. Por eso no se reutilizan: dan un mensaje tranquilizador a
/// un problema que no lo es.
///
/// Quien la lanza aborta la operación entera. Devolver un resultado parcial, o
/// rellenar los huecos con textos como "desconocido", escondería el problema en
/// una pantalla que parecería correcta.
class ReferenciaInconsistente implements Exception {
  final String detalle;

  ReferenciaInconsistente(this.detalle);

  @override
  String toString() => 'Inconsistencia en los datos: $detalle';
}

/// Se intentó finalizar un contrato en una fecha que todavía no ha llegado.
///
/// Finalizar significa que la salida **ya ocurrió**: la fecha de fin puede ser
/// hoy o una fecha pasada, nunca futura. Programar una salida por adelantado no
/// forma parte del alcance actual.
///
/// Vive aquí y no en el dominio por lo mismo que [HabitacionOcupada]: solo es
/// comprobable con un dato externo —qué día es hoy— que `Contrato` no conoce.
class FechaDeFinFutura implements Exception {
  final DateTime fechaFin;
  final DateTime hoy;

  FechaDeFinFutura(this.fechaFin, this.hoy);

  @override
  String toString() =>
      'La fecha de fin $fechaFin es posterior a hoy ($hoy): un contrato no '
      'puede finalizarse en el futuro';
}

/// Regla 1: la habitación ya tiene un contrato activo.
///
/// La regla es de negocio, pero solo es comprobable consultando el almacén, y
/// eso es orquestación: por eso la excepción vive aquí y no en el dominio.
class HabitacionOcupada implements Exception {
  final String habitacionId;

  HabitacionOcupada(this.habitacionId);

  @override
  String toString() =>
      'La habitación $habitacionId ya tiene un contrato activo';
}
