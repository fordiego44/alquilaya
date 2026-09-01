import 'package:flutter/material.dart';

import '../../aplicacion/inquilinos/registrar_inquilino.dart';
import '../../dominio/entidades/inquilino.dart';
import '../comun/mensajes.dart';

/// Alta de un inquilino. Se cierra devolviendo el inquilino creado, o `null` si
/// el usuario se echó atrás.
///
/// Documento y teléfono son opcionales. Un campo vacío se envía como `null`,
/// que es como [Inquilino] representa "no se conoce": mandar una cadena en
/// blanco sería un segundo modo de decir lo mismo, y el dominio lo rechaza.
class FormularioDeInquilino extends StatefulWidget {
  final RegistrarInquilino registrarInquilino;

  const FormularioDeInquilino({super.key, required this.registrarInquilino});

  @override
  State<FormularioDeInquilino> createState() => _FormularioDeInquilinoState();
}

class _FormularioDeInquilinoState extends State<FormularioDeInquilino> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _documento = TextEditingController();
  final _telefono = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _documento.dispose();
    _telefono.dispose();
    super.dispose();
  }

  /// Un campo opcional en blanco es un dato que no se conoce, no una cadena
  /// vacía.
  String? _opcional(TextEditingController campo) {
    final valor = campo.text.trim();
    return valor.isEmpty ? null : valor;
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final inquilino = await widget.registrarInquilino.ejecutar(
        nombre: _nombre.text.trim(),
        documento: _opcional(_documento),
        telefono: _opcional(_telefono),
      );
      if (mounted) Navigator.pop(context, inquilino);
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
      appBar: AppBar(title: const Text('Nuevo inquilino')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (valor) => (valor == null || valor.trim().isEmpty)
                  ? 'Escribe un nombre'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documento,
              decoration: const InputDecoration(
                labelText: 'Documento (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono (opcional)',
                border: OutlineInputBorder(),
              ),
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
