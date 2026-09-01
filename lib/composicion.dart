import 'package:sqflite/sqflite.dart';

import 'aplicacion/contratos/actualizar_cuotas_de_contrato.dart';
import 'aplicacion/contratos/actualizar_cuotas_de_todos_los_contratos.dart';
import 'aplicacion/contratos/consultar_historial_de_contrato.dart';
import 'aplicacion/contratos/crear_contrato.dart';
import 'aplicacion/contratos/finalizar_contrato.dart';
import 'aplicacion/contratos/listar_contratos.dart';
import 'aplicacion/cuotas/listar_cuotas.dart';
import 'aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import 'aplicacion/dashboard/consultar_dashboard.dart';
import 'aplicacion/habitaciones/listar_habitaciones.dart';
import 'aplicacion/habitaciones/registrar_habitacion.dart';
import 'aplicacion/inquilinos/listar_inquilinos.dart';
import 'aplicacion/inquilinos/registrar_inquilino.dart';
import 'aplicacion/pagos/registrar_pago.dart';
import 'aplicacion/puertos/generador_de_id.dart';
import 'infraestructura/generador_de_id_de_reloj.dart';
import 'infraestructura/persistencia/repositorio_de_contratos_sqlite.dart';
import 'infraestructura/persistencia/repositorio_de_cuotas_sqlite.dart';
import 'infraestructura/persistencia/repositorio_de_habitaciones_sqlite.dart';
import 'infraestructura/persistencia/repositorio_de_inquilinos_sqlite.dart';
import 'infraestructura/persistencia/repositorio_de_pagos_sqlite.dart';

/// Los casos de uso que la interfaz necesita, ya construidos.
///
/// Es el único sitio donde la presentación y la infraestructura se encuentran:
/// las pantallas reciben esto por constructor y no saben de dónde salen sus
/// dependencias ni qué las implementa.
///
/// No es un contenedor de inyección: es una clase Dart con campos finales. Con
/// doce casos de uso y un solo grafo, un service locator solo añadiría magia.
///
/// Solo están los que alguna pantalla usa. Los casos de uso de edición y de
/// consulta puntual existen en la aplicación, pero mientras ninguna pantalla
/// los llame no tienen por qué aparecer aquí.
class Dependencias {
  final RegistrarHabitacion registrarHabitacion;
  final ListarHabitaciones listarHabitaciones;

  final RegistrarInquilino registrarInquilino;
  final ListarInquilinos listarInquilinos;

  final CrearContrato crearContrato;
  final ListarContratos listarContratos;
  final FinalizarContrato finalizarContrato;
  final ConsultarHistorialDeContrato consultarHistorialDeContrato;

  /// Las cuotas llegan con su inquilino y su habitación: la interfaz no cruza
  /// datos por su cuenta. `ListarCuotas` queda como pieza interna de este
  /// caso de uso, sin consumidor directo en las pantallas.
  final ListarCuotasParaCobro listarCuotasParaCobro;

  final RegistrarPago registrarPago;

  final ConsultarDashboard consultarDashboard;

  /// La puesta al día es una operación explícita: la ejecuta el arranque y el
  /// botón de refrescar del panel, nunca una consulta por su cuenta.
  final ActualizarCuotasDeTodosLosContratos actualizarCuotas;

  const Dependencias({
    required this.registrarHabitacion,
    required this.listarHabitaciones,
    required this.registrarInquilino,
    required this.listarInquilinos,
    required this.crearContrato,
    required this.listarContratos,
    required this.finalizarContrato,
    required this.consultarHistorialDeContrato,
    required this.listarCuotasParaCobro,
    required this.registrarPago,
    required this.consultarDashboard,
    required this.actualizarCuotas,
  });
}

/// Cablea la aplicación sobre la base de datos [db].
///
/// Es el *composition root*: aquí, y solo aquí, se elige que los puertos los
/// implemente SQLite. Sustituir la persistencia significaría cambiar estas
/// líneas y nada más.
Dependencias construirDependencias(Database db) {
  final habitaciones = RepositorioDeHabitacionesSqlite(db);
  final inquilinos = RepositorioDeInquilinosSqlite(db);
  final cuotas = RepositorioDeCuotasSqlite(db);
  final pagos = RepositorioDePagosSqlite(db);

  // Sirve a la vez de repositorio de contratos y de `ContratosActivos`, que es
  // el puerto estrecho que consulta la ocupación: el mismo adaptador responde a
  // ambos, así que la ocupación sale siempre de los contratos guardados.
  final contratos = RepositorioDeContratosSqlite(db);

  final GeneradorDeId generadorDeId = GeneradorDeIdDeReloj();

  // Pieza intermedia: no la usa ninguna pantalla, pero sí quien pone al día la
  // cartera y quien finaliza un contrato.
  final actualizarCuotasDeContrato = ActualizarCuotasDeContrato(
    contratos,
    cuotas,
    generadorDeId,
  );

  final listarHabitaciones = ListarHabitaciones(habitaciones, contratos);

  // `ListarCuotas` no se expone: deriva estado y orden, y `ListarCuotasParaCobro`
  // lo envuelve añadiendo a quién y dónde cobrar. Las pantallas usan el segundo.
  final listarCuotas = ListarCuotas(cuotas, pagos);
  final listarCuotasParaCobro = ListarCuotasParaCobro(
    listarCuotas,
    contratos,
    habitaciones,
    inquilinos,
  );

  return Dependencias(
    registrarHabitacion: RegistrarHabitacion(habitaciones, generadorDeId),
    listarHabitaciones: listarHabitaciones,
    registrarInquilino: RegistrarInquilino(inquilinos, generadorDeId),
    listarInquilinos: ListarInquilinos(inquilinos),
    crearContrato: CrearContrato(
      contratos,
      cuotas,
      pagos,
      habitaciones,
      inquilinos,
      generadorDeId,
    ),
    listarContratos: ListarContratos(contratos),
    finalizarContrato: FinalizarContrato(
      contratos,
      cuotas,
      pagos,
      actualizarCuotasDeContrato,
    ),
    consultarHistorialDeContrato: ConsultarHistorialDeContrato(
      contratos,
      cuotas,
      pagos,
    ),
    listarCuotasParaCobro: listarCuotasParaCobro,
    registrarPago: RegistrarPago(cuotas, pagos, generadorDeId),
    // Reutiliza los dos listados en lugar de recalcular: el panel agrega, no
    // vuelve a derivar.
    consultarDashboard: ConsultarDashboard(
      listarHabitaciones,
      listarCuotasParaCobro,
      pagos,
    ),
    actualizarCuotas: ActualizarCuotasDeTodosLosContratos(
      contratos,
      actualizarCuotasDeContrato,
    ),
  );
}
