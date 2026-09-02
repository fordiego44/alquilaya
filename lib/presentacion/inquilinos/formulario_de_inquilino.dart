import 'package:flutter/material.dart';

import '../../aplicacion/inquilinos/editar_inquilino.dart';
import '../../aplicacion/inquilinos/registrar_inquilino.dart';
import '../../dominio/entidades/inquilino.dart';
import '../comun/mensajes.dart';

/// Alta o edición de un inquilino. Se cierra devolviendo el inquilino guardado,
/// o `null` si el usuario se echó atrás.
///
/// El mismo formulario sirve para las dos cosas: los campos son idénticos y
/// duplicarlo obligaría a arreglar cada cambio dos veces. Lo distingue
/// [inquilino]: si viene, se edita ese; si es `null`, se da de alta uno nuevo.
///
/// Documento y teléfono son opcionales. Un campo vacío se envía como `null`,
/// que es como [Inquilino] representa "no se conoce": mandar una cadena en
/// blanco sería un segundo modo de decir lo mismo, y el dominio lo rechaza.
/// Al editar, eso significa que vaciar un campo **borra** el dato, igual que
/// hace `EditarInquilino`.
///
/// **Editar no toca el archivado**: ni se menciona aquí. Lo conserva el caso de
/// uso a partir de lo guardado, de modo que corregir un nombre no puede
/// reactivar a alguien archivado.
class FormularioDeInquilino extends StatefulWidget {
  final RegistrarInquilino registrarInquilino;
  final EditarInquilino editarInquilino;

  /// `null` para dar de alta.
  final Inquilino? inquilino;

  const FormularioDeInquilino({
    super.key,
    required this.registrarInquilino,
    required this.editarInquilino,
    this.inquilino,
  });

  @override
  State<FormularioDeInquilino> createState() => _FormularioDeInquilinoState();
}

class _FormularioDeInquilinoState extends State<FormularioDeInquilino> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _documento;
  late final TextEditingController _telefono;
  bool _guardando = false;

  bool get _esEdicion => widget.inquilino != null;

  @override
  void initState() {
    super.initState();
    final inquilino = widget.inquilino;
    // Un dato ausente es `null` en el dominio y cadena vacía en el campo.
    _nombre = TextEditingController(text: inquilino?.nombre ?? '');
    _documento = TextEditingController(text: inquilino?.documento ?? '');
    _telefono = TextEditingController(text: inquilino?.telefono ?? '');
  }

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
      final nombre = _nombre.text.trim();
      final documento = _opcional(_documento);
      final telefono = _opcional(_telefono);
      final inquilino = _esEdicion
          ? await widget.editarInquilino.ejecutar(
              id: widget.inquilino!.id,
              nombre: nombre,
              documento: documento,
              telefono: telefono,
            )
          : await widget.registrarInquilino.ejecutar(
              nombre: nombre,
              documento: documento,
              telefono: telefono,
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
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar inquilino' : 'Nuevo inquilino'),
      ),
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
