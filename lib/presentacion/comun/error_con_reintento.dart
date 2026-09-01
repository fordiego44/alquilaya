import 'package:flutter/material.dart';

/// Lo que se enseña cuando una carga falla: qué pasó y cómo volver a intentarlo.
///
/// Existe porque los cinco listados fallan igual y lo resuelven igual. No
/// interpreta el error: recibe [mensaje] ya traducido con `mensajeDeError`, de
/// modo que decidir qué decir sigue siendo cosa de quien conoce el contexto.
class ErrorConReintento extends StatelessWidget {
  final String mensaje;
  final VoidCallback alReintentar;

  const ErrorConReintento({
    super.key,
    required this.mensaje,
    required this.alReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: alReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
