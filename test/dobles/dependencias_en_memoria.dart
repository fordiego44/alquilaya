import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_todos_los_contratos.dart';
import 'package:alquilaya/aplicacion/contratos/consultar_historial_de_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/crear_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/finalizar_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/listar_contratos.dart';
import 'package:alquilaya/aplicacion/cuotas/listar_cuotas.dart';
import 'package:alquilaya/aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import 'package:alquilaya/aplicacion/dashboard/consultar_dashboard.dart';
import 'package:alquilaya/aplicacion/habitaciones/archivar_habitacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/editar_habitacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/eliminar_habitacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/listar_habitaciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/reactivar_habitacion.dart';
import 'package:alquilaya/aplicacion/habitaciones/registrar_habitacion.dart';
import 'package:alquilaya/aplicacion/inquilinos/archivar_inquilino.dart';
import 'package:alquilaya/aplicacion/inquilinos/editar_inquilino.dart';
import 'package:alquilaya/aplicacion/inquilinos/eliminar_inquilino.dart';
import 'package:alquilaya/aplicacion/inquilinos/listar_inquilinos.dart';
import 'package:alquilaya/aplicacion/inquilinos/reactivar_inquilino.dart';
import 'package:alquilaya/aplicacion/inquilinos/registrar_inquilino.dart';
import 'package:alquilaya/aplicacion/pagos/registrar_pago.dart';
import 'package:alquilaya/composicion.dart';
import 'package:alquilaya/dominio/entidades/contrato.dart';
import 'package:alquilaya/dominio/entidades/habitacion.dart';
import 'package:alquilaya/dominio/entidades/inquilino.dart';

import 'generador_de_id_secuencial.dart';
import 'repositorio_de_contratos_en_memoria.dart';
import 'repositorio_de_cuotas_en_memoria.dart';
import 'repositorio_de_habitaciones_en_memoria.dart';
import 'repositorio_de_inquilinos_en_memoria.dart';
import 'repositorio_de_pagos_en_memoria.dart';

/// Cablea la aplicación sobre los almacenes en memoria.
///
/// Es el mismo grafo que `construirDependencias`, pero sin SQLite: la interfaz
/// solo conoce casos de uso, así que se la puede arrancar entera sin abrir
/// ninguna base de datos.
///
/// Los parámetros son la **siembra** del escenario: el estado que ya existía
/// antes de que el usuario abriera la app. No son una API de construcción; para
/// todo lo demás, los tests usan la interfaz de verdad.
Dependencias dependenciasEnMemoria({
  List<Habitacion> habitaciones = const [],
  List<Inquilino> inquilinos = const [],
  List<Contrato> contratos = const [],
}) {
  final repoHabitaciones = RepositorioDeHabitacionesEnMemoria(habitaciones);
  final repoInquilinos = RepositorioDeInquilinosEnMemoria(inquilinos);
  final repoContratos = RepositorioDeContratosEnMemoria(contratos);
  final cuotas = RepositorioDeCuotasEnMemoria();
  final pagos = RepositorioDePagosEnMemoria();
  final generadorDeId = GeneradorDeIdSecuencial();

  final actualizarCuotasDeContrato = ActualizarCuotasDeContrato(
    repoContratos,
    cuotas,
    generadorDeId,
  );
  final listarHabitaciones = ListarHabitaciones(
    repoHabitaciones,
    repoContratos,
  );

  // `ListarCuotas` no se expone: es la pieza que `ListarCuotasParaCobro`
  // envuelve para añadir a quién y dónde se cobra.
  final listarCuotas = ListarCuotas(cuotas, pagos);
  final listarCuotasParaCobro = ListarCuotasParaCobro(
    listarCuotas,
    repoContratos,
    repoHabitaciones,
    repoInquilinos,
  );

  return Dependencias(
    registrarHabitacion: RegistrarHabitacion(repoHabitaciones, generadorDeId),
    listarHabitaciones: listarHabitaciones,
    editarHabitacion: EditarHabitacion(repoHabitaciones),
    eliminarHabitacion: EliminarHabitacion(repoHabitaciones, repoContratos),
    archivarHabitacion: ArchivarHabitacion(repoHabitaciones, repoContratos),
    reactivarHabitacion: ReactivarHabitacion(repoHabitaciones),
    registrarInquilino: RegistrarInquilino(repoInquilinos, generadorDeId),
    listarInquilinos: ListarInquilinos(repoInquilinos),
    editarInquilino: EditarInquilino(repoInquilinos),
    eliminarInquilino: EliminarInquilino(repoInquilinos, repoContratos),
    archivarInquilino: ArchivarInquilino(repoInquilinos, repoContratos),
    reactivarInquilino: ReactivarInquilino(repoInquilinos),
    crearContrato: CrearContrato(
      repoContratos,
      cuotas,
      pagos,
      repoHabitaciones,
      repoInquilinos,
      generadorDeId,
    ),
    listarContratos: ListarContratos(repoContratos),
    finalizarContrato: FinalizarContrato(
      repoContratos,
      cuotas,
      pagos,
      actualizarCuotasDeContrato,
    ),
    consultarHistorialDeContrato: ConsultarHistorialDeContrato(
      repoContratos,
      cuotas,
      pagos,
    ),
    listarCuotasParaCobro: listarCuotasParaCobro,
    registrarPago: RegistrarPago(cuotas, pagos, generadorDeId),
    consultarDashboard: ConsultarDashboard(
      listarHabitaciones,
      listarCuotasParaCobro,
      pagos,
    ),
    actualizarCuotas: ActualizarCuotasDeTodosLosContratos(
      repoContratos,
      actualizarCuotasDeContrato,
    ),
  );
}
