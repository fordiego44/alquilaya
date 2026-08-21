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
