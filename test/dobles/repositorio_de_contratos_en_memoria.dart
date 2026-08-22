import 'package:alquilaya/aplicacion/puertos/repositorio_de_contratos.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';

/// Implementación en memoria. La ocupación se **deriva** de los contratos
/// guardados, no de un conjunto fijado a mano: así crear o finalizar un
/// contrato cambia de verdad el estado de la habitación.
class RepositorioDeContratosEnMemoria implements RepositorioDeContratos {
  final Map<String, Contrato> _porId = {};

  RepositorioDeContratosEnMemoria([List<Contrato> iniciales = const []]) {
    for (final contrato in iniciales) {
      _porId[contrato.id] = contrato;
    }
  }

  @override
  Future<void> guardar(Contrato contrato) async {
    _porId[contrato.id] = contrato;
  }

  @override
  Future<Contrato?> obtenerPorId(String id) async => _porId[id];

  @override
  Future<Set<String>> habitacionesOcupadas() async => {
    for (final contrato in _porId.values)
      if (contrato.estaActivo) contrato.habitacionId,
  };

  @override
  Future<bool> tieneContratoActivo(String habitacionId) async => _porId.values
      .any((c) => c.estaActivo && c.habitacionId == habitacionId);

  /// Solo para los tests: el puerto no expone un listado completo porque
  /// ningún caso de uso lo necesita, pero comprobar que un fallo no dejó nada
  /// guardado sí lo requiere.
  Future<List<Contrato>> todos() async => _porId.values.toList();
}
