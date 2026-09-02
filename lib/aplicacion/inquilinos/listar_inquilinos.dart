import '../../dominio/entidades/inquilino.dart';
import '../puertos/repositorio_de_inquilinos.dart';

/// Lista todos los inquilinos.
///
/// Sin búsqueda por texto: no hay todavía un consumidor que la justifique.
///
/// Los **archivados se excluyen por defecto**, igual que en habitaciones: así
/// ninguna pantalla los ofrece para un contrato nuevo por haber olvidado un
/// filtro. Quien los necesite los pide.
class ListarInquilinos {
  final RepositorioDeInquilinos _repositorio;

  ListarInquilinos(this._repositorio);

  /// Con [incluirArchivados] en `true` devuelve todos, activos y archivados.
  /// El filtro vive aquí, no en el repositorio, que sigue devolviendo todo.
  Future<List<Inquilino>> ejecutar({bool incluirArchivados = false}) async {
    final inquilinos = await _repositorio.listar();
    if (incluirArchivados) return inquilinos;
    return [
      for (final inquilino in inquilinos)
        if (!inquilino.archivado) inquilino,
    ];
  }
}
