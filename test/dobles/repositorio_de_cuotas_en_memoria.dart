import 'package:alquilaya/aplicacion/puertos/repositorio_de_cuotas.dart';
import 'package:alquilaya/dominio/entidades/cuota.dart';

class RepositorioDeCuotasEnMemoria implements RepositorioDeCuotas {
  final Map<String, Cuota> _porId = {};

  RepositorioDeCuotasEnMemoria([List<Cuota> iniciales = const []]) {
    for (final cuota in iniciales) {
      _porId[cuota.id] = cuota;
    }
  }

  @override
  Future<void> guardarTodas(List<Cuota> cuotas) async {
    for (final cuota in cuotas) {
      _porId[cuota.id] = cuota;
    }
  }

  @override
  Future<List<Cuota>> deContrato(String contratoId) async =>
      _porId.values.where((cuota) => cuota.contratoId == contratoId).toList();

  @override
  Future<void> eliminar(Iterable<String> cuotaIds) async {
    for (final id in cuotaIds) {
      _porId.remove(id);
    }
  }

  /// Solo para los tests: comprobar que un fallo no dejó cuotas sueltas, sin
  /// tener que saber a qué contrato habrían pertenecido.
  Future<List<Cuota>> todas() async => _porId.values.toList();
}
