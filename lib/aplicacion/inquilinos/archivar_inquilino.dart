import '../../dominio/entidades/inquilino.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Retira a un inquilino de las opciones para contratos nuevos, conservándolo.
///
/// Se puede archivar a quien nunca tuvo contrato y a quien ya los cerró todos.
/// Lo único que lo impide es un **contrato activo**: archivar a alguien que
/// sigue viviendo en la vivienda la describiría en falso.
///
/// Es idempotente: archivar a quien ya está archivado vuelve a guardar el mismo
/// estado.
class ArchivarInquilino {
  final RepositorioDeInquilinos _inquilinos;
  final RepositorioDeContratos _contratos;

  ArchivarInquilino(this._inquilinos, this._contratos);

  Future<Inquilino> ejecutar(String inquilinoId) async {
    final inquilino = await _inquilinos.obtenerPorId(inquilinoId);
    if (inquilino == null) {
      throw InquilinoNoEncontrado(inquilinoId);
    }

    final contratos = await _contratos.listar();
    if (contratos.any((c) => c.inquilinoId == inquilinoId && c.estaActivo)) {
      throw InquilinoConContratoActivo(inquilinoId);
    }

    final archivado = inquilino.archivar();
    await _inquilinos.guardar(archivado);
    return archivado;
  }
}
