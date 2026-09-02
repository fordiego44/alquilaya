import 'dart:async';

import 'package:alquilaya/aplicacion/puertos/autenticacion.dart';

/// Sesión de mentira para los tests: no habla con Supabase ni con la red.
///
/// Por defecto arranca **con** sesión, que es el escenario de las pruebas de
/// presentación existentes: entran directamente a las pantallas. Un test que
/// quiera el caso contrario construye `AutenticacionEnMemoria(autenticado:
/// false)`.
class AutenticacionEnMemoria implements Autenticacion {
  bool _haySesion;

  /// `broadcast` porque más de un widget puede escuchar la misma sesión, y
  /// porque un test puede no escuchar en absoluto sin que eso bloquee nada.
  final _cambios = StreamController<bool>.broadcast();

  AutenticacionEnMemoria({bool autenticado = true}) : _haySesion = autenticado;

  @override
  bool get haySesion => _haySesion;

  @override
  Stream<bool> get cambiosDeSesion => _cambios.stream;

  /// Acepta cualquier credencial: aquí no se comprueban contraseñas, solo se
  /// simula que la sesión se abre. Un test que necesite el fallo usará su
  /// propio doble.
  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    _cambiarA(true);
  }

  /// Permite a un test provocar la pérdida de sesión sin pasar por la interfaz.
  void cerrarSesionEnElDoble() => _cambiarA(false);

  void _cambiarA(bool haySesion) {
    _haySesion = haySesion;
    _cambios.add(haySesion);
  }
}
