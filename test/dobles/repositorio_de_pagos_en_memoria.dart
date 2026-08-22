import 'package:alquilaya/aplicacion/puertos/repositorio_de_pagos.dart';
import 'package:alquilaya/dominio/entidades/pago.dart';

class RepositorioDePagosEnMemoria implements RepositorioDePagos {
  final Map<String, Pago> _porId = {};

  RepositorioDePagosEnMemoria([List<Pago> iniciales = const []]) {
    for (final pago in iniciales) {
      _porId[pago.id] = pago;
    }
  }

  @override
  Future<void> guardar(Pago pago) async {
    _porId[pago.id] = pago;
  }

  @override
  Future<List<Pago>> deCuotas(Iterable<String> cuotaIds) async {
    final ids = cuotaIds.toSet();
    return _porId.values.where((pago) => ids.contains(pago.cuotaId)).toList();
  }

  /// Solo para los tests: ningún pago debe desaparecer nunca (regla 12).
  Future<List<Pago>> todos() async => _porId.values.toList();
}
