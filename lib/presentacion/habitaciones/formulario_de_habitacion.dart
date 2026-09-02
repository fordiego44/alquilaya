import 'package:flutter/material.dart';

import '../../aplicacion/habitaciones/editar_habitacion.dart';
import '../../aplicacion/habitaciones/registrar_habitacion.dart';
import '../../dominio/entidades/habitacion.dart';
import '../comun/mensajes.dart';

/// Alta o edición de una habitación. Se cierra devolviendo la habitación
/// guardada, o `null` si el usuario se echó atrás.
///
/// El mismo formulario sirve para las dos cosas: los campos son idénticos y
/// duplicarlo obligaría a arreglar cada cambio dos veces. Lo distingue
/// [habitacion]: si viene, se edita esa; si es `null`, se da de alta una nueva.
///
/// **Editar no toca el archivado.** Ni siquiera se menciona aquí: lo conserva
/// `EditarHabitacion` a partir de lo guardado, de modo que renombrar una
/// habitación archivada no puede reactivarla desde la interfaz.
///
/// La única validación que hace es de formulario —que el campo no esté vacío—.
/// Que el nombre sea válido lo decide el constructor de [Habitacion]; si lo
/// rechaza, el error se enseña tal cual llega, sin repetir la comprobación.
class FormularioDeHabitacion extends StatefulWidget {
  final RegistrarHabitacion registrarHabitacion;
  final EditarHabitacion editarHabitacion;

  /// `null` para dar de alta.
  final Habitacion? habitacion;

  const FormularioDeHabitacion({
    super.key,
    required this.registrarHabitacion,
    required this.editarHabitacion,
    this.habitacion,
  });

  @override
  State<FormularioDeHabitacion> createState() => _FormularioDeHabitacionState();
}

class _FormularioDeHabitacionState extends State<FormularioDeHabitacion> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  bool _guardando = false;

  bool get _esEdicion => widget.habitacion != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.habitacion?.nombre ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final nombre = _nombre.text.trim();
      final habitacion = _esEdicion
          ? await widget.editarHabitacion.ejecutar(
              id: widget.habitacion!.id,
              nombre: nombre,
            )
          : await widget.registrarHabitacion.ejecutar(nombre: nombre);
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
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar habitación' : 'Nueva habitación'),
      ),
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
