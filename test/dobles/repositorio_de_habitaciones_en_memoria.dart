import 'package:alquilaya/aplicacion/puertos/repositorio_de_habitaciones.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';

/// Implementación en memoria para las pruebas. Es asíncrona como el puerto,
/// aunque resuelva de inmediato, para ejercitar el mismo contrato.
class RepositorioDeHabitacionesEnMemoria implements RepositorioDeHabitaciones {
  final Map<String, Habitacion> _porId = {};

  /// Precarga habitaciones para montar el escenario de un test en una línea.
  RepositorioDeHabitacionesEnMemoria([List<Habitacion> iniciales = const []]) {
    for (final habitacion in iniciales) {
      _porId[habitacion.id] = habitacion;
    }
  }

  @override
  Future<void> guardar(Habitacion habitacion) async {
    _porId[habitacion.id] = habitacion;
  }

  @override
  Future<Habitacion?> obtenerPorId(String id) async => _porId[id];

  @override
  Future<List<Habitacion>> listar() async => _porId.values.toList();
}
