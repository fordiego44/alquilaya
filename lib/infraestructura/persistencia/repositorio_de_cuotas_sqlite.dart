import 'package:sqflite/sqflite.dart';

import '../../aplicacion/puertos/repositorio_de_cuotas.dart';
import '../../dominio/entidades/cuota.dart';
import '../../dominio/valores/dinero.dart';
import '../../dominio/valores/periodo.dart';

/// Adaptador SQLite del almacén de cuotas.
class RepositorioDeCuotasSqlite implements RepositorioDeCuotas {
  static const _upsert = '''
    INSERT INTO cuotas (
      id, contrato_id, periodo_anio, periodo_mes,
      monto_centavos, fecha_vencimiento
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      contrato_id       = excluded.contrato_id,
      periodo_anio      = excluded.periodo_anio,
      periodo_mes       = excluded.periodo_mes,
      monto_centavos    = excluded.monto_centavos,
      fecha_vencimiento = excluded.fecha_vencimiento
    ''';

  final Database _db;

  RepositorioDeCuotasSqlite(this._db);

  /// Guarda el lote en un solo viaje. Una cuota que ya existe se actualiza en su
  /// sitio: si tuviera pagos, siguen colgando de ella. Con REPLACE se habrían
  /// perdido o habrían hecho fallar la clave foránea.
  @override
  Future<void> guardarTodas(List<Cuota> cuotas) async {
    if (cuotas.isEmpty) return;

    final lote = _db.batch();
    for (final cuota in cuotas) {
      lote.rawInsert(_upsert, [
        cuota.id,
        cuota.contratoId,
        cuota.periodo.anio,
        cuota.periodo.mes,
        cuota.monto.centavos,
        cuota.fechaVencimiento.toIso8601String(),
      ]);
    }
    await lote.commit(noResult: true);
  }

  @override
  Future<Cuota?> obtenerPorId(String id) async {
    final filas = await _db.query(
      'cuotas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return filas.isEmpty ? null : _desdeFila(filas.first);
  }

  @override
  Future<List<Cuota>> deContrato(String contratoId) async => (await _db.query(
    'cuotas',
    where: 'contrato_id = ?',
    whereArgs: [contratoId],
  )).map(_desdeFila).toList();

  @override
  Future<List<Cuota>> todas() async =>
      (await _db.query('cuotas')).map(_desdeFila).toList();

  /// Sin ids no hay nada que borrar, y `IN ()` no es SQL válido.
  @override
  Future<void> eliminar(Iterable<String> cuotaIds) async {
    final ids = cuotaIds.toList();
    if (ids.isEmpty) return;

    final huecos = List.filled(ids.length, '?').join(', ');
    await _db.delete('cuotas', where: 'id IN ($huecos)', whereArgs: ids);
  }

  Cuota _desdeFila(Map<String, Object?> fila) => Cuota(
    id: fila['id'] as String,
    contratoId: fila['contrato_id'] as String,
    periodo: Periodo(fila['periodo_anio'] as int, fila['periodo_mes'] as int),
    monto: Dinero(fila['monto_centavos'] as int),
    fechaVencimiento: DateTime.parse(fila['fecha_vencimiento'] as String),
  );
}
