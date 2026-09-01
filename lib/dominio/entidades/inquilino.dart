/// Persona que alquila una habitación.
///
/// `documento` y `telefono` son opcionales: `null` —y solo `null`— significa
/// que el dato no se conoce. Si se proporcionan, deben tener contenido. No se
/// validan formatos porque el negocio aún no los ha definido.
///
/// [archivado] es estado propio y persistente: un inquilino archivado se
/// conserva —los contratos históricos siguen resolviendo su nombre— pero deja
/// de ofrecerse para contratos nuevos.
class Inquilino {
  final String id;
  final String nombre;
  final String? documento;
  final String? telefono;
  final bool archivado;

  Inquilino({
    required this.id,
    required this.nombre,
    this.documento,
    this.telefono,
    this.archivado = false,
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

  /// Devuelve una copia archivada, sin mutar el original. Archivar lo ya
  /// archivado devuelve una copia equivalente en lugar de fallar.
  Inquilino archivar() => _con(archivado: true);

  /// Devuelve una copia activa. Reactivar no tiene condiciones.
  Inquilino reactivar() => _con(archivado: false);

  /// Copia con el mismo id y los mismos datos, cambiando solo el archivado.
  /// Existe para no repetir los cuatro campos en cada uno de los dos métodos.
  Inquilino _con({required bool archivado}) => Inquilino(
    id: id,
    nombre: nombre,
    documento: documento,
    telefono: telefono,
    archivado: archivado,
  );

  @override
  bool operator ==(Object other) => other is Inquilino && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Inquilino($id, $nombre, archivado: $archivado)';
}
