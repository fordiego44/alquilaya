import 'package:alquilaya/aplicacion/puertos/repositorio_de_inquilinos.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';

class RepositorioDeInquilinosEnMemoria implements RepositorioDeInquilinos {
  final Map<String, Inquilino> _porId = {};

  RepositorioDeInquilinosEnMemoria([List<Inquilino> iniciales = const []]) {
    for (final inquilino in iniciales) {
      _porId[inquilino.id] = inquilino;
    }
  }

  @override
  Future<void> guardar(Inquilino inquilino) async {
    _porId[inquilino.id] = inquilino;
  }

  @override
  Future<Inquilino?> obtenerPorId(String id) async => _porId[id];

  @override
  Future<List<Inquilino>> listar() async => _porId.values.toList();
}
