import 'dart:math';

import '../aplicacion/puertos/generador_de_id.dart';

/// Genera ids a partir del reloj más un sufijo aleatorio.
///
/// Basta para una aplicación local de un solo usuario: dos ids solo chocarían
/// si se pidieran en el mismo microsegundo y además coincidiera el aleatorio.
/// No se añade una dependencia de UUID porque nada la necesita todavía; el día
/// que existan varios orígenes escribiendo a la vez, se reemplaza este
/// adaptador sin tocar a quien lo usa.
///
/// Efecto secundario útil: al empezar por el instante de creación, los ids
/// quedan ordenados por antigüedad.
class GeneradorDeIdDeReloj implements GeneradorDeId {
  final Random _aleatorio;

  GeneradorDeIdDeReloj([Random? aleatorio]) : _aleatorio = aleatorio ?? Random();

  @override
  Future<String> nuevoId() async {
    final instante = DateTime.now().microsecondsSinceEpoch;
    final sufijo = _aleatorio
        .nextInt(0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0');
    return '$instante-$sufijo';
  }
}
