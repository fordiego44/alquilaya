import 'package:sqflite/sqflite.dart';

import '../../aplicacion/puertos/repositorio_de_habitaciones.dart';
import '../../dominio/entidades/habitacion.dart';

/// Adaptador SQLite del almacén de habitaciones.
///
/// Recibe la conexión ya abierta: quién es el dueño de la base y de su ciclo de
/// vida no es asunto de un repositorio.
class RepositorioDeHabitacionesSqlite implements RepositorioDeHabitaciones {
  final Database _db;

  RepositorioDeHabitacionesSqlite(this._db);

  /// Inserta, y si el id ya existe actualiza la fila **en su sitio**.
  ///
  /// Nunca `INSERT OR REPLACE`: REPLACE borra la fila en conflicto antes de
  /// reinsertarla, y con las claves foráneas activas eso rompería o arrastraría
  /// las filas que la referencian.
  @override
  Future<void> guardar(Habitacion habitacion) => _db.execute(
    '''
    INSERT INTO habitaciones (id, nombre, archivada) VALUES (?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      nombre    = excluded.nombre,
      archivada = excluded.archivada
    ''',
    // SQLite no tiene booleano: 0/1, como el resto de la base.
    [habitacion.id, habitacion.nombre, habitacion.archivada ? 1 : 0],
  );

  @override
  Future<Habitacion?> obtenerPorId(String id) async {
    final filas = await _db.query(
      'habitaciones',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return filas.isEmpty ? null : _desdeFila(filas.first);
  }

  @override
  Future<List<Habitacion>> listar() async =>
      (await _db.query('habitaciones')).map(_desdeFila).toList();

  /// Borra la fila con [id]. Un id inexistente no es un error: un `DELETE` que
  /// no afecta a ninguna fila es un no-op, que es justo lo que pide el puerto.
  ///
  /// **Sin CASCADE en ninguna parte.** Si un contrato referencia esta
  /// habitación, la clave foránea rechaza el borrado y sqflite lanza
  /// `DatabaseException`. Es la barrera de último recurso: el caso de uso
  /// comprueba antes y da un mensaje comprensible, pero si alguna vez se
  /// olvidara, el historial sigue sin poder romperse.
  @override
  Future<void> eliminar(String id) =>
      _db.delete('habitaciones', where: 'id = ?', whereArgs: [id]);

  /// Reconstruye por el constructor del dominio, no por un atajo: así una fila
  /// corrupta falla al leerse y no más adelante.
  Habitacion _desdeFila(Map<String, Object?> fila) => Habitacion(
    id: fila['id'] as String,
    nombre: fila['nombre'] as String,
    archivada: (fila['archivada'] as int) == 1,
  );
}
