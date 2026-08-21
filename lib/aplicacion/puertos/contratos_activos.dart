/// Consulta de solo lectura sobre qué habitaciones tienen un contrato activo.
///
/// No es un repositorio de contratos: esta fase nunca necesita leer ni guardar
/// un `Contrato` completo, solo responder si existe uno activo. El puerto está
/// segregado por lo que su consumidor necesita.
///
/// Aquí vive la mitad *de lectura* de la regla 1 de PROJECT.md: una habitación
/// está ocupada si y solo si tiene un contrato activo. La mitad *de escritura*
/// —impedir un segundo contrato activo— corresponde a `CrearContrato`, que
/// reutilizará [tieneContratoActivo] cuando exista.
abstract interface class ContratosActivos {
  /// Ids de las habitaciones ocupadas. Existe para resolver un listado
  /// completo con una sola consulta en lugar de una por habitación.
  Future<Set<String>> habitacionesOcupadas();

  /// Evita traerse todo el conjunto para responder por una sola habitación.
  Future<bool> tieneContratoActivo(String habitacionId);
}
