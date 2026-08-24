import '../../dominio/entidades/cuota.dart';
import '../puertos/repositorio_de_contratos.dart';
import 'actualizar_cuotas_de_contrato.dart';

/// Pone al día las cuotas de los contratos **activos**.
///
/// Compone [ActualizarCuotasDeContrato] en lugar de repetir su lógica: las
/// reglas de calendario viven en un solo sitio (regla 7).
///
/// Los contratos finalizados se ignoran por completo: `FinalizarContrato` ya
/// materializa durante el cierre las cuotas que les corresponden hasta su
/// fecha de fin. Una puesta al día global no tiene que reparar ni completar un
/// contrato que ya está cerrado.
class ActualizarCuotasDeTodosLosContratos {
  final RepositorioDeContratos _contratos;
  final ActualizarCuotasDeContrato _porContrato;

  ActualizarCuotasDeTodosLosContratos(this._contratos, this._porContrato);

  /// Devuelve **solo las cuotas creadas en esta ejecución**, agrupadas por
  /// contrato en el orden en que los devuelve el almacén. Una segunda ejecución
  /// con el mismo [hoy] devuelve una lista vacía.
  Future<List<Cuota>> ejecutar({required DateTime hoy}) async {
    final nuevas = <Cuota>[];
    for (final contrato in await _contratos.listar()) {
      if (!contrato.estaActivo) {
        continue;
      }

      nuevas.addAll(
        await _porContrato.ejecutar(contratoId: contrato.id, hoy: hoy),
      );
    }
    return nuevas;
  }
}
