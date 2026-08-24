import '../../dominio/entidades/contrato.dart';
import 'contratos_activos.dart';

/// Almacén de contratos.
///
/// Extiende [ContratosActivos] a propósito: quien guarda los contratos es
/// también quien puede decir qué habitaciones están ocupadas, así que ambas
/// respuestas salen de la misma fuente y no pueden contradecirse. Los casos de
/// uso de habitaciones siguen dependiendo solo del puerto estrecho.
abstract interface class RepositorioDeContratos implements ContratosActivos {
  /// Inserta o reemplaza por id.
  Future<void> guardar(Contrato contrato);

  /// Devuelve `null` si no existe.
  Future<Contrato?> obtenerPorId(String id);

  /// Todos los contratos, activos y finalizados. Sin filtros por habitación ni
  /// por inquilino: quien los necesita los aplica en memoria, que para una
  /// vivienda es suficiente y evita comprometer al puerto con consultas que
  /// todavía nadie ha pedido.
  Future<List<Contrato>> listar();
}
