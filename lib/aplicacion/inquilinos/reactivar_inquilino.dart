import '../../dominio/entidades/inquilino.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Devuelve a un inquilino archivado a las opciones disponibles.
///
/// No consulta los contratos: reactivar no tiene condiciones. Un inquilino
/// archivado no puede tener un contrato activo —archivarlo lo impedía—, así que
/// no hay nada que comprobar. Es idempotente.
class ReactivarInquilino {
  final RepositorioDeInquilinos _inquilinos;

  ReactivarInquilino(this._inquilinos);

  Future<Inquilino> ejecutar(String inquilinoId) async {
    final inquilino = await _inquilinos.obtenerPorId(inquilinoId);
    if (inquilino == null) {
      throw InquilinoNoEncontrado(inquilinoId);
    }

    final reactivado = inquilino.reactivar();
    await _inquilinos.guardar(reactivado);
    return reactivado;
  }
}
