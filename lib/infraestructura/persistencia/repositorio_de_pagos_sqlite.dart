import 'package:sqflite/sqflite.dart';

import '../../aplicacion/puertos/repositorio_de_pagos.dart';
import '../../dominio/entidades/pago.dart';
import '../../dominio/valores/dinero.dart';

/// Adaptador SQLite del almacén de pagos.
class RepositorioDePagosSqlite implements RepositorioDePagos {
  final Database _db;

  RepositorioDePagosSqlite(this._db);

  /// Actualiza en su sitio si el id ya existe, nunca por borrado y reinserción.
  @override
  Future<void> guardar(Pago pago) => _db.execute(
    '''
    INSERT INTO pagos (id, cuota_id, monto_centavos, fecha_pago)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      cuota_id       = excluded.cuota_id,
      monto_centavos = excluded.monto_centavos,
      fecha_pago     = excluded.fecha_pago
    ''',
    [pago.id, pago.cuotaId, pago.monto.centavos, pago.fechaPago.toIso8601String()],
  );

  /// Sin cuotas por las que preguntar no hay pagos que devolver, y consultar
  /// con `IN ()` sería SQL inválido. El caso ocurre de verdad: `ListarCuotas` y
  /// `ConsultarDashboard` llaman con el resultado de `cuotas.todas()`, que en
  /// una base recién creada está vacío.
  @override
  Future<List<Pago>> deCuotas(Iterable<String> cuotaIds) async {
    final ids = cuotaIds.toList();
    if (ids.isEmpty) return [];

    final huecos = List.filled(ids.length, '?').join(', ');
    final filas = await _db.query(
      'pagos',
      where: 'cuota_id IN ($huecos)',
      whereArgs: ids,
    );
    return filas.map(_desdeFila).toList();
  }

  Pago _desdeFila(Map<String, Object?> fila) => Pago(
    id: fila['id'] as String,
    cuotaId: fila['cuota_id'] as String,
    monto: Dinero(fila['monto_centavos'] as int),
    fechaPago: DateTime.parse(fila['fecha_pago'] as String),
  );
}
