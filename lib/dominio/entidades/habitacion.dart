/// Espacio alquilable de la vivienda.
///
/// Su estado ocupada/disponible no se guarda ni se calcula aquí: es
/// consecuencia de que exista un contrato activo, y se deriva en la capa de
/// aplicación, que es quien puede consultar los contratos.
///
/// [archivada] sí es estado propio y persistente, no derivado: una habitación
/// archivada se conserva para que los contratos históricos sigan resolviendo su
/// nombre, pero deja de ofrecerse para contratos nuevos. Quién puede archivarla
/// —y quién no— lo decide la capa de aplicación, que es la que ve los
/// contratos.
class Habitacion {
  final String id;
  final String nombre;
  final bool archivada;

  Habitacion({required this.id, required this.nombre, this.archivada = false}) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'No puede estar vacío');
    }
    if (nombre.trim().isEmpty) {
      throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío');
    }
  }

  /// Devuelve una copia archivada. Como [Contrato.finalizar], no muta el
  /// original. Archivar lo ya archivado no es un error: devuelve una copia
  /// equivalente, de modo que quien lo llama no tiene que comprobar antes.
  Habitacion archivar() => Habitacion(id: id, nombre: nombre, archivada: true);

  /// Devuelve una copia activa. Reactivar no tiene condiciones: una habitación
  /// archivada siempre puede volver.
  Habitacion reactivar() =>
      Habitacion(id: id, nombre: nombre, archivada: false);

  @override
  bool operator ==(Object other) => other is Habitacion && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Habitacion($id, $nombre, archivada: $archivada)';
}
