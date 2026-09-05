import 'package:flutter/material.dart';

import '../composicion.dart';
import 'autenticacion/puerta_de_autenticacion.dart';

/// Raíz de la interfaz.
///
/// Recibe las [Dependencias] ya construidas y las entrega a la puerta de
/// autenticación, que decide si se ve el login o la navegación: no las crea ni
/// sabe qué hay detrás de ellas. Su única responsabilidad propia es el tema.
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
      home: PuertaDeAutenticacion(dependencias: dependencias),
    );
  }
}
