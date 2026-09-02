import '../../dominio/entidades/inquilino.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Cambia los datos de un inquilino existente.
///
/// Se reemplaza el inquilino entero: omitir `documento` o `telefono` los deja
/// en `null`, es decir, borra el dato. No es una actualización parcial.
///
/// El **archivado** es la excepción a esa regla, y no por capricho: no es un
/// dato que este formulario edite, sino el estado del inquilino en la
/// aplicación. Renombrar a alguien archivado no puede devolverlo a las
/// opciones de contrato sin que nadie lo haya pedido.
class EditarInquilino {
  final RepositorioDeInquilinos _repositorio;

  EditarInquilino(this._repositorio);

  Future<Inquilino> ejecutar({
    required String id,
    required String nombre,
    String? documento,
    String? telefono,
  }) async {
    final actual = await _repositorio.obtenerPorId(id);
    if (actual == null) {
      throw InquilinoNoEncontrado(id);
    }
    final editado = Inquilino(
      id: id,
      nombre: nombre,
      documento: documento,
      telefono: telefono,
      archivado: actual.archivado,
    );
    await _repositorio.guardar(editado);
    return editado;
  }
}
