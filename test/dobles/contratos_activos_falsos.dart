import 'package:alquilaya/aplicacion/puertos/contratos_activos.dart';

/// Responde el predicado de ocupación a partir de un conjunto fijo de ids.
/// No simula contratos: en esta fase no existen todavía.
class ContratosActivosFalsos implements ContratosActivos {
  final Set<String> _ocupadas;

  ContratosActivosFalsos([Set<String> ocupadas = const {}])
    : _ocupadas = ocupadas;

  @override
  Future<Set<String>> habitacionesOcupadas() async => _ocupadas;

  @override
  Future<bool> tieneContratoActivo(String habitacionId) async =>
      _ocupadas.contains(habitacionId);
}
