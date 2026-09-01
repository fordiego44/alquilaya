import 'package:flutter/material.dart';

import '../../composicion.dart';
import '../../dominio/entidades/inquilino.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';
import 'formulario_de_inquilino.dart';

/// Listado de inquilinos.
///
/// Solo consulta y alta: editar y eliminar quedan fuera del MVP, así que no hay
/// acciones por fila.
class PantallaInquilinos extends StatefulWidget {
  final Dependencias dependencias;

  const PantallaInquilinos({super.key, required this.dependencias});

  @override
  State<PantallaInquilinos> createState() => _PantallaInquilinosState();
}

class _PantallaInquilinosState extends State<PantallaInquilinos> {
  late Future<List<Inquilino>> _inquilinos;

  @override
  void initState() {
    super.initState();
    _inquilinos = _consultar();
  }

  Future<List<Inquilino>> _consultar() =>
      widget.dependencias.listarInquilinos.ejecutar();

  void _recargar() {
    setState(() {
      _inquilinos = _consultar();
    });
  }

  Future<void> _nuevoInquilino() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDeInquilino(
          registrarInquilino: widget.dependencias.registrarInquilino,
        ),
      ),
    );

    if (!mounted) return;
    if (creado != null) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inquilinos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoInquilino,
        icon: const Icon(Icons.add),
        label: const Text('Inquilino'),
      ),
      body: FutureBuilder<List<Inquilino>>(
        future: _inquilinos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorConReintento(
              mensaje: mensajeDeError(snapshot.error!),
              alReintentar: _recargar,
            );
          }

          final inquilinos = snapshot.data ?? const [];
          if (inquilinos.isEmpty) {
            return const _SinInquilinos();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: inquilinos.length,
            itemBuilder: (context, indice) => _FilaDeInquilino(
              inquilinos[indice],
            ),
          );
        },
      ),
    );
  }
}

class _FilaDeInquilino extends StatelessWidget {
  final Inquilino inquilino;

  const _FilaDeInquilino(this.inquilino);

  @override
  Widget build(BuildContext context) {
    // Solo se muestran los datos que existen: un "Documento: —" no aporta nada.
    final detalles = [
      if (inquilino.documento != null) inquilino.documento!,
      if (inquilino.telefono != null) inquilino.telefono!,
    ].join(' · ');

    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Text(inquilino.nombre),
      subtitle: detalles.isEmpty ? null : Text(detalles),
    );
  }
}

class _SinInquilinos extends StatelessWidget {
  const _SinInquilinos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay inquilinos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra al primero para poder crear contratos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
