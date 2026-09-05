import 'package:flutter/material.dart';

import '../../aplicacion/puertos/autenticacion.dart';

/// Entrada a la app cuando no hay sesión.
///
/// Recibe el puerto [Autenticacion] y no un cliente concreto: esta pantalla no
/// sabe que detrás hay Supabase, ni podría averiguarlo.
///
/// El error se enseña siempre igual, venga de donde venga. Distinguir "esa
/// cuenta no existe" de "esa contraseña no es" le diría a quien prueba correos
/// cuáles están registrados; y un fallo de red no merece un mensaje distinto
/// porque la acción de quien mira la pantalla es la misma: revisar y reintentar.
class PantallaLogin extends StatefulWidget {
  final Autenticacion autenticacion;

  const PantallaLogin({super.key, required this.autenticacion});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  bool _entrando = false;

  @override
  void dispose() {
    // Los controladores son lo único que guarda la contraseña, y mueren con la
    // pantalla: no se copia a ningún campo ni se conserva tras entrar.
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _entrando = true);
    try {
      await widget.autenticacion.iniciarSesion(
        email: _correo.text.trim(),
        password: _password.text,
      );
      // No se navega desde aquí: quien decide qué se muestra es la puerta de
      // autenticación, que ya está escuchando el cambio de sesión.
    } catch (_) {
      // El error se descarta a propósito: no se registra ni se muestra su
      // detalle, que puede mencionar la cuenta o el proveedor.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo iniciar sesión. Verifica tu correo, contraseña y '
            'conexión.',
          ),
        ),
      );
    } finally {
      // Si la sesión se abrió, esta pantalla ya no está montada y no hay nada
      // que restaurar.
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formulario,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'AlquilaYa',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _correo,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    border: OutlineInputBorder(),
                  ),
                  // Solo se comprueba que haya algo: validar el formato del
                  // correo aquí duplicaría lo que el servidor decide de todos
                  // modos, y rechazaría direcciones válidas poco comunes.
                  validator: (valor) => (valor == null || valor.trim().isEmpty)
                      ? 'Escribe tu correo'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) => (valor == null || valor.isEmpty)
                      ? 'Escribe tu contraseña'
                      : null,
                  onFieldSubmitted: (_) => _entrando ? null : _iniciarSesion(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _entrando ? null : _iniciarSesion,
                  child: _entrando
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Iniciar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
