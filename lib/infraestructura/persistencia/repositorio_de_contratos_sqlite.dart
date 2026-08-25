import 'package:sqflite/sqflite.dart';

import '../../aplicacion/puertos/repositorio_de_contratos.dart';
import '../../dominio/entidades/contrato.dart';
import '../../dominio/valores/dinero.dart';

/// Adaptador SQLite del almacén de contratos.
///
/// Implementa también `ContratosActivos`, que `RepositorioDeContratos` extiende:
/// la ocupación se responde siempre desde los contratos realmente guardados.
class RepositorioDeContratosSqlite implements RepositorioDeContratos {
  final Database _db;

  RepositorioDeContratosSqlite(this._db);

  /// Actualiza la fila en su sitio cuando el contrato ya existe.
  ///
  /// Es el caso donde REPLACE haría más daño: `FinalizarContrato` guarda un
  /// contrato que normalmente **ya tiene cuotas**, y borrar su fila para
  /// reinsertarla rompería esas referencias. El UPSERT la modifica sin tocarlas.
  ///
  /// El id no se actualiza: es la clave del conflicto y no cambia.
  @override
  Future<void> guardar(Contrato contrato) => _db.execute(
    '''
    INSERT INTO contratos (
      id, habitacion_id, inquilino_id,
      fecha_inicio, monto_mensual_centavos, fecha_fin
    ) VALUES (?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      habitacion_id          = excluded.habitacion_id,
      inquilino_id           = excluded.inquilino_id,
      fecha_inicio           = excluded.fecha_inicio,
      monto_mensual_centavos = excluded.monto_mensual_centavos,
      fecha_fin              = excluded.fecha_fin
    ''',
    [
      contrato.id,
      contrato.habitacionId,
      contrato.inquilinoId,
      contrato.fechaInicio.toIso8601String(),
      contrato.montoMensual.centavos,
      contrato.fechaFin?.toIso8601String(),
    ],
  );

  @override
  Future<Contrato?> obtenerPorId(String id) async {
    final filas = await _db.query(
      'contratos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return filas.isEmpty ? null : _desdeFila(filas.first);
  }

  @override
  Future<List<Contrato>> listar() async =>
      (await _db.query('contratos')).map(_desdeFila).toList();

  /// Se filtra en Dart con `Contrato.estaActivo` en lugar de escribir
  /// `WHERE fecha_fin IS NULL`: qué significa "activo" lo define el dominio y
  /// no debe quedar duplicado en SQL, donde se desincronizaría en silencio.
  @override
  Future<Set<String>> habitacionesOcupadas() async => {
    for (final contrato in await listar())
      if (contrato.estaActivo) contrato.habitacionId,
  };

  @override
  Future<bool> tieneContratoActivo(String habitacionId) async =>
      (await listar()).any(
        (contrato) =>
            contrato.estaActivo && contrato.habitacionId == habitacionId,
      );

  Contrato _desdeFila(Map<String, Object?> fila) {
    final fechaFin = fila['fecha_fin'] as String?;
    return Contrato(
      id: fila['id'] as String,
      habitacionId: fila['habitacion_id'] as String,
      inquilinoId: fila['inquilino_id'] as String,
      fechaInicio: DateTime.parse(fila['fecha_inicio'] as String),
      montoMensual: Dinero(fila['monto_mensual_centavos'] as int),
      fechaFin: fechaFin == null ? null : DateTime.parse(fechaFin),
    );
  }
}
