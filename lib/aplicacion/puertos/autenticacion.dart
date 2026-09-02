/// Sesión del usuario que está usando la app.
///
/// Existe como puerto para que la presentación no dependa de Supabase: quien
/// pregunta si hay sesión solo conoce esta interfaz, y en los tests se sustituye
/// por un doble sin red.
///
/// Es deliberadamente estrecho. No expone el usuario, ni el token, ni la sesión
/// en sí: la app todavía no necesita ninguna de las tres cosas, y devolverlas
/// obligaría a arrastrar los tipos de Supabase hasta la aplicación.
abstract interface class Autenticacion {
  /// Si hay sesión **ahora mismo**. Es una lectura puntual; para reaccionar a
  /// los cambios está [cambiosDeSesion].
  bool get haySesion;

  /// Emite cada vez que la sesión aparece o desaparece.
  Stream<bool> get cambiosDeSesion;

  /// Abre sesión con email y contraseña. Falla lanzando: no devuelve un
  /// resultado que quien llama pueda ignorar por descuido.
  Future<void> iniciarSesion({
    required String email,
    required String password,
  });
}
