import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/actualizar_cuotas_de_todos_los_contratos.dart';
import 'package:alquilaya/aplicacion/contratos/consultar_historial_de_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/crear_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/finalizar_contrato.dart';
import 'package:alquilaya/aplicacion/contratos/listar_contratos.dart';
import 'package:alquilaya/aplicacion/cuotas/listar_cuotas.dart';
import 'package:alquilaya/aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import 'package:alquilaya/aplicacion/dashboard/consultar_dashboard.dart';
import 'package:alquilaya/aplicacion/habitaciones/listar_habitaciones.dart';
import 'package:alquilaya/aplicacion/habitaciones/registrar_habitacion.dart';
import 'package:alquilaya/aplicacion/inquilinos/listar_inquilinos.dart';
import 'package:alquilaya/aplicacion/inquilinos/registrar_inquilino.dart';
import 'package:alquilaya/aplicacion/pagos/registrar_pago.dart';
import 'package:alquilaya/composicion.dart';
import 'package:alquilaya/presentacion/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dobles/generador_de_id_secuencial.dart';
import 'dobles/repositorio_de_contratos_en_memoria.dart';
import 'dobles/repositorio_de_cuotas_en_memoria.dart';
import 'dobles/repositorio_de_habitaciones_en_memoria.dart';
import 'dobles/repositorio_de_inquilinos_en_memoria.dart';
import 'dobles/repositorio_de_pagos_en_memoria.dart';

/// Cablea la aplicación sobre los almacenes en memoria.
///
/// Es el mismo grafo que `construirDependencias`, pero sin SQLite: la interfaz
/// solo conoce casos de uso, así que se la puede arrancar entera sin abrir
/// ninguna base de datos.
Dependencias dependenciasEnMemoria() {
  final habitaciones = RepositorioDeHabitacionesEnMemoria();
  final inquilinos = RepositorioDeInquilinosEnMemoria();
  final cuotas = RepositorioDeCuotasEnMemoria();
  final pagos = RepositorioDePagosEnMemoria();
  final contratos = RepositorioDeContratosEnMemoria();
  final generadorDeId = GeneradorDeIdSecuencial();

  final actualizarCuotasDeContrato = ActualizarCuotasDeContrato(
    contratos,
    cuotas,
    generadorDeId,
  );
  final listarHabitaciones = ListarHabitaciones(habitaciones, contratos);

  // `ListarCuotas` no se expone: es la pieza que `ListarCuotasParaCobro`
  // envuelve para añadir a quién y dónde se cobra.
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

void main() {
  testWidgets('arranca en el panel con la base vacía', (tester) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria()),
    );
    // Las pantallas cargan sus datos de forma asíncrona.
    await tester.pumpAndSettle();

    // El panel es el destino inicial.
    expect(find.text('AlquilaYa'), findsOneWidget);
    expect(find.text('Ocupadas'), findsOneWidget);
    expect(find.text('Disponibles'), findsOneWidget);
    expect(find.text('Deuda vencida'), findsOneWidget);

    // Sin contratos no hay nada que cobrar, y se dice.
    expect(find.text('No hay cobros próximos.'), findsOneWidget);
  });

  testWidgets('ofrece los cinco destinos de la navegación', (tester) async {
    await tester.pumpWidget(
      AlquilaYaApp(dependencias: dependenciasEnMemoria()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final destino in [
      'Inicio',
      'Cuotas',
      'Contratos',
      'Habitaciones',
      'Inquilinos',
    ]) {
      expect(find.text(destino), findsOneWidget);
    }
  });
}
