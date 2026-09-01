import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'composicion.dart';
import 'infraestructura/persistencia/base_de_datos.dart';
import 'presentacion/app.dart';

/// Arranque de AlquilaYa: abre la base local, cablea la aplicación y la lanza.
///
/// Aquí no vive ninguna pantalla ni ninguna regla: solo el orden en que se
/// montan las piezas.
Future<void> main() async {
  // Hace falta antes de tocar cualquier plugin, y `sqflite` lo es.
  WidgetsFlutterBinding.ensureInitialized();

  // `getDatabasesPath` devuelve la carpeta de bases de datos que la plataforma
  // reserva a la app. Se une con '/' literal en vez de traer `package:path`
  // solo para esto: en Android ese es el separador.
  final ruta = '${await getDatabasesPath()}/alquilaya.db';

  // Un fallo aquí no se captura a propósito: sin base de datos no hay nada que
  // mostrar, y esconderlo dejaría una app que parece funcionar y no guarda.
  final db = await abrirBaseDeDatos(ruta: ruta);

  final dependencias = construirDependencias(db);

  // La puesta al día sí puede fallar sin impedir el arranque: la app sigue
  // siendo usable, solo que la cartera muestra las cuotas que ya existían. Es
  // una operación explícita, nunca un efecto secundario de consultar.
  try {
    await dependencias.actualizarCuotas.ejecutar(hoy: DateTime.now());
  } catch (error) {
    debugPrint('No se pudieron poner al día las cuotas al arrancar: $error');
  }

  runApp(AlquilaYaApp(dependencias: dependencias));
}
