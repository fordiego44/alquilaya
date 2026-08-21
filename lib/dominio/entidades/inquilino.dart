/// Persona que alquila una habitación.
///
/// `documento` y `telefono` son opcionales: `null` —y solo `null`— significa
/// que el dato no se conoce. Si se proporcionan, deben tener contenido. No se
/// validan formatos porque el negocio aún no los ha definido.
class Inquilino {
  final String id;
  final String nombre;
  final String? documento;
  final String? telefono;

  Inquilino({
    required this.id,
    required this.nombre,
    this.documento,
    this.telefono,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'No puede estar vacío');
    }
    if (nombre.trim().isEmpty) {
      throw ArgumentError.value(nombre, 'nombre', 'No puede estar vacío');
    }
    _validarOpcional(documento, 'documento');
    _validarOpcional(telefono, 'telefono');
  }

  /// Un dato ausente se representa con `null`, nunca con una cadena vacía o en
  /// blanco: dos representaciones para lo mismo obligarían a comprobar ambas en
  /// todas partes.
  static void _validarOpcional(String? valor, String nombreDelCampo) {
    if (valor != null && valor.trim().isEmpty) {
      throw ArgumentError.value(
        valor,
        nombreDelCampo,
        'Si se proporciona no puede estar vacío; usa null si no se conoce',
      );
    }
  }

  @override
  bool operator ==(Object other) => other is Inquilino && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Inquilino($id, $nombre)';
}
