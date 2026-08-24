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
