import '../../dominio/entidades/inquilino.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Lista todos los inquilinos.
///
/// Sin búsqueda por texto: no hay todavía un consumidor que la justifique.
class ListarInquilinos {
  final RepositorioDeInquilinos _repositorio;

  ListarInquilinos(this._repositorio);

  Future<List<Inquilino>> ejecutar() => _repositorio.listar();
}
