import 'package:flutter/material.dart';

import '../../aplicacion/habitaciones/registrar_habitacion.dart';
import '../../dominio/entidades/habitacion.dart';
import '../comun/mensajes.dart';

/// Alta de una habitación. Se cierra devolviendo la habitación creada, o `null`
/// si el usuario se echó atrás.
///
/// La única validación que hace es de formulario —que el campo no esté vacío—.
/// Que el nombre sea válido lo decide el constructor de [Habitacion]; si lo
/// rechaza, el error se enseña tal cual llega, sin repetir la comprobación.
class FormularioDeHabitacion extends StatefulWidget {
  final RegistrarHabitacion registrarHabitacion;

  const FormularioDeHabitacion({super.key, required this.registrarHabitacion});

  @override
  State<FormularioDeHabitacion> createState() => _FormularioDeHabitacionState();
}

class _FormularioDeHabitacionState extends State<FormularioDeHabitacion> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final habitacion = await widget.registrarHabitacion.ejecutar(
        nombre: _nombre.text.trim(),
      );
      if (mounted) Navigator.pop(context, habitacion);
    } catch (error) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva habitación')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                helperText: 'Cómo la reconoces: "Habitación 1", "La del patio"…',
                border: OutlineInputBorder(),
              ),
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'Escribe un nombre'
                  : null,
              onFieldSubmitted: (_) => _guardando ? null : _guardar(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
