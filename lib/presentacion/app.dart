import 'package:flutter/material.dart';

import '../composicion.dart';
import 'navegacion_principal.dart';

/// Raíz de la interfaz.
///
/// Recibe las [Dependencias] ya construidas y las entrega a la navegación: no
/// las crea ni sabe qué hay detrás de ellas. Su única responsabilidad propia es
/// el tema.
class AlquilaYaApp extends StatelessWidget {
  final Dependencias dependencias;

  const AlquilaYaApp({super.key, required this.dependencias});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlquilaYa',
      // Material 3 con un color semilla y nada más: el MVP no necesita un
      // sistema de diseño propio ni varios temas.
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: NavegacionPrincipal(dependencias: dependencias),
    );
  }
}
