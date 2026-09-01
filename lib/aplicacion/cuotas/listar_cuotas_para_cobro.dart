import '../../dominio/entidades/contrato.dart';
import '../../dominio/entidades/cuota.dart';
import '../../dominio/entidades/inquilino.dart';
import '../excepciones.dart';
import '../puertos/repositorio_de_contratos.dart';
import '../puertos/repositorio_de_habitaciones.dart';
import '../puertos/repositorio_de_inquilinos.dart';
import 'cuota_con_estado.dart';
import 'listar_cuotas.dart';

/// Una cuota con lo que hace falta para ir a cobrarla: a quién, dónde y cómo
/// avisarle.
///
/// Es un modelo de salida de la aplicación, no una entidad. `Cuota` solo conoce
/// su contrato; el nombre del inquilino, el de la habitación y el teléfono se
/// resuelven al leer y no se guardan en ninguna parte.
class CuotaParaCobro {
  final CuotaConEstado cuota;
  final String nombreInquilino;
  final String nombreHabitacion;

  /// `null` cuando no se conoce, igual que en [Inquilino].
  final String? telefono;

  const CuotaParaCobro({
    required this.cuota,
    required this.nombreInquilino,
    required this.nombreHabitacion,
    this.telefono,
  });

  @override
  String toString() =>
      'CuotaParaCobro(${cuota.cuota.periodo}, $nombreInquilino, '
      '$nombreHabitacion)';
}

/// Lista las cuotas listas para cobrar, cada una con su inquilino y habitación.
///
/// Compone [ListarCuotas] en lugar de repetirlo: el estado, el monto pendiente
/// y el orden por vencimiento se siguen derivando en un solo sitio. Aquí solo
/// se añaden los nombres.
///
/// Los tres almacenes se leen **una vez** y se cruzan en memoria, en lugar de
/// preguntar por cada cuota. Es de solo lectura: no genera cuotas ni escribe.
class ListarCuotasParaCobro {
  final ListarCuotas _listarCuotas;
  final RepositorioDeContratos _contratos;
  final RepositorioDeHabitaciones _habitaciones;
  final RepositorioDeInquilinos _inquilinos;

  ListarCuotasParaCobro(
    this._listarCuotas,
    this._contratos,
    this._habitaciones,
    this._inquilinos,
  );

  /// [estado] nulo devuelve todas. El filtro y el orden los aplica
  /// [ListarCuotas]; esta lista los conserva tal cual.
  ///
  /// Lanza [ReferenciaInconsistente] si una cuota apunta a un contrato que no
  /// existe, o el contrato a una habitación o un inquilino que no existen. La
  /// consulta falla entera: una lista de cobranza a la que le falta gente es
  /// peor que un error visible.
  Future<List<CuotaParaCobro>> ejecutar({
    required DateTime hoy,
    EstadoCuota? estado,
  }) async {
    final cuotas = await _listarCuotas.ejecutar(hoy: hoy, estado: estado);
    if (cuotas.isEmpty) return [];

    final contratos = {
      for (final contrato in await _contratos.listar()) contrato.id: contrato,
    };
    final habitaciones = {
      for (final habitacion in await _habitaciones.listar())
        habitacion.id: habitacion.nombre,
    };
    final inquilinos = {
      for (final inquilino in await _inquilinos.listar())
        inquilino.id: inquilino,
    };

    return [
      for (final cuota in cuotas)
        _paraCobro(cuota, contratos, habitaciones, inquilinos),
    ];
  }

  CuotaParaCobro _paraCobro(
    CuotaConEstado cuota,
    Map<String, Contrato> contratos,
    Map<String, String> habitaciones,
    Map<String, Inquilino> inquilinos,
  ) {
    final contratoId = cuota.cuota.contratoId;
    final contrato = contratos[contratoId];
    if (contrato == null) {
      throw ReferenciaInconsistente(
        'la cuota ${cuota.cuota.id} apunta al contrato $contratoId, que no '
        'existe',
      );
    }

    final nombreHabitacion = habitaciones[contrato.habitacionId];
    if (nombreHabitacion == null) {
      throw ReferenciaInconsistente(
        'el contrato ${contrato.id} apunta a la habitación '
        '${contrato.habitacionId}, que no existe',
      );
    }

    final inquilino = inquilinos[contrato.inquilinoId];
    if (inquilino == null) {
      throw ReferenciaInconsistente(
        'el contrato ${contrato.id} apunta al inquilino '
        '${contrato.inquilinoId}, que no existe',
      );
    }

    return CuotaParaCobro(
      cuota: cuota,
      nombreInquilino: inquilino.nombre,
      nombreHabitacion: nombreHabitacion,
      telefono: inquilino.telefono,
    );
  }
}
