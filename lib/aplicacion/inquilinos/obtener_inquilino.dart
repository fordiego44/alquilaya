import '../../dominio/entidades/inquilino.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Recupera un inquilino por su id.
class ObtenerInquilino {
  final RepositorioDeInquilinos _repositorio;

  ObtenerInquilino(this._repositorio);

  Future<Inquilino> ejecutar(String id) async {
    final inquilino = await _repositorio.obtenerPorId(id);
    if (inquilino == null) {
      throw InquilinoNoEncontrado(id);
    }
    return inquilino;
  }
}
