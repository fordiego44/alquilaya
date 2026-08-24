import '../../dominio/entidades/cuota.dart';
import '../../dominio/entidades/pago.dart';
import '../../dominio/valores/dinero.dart';

/// Una cuota junto al estado y al pendiente que se derivan de sus pagos y de
/// una fecha concreta.
///
/// Es un dato de salida de la aplicación, no una entidad: ni el estado ni el
/// pendiente forman parte de [Cuota] y no deben poder guardarse. Se calculan
/// para un `hoy` determinado, así que el mismo par cuota/pagos produce
/// resultados distintos en fechas distintas.
class CuotaConEstado {
  final Cuota cuota;
  final EstadoCuota estado;
  final Dinero montoPendiente;

  const CuotaConEstado(this.cuota, this.estado, this.montoPendiente);

  /// Deriva el estado preguntándoselo a la propia cuota. [pagos] puede traer
  /// pagos de otras cuotas: el dominio se queda solo con los suyos.
  ///
  /// Vive aquí, y no en cada caso de uso, para que la lectura de una cuota
  /// signifique lo mismo en un listado que en un historial.
  factory CuotaConEstado.derivar(
    Cuota cuota,
    Iterable<Pago> pagos,
    DateTime hoy,
  ) => CuotaConEstado(
    cuota,
    cuota.estadoSegun(pagos, hoy),
    cuota.montoPendiente(pagos),
  );

  @override
  String toString() => 'CuotaConEstado(${cuota.periodo}, ${estado.name})';
}
