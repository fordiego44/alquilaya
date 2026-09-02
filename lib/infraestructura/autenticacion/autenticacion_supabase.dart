import 'package:supabase_flutter/supabase_flutter.dart';

import '../../aplicacion/puertos/autenticacion.dart';

/// Implementa [Autenticacion] contra Supabase Auth.
///
/// Recibe el cliente por constructor en vez de tomarlo de `Supabase.instance`:
/// quién lo crea es asunto del arranque, y así este adaptador no depende de que
/// exista un singleton ya inicializado.
///
/// No guarda la contraseña ni la sesión: de eso se encarga el propio cliente,
/// que persiste el token y lo renueva. Tampoco registra nada en consola —email,
/// contraseña, tokens y sesiones acabarían en los logs del dispositivo.
class AutenticacionSupabase implements Autenticacion {
  final SupabaseClient _cliente;

  AutenticacionSupabase(this._cliente);

  @override
  bool get haySesion => _cliente.auth.currentSession != null;

  /// El stream de Supabase emite el evento completo; aquí solo sale el hecho de
  /// si hay sesión o no, que es lo único que la aplicación necesita saber.
  @override
  Stream<bool> get cambiosDeSesion =>
      _cliente.auth.onAuthStateChange.map((estado) => estado.session != null);

  /// Deja subir el `AuthException` de Supabase tal cual: traducirlo a una
  /// excepción propia sin saber todavía qué mensajes mostrará la interfaz sería
  /// inventarse una clasificación. Se hará cuando exista la pantalla de login.
  @override
  Future<void> iniciarSesion({
    required String email,
    required String password,
  }) async {
    await _cliente.auth.signInWithPassword(email: email, password: password);
  }
}
