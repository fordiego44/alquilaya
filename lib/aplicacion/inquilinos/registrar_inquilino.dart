import '../../dominio/entidades/inquilino.dart';
import '../puertos/generador_de_id.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Da de alta un inquilino.
///
/// `documento` y `telefono` son opcionales: `null` significa "no se conoce".
/// La validación la hace el constructor de [Inquilino].
class RegistrarInquilino {
  final RepositorioDeInquilinos _repositorio;
  final GeneradorDeId _generadorDeId;

  RegistrarInquilino(this._repositorio, this._generadorDeId);

  Future<Inquilino> ejecutar({
    required String nombre,
    String? documento,
    String? telefono,
  }) async {
    final inquilino = Inquilino(
      id: await _generadorDeId.nuevoId(),
      nombre: nombre,
      documento: documento,
      telefono: telefono,
    );
    await _repositorio.guardar(inquilino);
    return inquilino;
  }
}
