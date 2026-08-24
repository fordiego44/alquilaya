import '../../dominio/entidades/contrato.dart';
import '../puertos/repositorio_de_contratos.dart';

/// Lista los contratos, opcionalmente filtrados por habitación y/o inquilino.
///
/// Devuelve las entidades tal cual: no hay ningún dato derivado que justifique
/// envolverlas. Activo o finalizado ya se lee en `Contrato.estaActivo`.
///
/// Los filtros se resuelven en memoria sobre `listar()` en lugar de añadir
/// consultas al puerto: para una vivienda es de sobra, y no compromete al
/// adaptador futuro con búsquedas que nadie ha pedido.
class ListarContratos {
  final RepositorioDeContratos _contratos;

  ListarContratos(this._contratos);

  /// Los filtros nulos no filtran; si se pasan los dos, se aplican ambos.
  Future<List<Contrato>> ejecutar({
    String? habitacionId,
    String? inquilinoId,
  }) async {
    final contratos = await _contratos.listar();
    return contratos
        .where(
          (contrato) =>
              (habitacionId == null || contrato.habitacionId == habitacionId) &&
              (inquilinoId == null || contrato.inquilinoId == inquilinoId),
        )
        .toList();
  }
}
