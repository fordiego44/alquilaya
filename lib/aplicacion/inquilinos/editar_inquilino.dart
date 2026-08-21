import '../../dominio/entidades/inquilino.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Cambia los datos de un inquilino existente.
///
/// Se reemplaza el inquilino entero: omitir `documento` o `telefono` los deja
/// en `null`, es decir, borra el dato. No es una actualización parcial.
class EditarInquilino {
  final RepositorioDeInquilinos _repositorio;

  EditarInquilino(this._repositorio);

  Future<Inquilino> ejecutar({
    required String id,
    required String nombre,
    String? documento,
    String? telefono,
  }) async {
    if (await _repositorio.obtenerPorId(id) == null) {
      throw InquilinoNoEncontrado(id);
    }
    final editado = Inquilino(
      id: id,
      nombre: nombre,
      documento: documento,
      telefono: telefono,
    );
    await _repositorio.guardar(editado);
    return editado;
  }
}
