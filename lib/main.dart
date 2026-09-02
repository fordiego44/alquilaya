import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'composicion.dart';
import 'infraestructura/autenticacion/autenticacion_supabase.dart';
import 'infraestructura/persistencia/base_de_datos.dart';
import 'presentacion/app.dart';

/// Credenciales del proyecto Supabase. Llegan como constantes de compilación,
/// no desde un fichero leído en tiempo de ejecución: así no viajan en el
/// repositorio ni hay que empaquetar el JSON como asset.
///
/// Se rellenan con `--dart-define-from-file=config/supabase.json`, que está
/// ignorado por Git. `config/supabase.example.json` documenta su forma.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

/// Arranque de AlquilaYa: abre la base local, cablea la aplicación y la lanza.
///
/// Aquí no vive ninguna pantalla ni ninguna regla: solo el orden en que se
/// montan las piezas.
Future<void> main() async {
  // Hace falta antes de tocar cualquier plugin, y `sqflite` lo es.
  WidgetsFlutterBinding.ensureInitialized();

  // Sin credenciales no se arranca: `String.fromEnvironment` devuelve cadena
  // vacía cuando falta el define, y un cliente Supabase mal configurado fallaría
  // más tarde y en otro sitio. El mensaje no incluye los valores: uno de ellos
  // es una clave, y los errores acaban en registros.
  if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
    throw StateError(
      'Faltan SUPABASE_URL y/o SUPABASE_PUBLISHABLE_KEY. Ejecuta la app con '
      '--dart-define-from-file=config/supabase.json',
    );
  }

  // Solo deja el cliente listo. La app todavía no lo usa: la persistencia sigue
  // siendo SQLite hasta que existan los repositorios contra Supabase.
  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );

  // El único punto donde se elige Supabase como implementación de la sesión.
  // De aquí en adelante solo circula el puerto `Autenticacion`.
  final autenticacion = AutenticacionSupabase(Supabase.instance.client);

  // `getDatabasesPath` devuelve la carpeta de bases de datos que la plataforma
  // reserva a la app. Se une con '/' literal en vez de traer `package:path`
  // solo para esto: en Android ese es el separador.
  final ruta = '${await getDatabasesPath()}/alquilaya.db';

  // Un fallo aquí no se captura a propósito: sin base de datos no hay nada que
  // mostrar, y esconderlo dejaría una app que parece funcionar y no guarda.
  final db = await abrirBaseDeDatos(ruta: ruta);

  final dependencias = construirDependencias(db, autenticacion: autenticacion);

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
