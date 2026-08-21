import 'package:alquilaya/aplicacion/puertos/generador_de_id.dart';

/// Genera ids secuenciales para que los tests puedan afirmar sobre ids
/// concretos: 'id1', 'id2'... por defecto, con el prefijo configurable
/// (`GeneradorDeIdSecuencial('h')` produce 'h1', 'h2'...).
class GeneradorDeIdSecuencial implements GeneradorDeId {
  final String _prefijo;
  int _siguiente = 0;

  GeneradorDeIdSecuencial([this._prefijo = 'id']);

  @override
  Future<String> nuevoId() async => '$_prefijo${++_siguiente}';
}
