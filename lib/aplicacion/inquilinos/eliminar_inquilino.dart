import '../excepciones.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Borra físicamente a un inquilino que nunca tuvo contratos.
///
/// Solo se elimina lo que no deja huella: basta **un** contrato, activo o
/// finalizado, para que el inquilino pertenezca al historial y el borrado deje
/// de ser una opción. Para ese caso está `ArchivarInquilino`.
///
/// La comprobación se hace aquí, no en la base: la clave foránea también lo
/// impediría, pero es la última barrera y solo sabe decir "constraint failed".
class EliminarInquilino {
  final RepositorioDeInquilinos _inquilinos;
  final RepositorioDeContratos _contratos;

  EliminarInquilino(this._inquilinos, this._contratos);

  Future<void> ejecutar(String inquilinoId) async {
    if (await _inquilinos.obtenerPorId(inquilinoId) == null) {
      throw InquilinoNoEncontrado(inquilinoId);
    }

    // Traer los contratos y filtrar en memoria, como en habitaciones: el puerto
    // no gana nada con una consulta que solo usaría este caso de uso.
    final contratos = await _contratos.listar();
    if (contratos.any((c) => c.inquilinoId == inquilinoId)) {
      throw InquilinoConContratos(inquilinoId);
    }

    await _inquilinos.eliminar(inquilinoId);
  }
}
