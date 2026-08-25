import 'package:sqflite/sqflite.dart';

import '../../aplicacion/puertos/repositorio_de_inquilinos.dart';
import '../../dominio/entidades/inquilino.dart';

/// Adaptador SQLite del almacén de inquilinos.
class RepositorioDeInquilinosSqlite implements RepositorioDeInquilinos {
  final Database _db;

  RepositorioDeInquilinosSqlite(this._db);

  /// Actualiza en su sitio si el id ya existe. Nunca REPLACE: borraría la fila
  /// antes de reinsertarla, con el riesgo que eso tiene para las relaciones.
  ///
  /// `documento` y `telefono` viajan como NULL cuando no se conocen, que es la
  /// única forma en que el dominio representa un dato ausente.
  @override
  Future<void> guardar(Inquilino inquilino) => _db.execute(
    '''
    INSERT INTO inquilinos (id, nombre, documento, telefono)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      nombre    = excluded.nombre,
      documento = excluded.documento,
      telefono  = excluded.telefono
    ''',
    [inquilino.id, inquilino.nombre, inquilino.documento, inquilino.telefono],
  );

  @override
  Future<Inquilino?> obtenerPorId(String id) async {
    final filas = await _db.query(
      'inquilinos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return filas.isEmpty ? null : _desdeFila(filas.first);
  }

  @override
  Future<List<Inquilino>> listar() async =>
      (await _db.query('inquilinos')).map(_desdeFila).toList();

  Inquilino _desdeFila(Map<String, Object?> fila) => Inquilino(
    id: fila['id'] as String,
    nombre: fila['nombre'] as String,
    documento: fila['documento'] as String?,
    telefono: fila['telefono'] as String?,
  );
}
