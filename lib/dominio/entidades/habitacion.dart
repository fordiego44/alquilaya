/// Espacio alquilable de la vivienda.
///
/// Su estado ocupada/disponible no se guarda ni se calcula aquí: es
/// consecuencia de que exista un contrato activo, y se deriva en la capa de
/// aplicación, que es quien puede consultar los contratos.
class Habitacion {
  final String id;
  final String nombre;

  Habitacion({required this.id, required this.nombre}) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'No puede estar vacío');
    }
    if (nombre.trim().isEmpty) {
      throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío');
    }
  }

  @override
  bool operator ==(Object other) => other is Habitacion && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Habitacion($id, $nombre)';
}
