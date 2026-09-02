import 'package:flutter/material.dart';

import '../../composicion.dart';
import '../../dominio/entidades/inquilino.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';
import 'formulario_de_inquilino.dart';

/// Qué listado se está mirando. Archivar no borra: lo archivado sigue estando,
/// solo deja de ofrecerse para contratos nuevos.
enum _Vista { activos, archivados }

/// Qué se puede hacer con una fila. El menú ofrece archivar o reactivar según
/// el estado, nunca las dos.
enum _Accion { editar, archivar, reactivar, eliminar }

/// Listado de inquilinos, con alta, edición, archivado y borrado.
///
/// No decide quién puede archivarse o eliminarse: lo intenta y enseña lo que
/// responda el caso de uso. Comprobar aquí si alguien tiene contratos sería
/// tener la regla en dos sitios.
class PantallaInquilinos extends StatefulWidget {
  final Dependencias dependencias;

  const PantallaInquilinos({super.key, required this.dependencias});

  @override
  State<PantallaInquilinos> createState() => _PantallaInquilinosState();
}

class _PantallaInquilinosState extends State<PantallaInquilinos> {
  late Future<List<Inquilino>> _inquilinos;
  _Vista _vista = _Vista.activos;

  @override
  void initState() {
    super.initState();
    _inquilinos = _consultar();
  }

  /// La vista de archivados pide el listado completo y se queda con los
  /// archivados. El caso de uso no tiene un "solo archivados" porque nadie más
  /// lo necesita.
  Future<List<Inquilino>> _consultar() async {
    // Se captura antes del await: si se cambia de pestaña con la consulta en
    // vuelo, el filtrado debe corresponder a la vista con la que se pidió.
    final vista = _vista;
    final listado = await widget.dependencias.listarInquilinos.ejecutar(
      incluirArchivados: vista == _Vista.archivados,
    );
    if (vista == _Vista.activos) return listado;
    return [
      for (final inquilino in listado)
        if (inquilino.archivado) inquilino,
    ];
  }

  void _recargar() {
    setState(() {
      _inquilinos = _consultar();
    });
  }

  void _cambiarVista(_Vista vista) {
    setState(() {
      _vista = vista;
      _inquilinos = _consultar();
    });
  }

  /// Ejecuta una acción y refresca, o enseña por qué no se pudo. El error llega
  /// ya tipado desde la aplicación y se traduce con `mensajeDeError`.
  Future<void> _intentar(Future<void> Function() accion) async {
    try {
      await accion();
      if (!mounted) return;
      _recargar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeError(error))));
    }
  }

  Future<void> _nuevoInquilino() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDeInquilino(
          registrarInquilino: widget.dependencias.registrarInquilino,
          // El formulario es el mismo para alta y edición, así que siempre
          // recibe ambos casos de uso; `inquilino: null` lo pone en modo alta.
          editarInquilino: widget.dependencias.editarInquilino,
        ),
      ),
    );

    if (!mounted) return;
    if (creado != null) _recargar();
  }

  Future<void> _editar(Inquilino inquilino) async {
    final editado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDeInquilino(
          registrarInquilino: widget.dependencias.registrarInquilino,
          editarInquilino: widget.dependencias.editarInquilino,
          inquilino: inquilino,
        ),
      ),
    );

    if (!mounted) return;
    if (editado != null) _recargar();
  }

  /// Archivar es reversible, así que no se pregunta: si fue un error, se
  /// reactiva desde la propia vista de archivados.
  Future<void> _archivar(Inquilino inquilino) => _intentar(
    () => widget.dependencias.archivarInquilino.ejecutar(inquilino.id),
  );

  Future<void> _reactivar(Inquilino inquilino) => _intentar(
    () => widget.dependencias.reactivarInquilino.ejecutar(inquilino.id),
  );

  /// Eliminar sí pregunta: es físico y no se puede deshacer.
  Future<void> _eliminar(Inquilino inquilino) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar inquilino'),
        content: Text(
          'Se eliminará a "${inquilino.nombre}" definitivamente.\n\n'
          'Esta acción no se puede deshacer. Si el inquilino tiene contratos, '
          'archívalo en su lugar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;

    await _intentar(
      () => widget.dependencias.eliminarInquilino.ejecutar(inquilino.id),
    );
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<_Vista>(
              segments: const [
                ButtonSegment(value: _Vista.activos, label: Text('Activos')),
                ButtonSegment(
                  value: _Vista.archivados,
                  label: Text('Archivados'),
                ),
              ],
              selected: {_vista},
              onSelectionChanged: (seleccion) => _cambiarVista(seleccion.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Inquilino>>(
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
                  return _SinInquilinos(vista: _vista);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: inquilinos.length,
                  itemBuilder: (context, indice) {
                    final inquilino = inquilinos[indice];
                    return _FilaDeInquilino(
                      inquilino,
                      alEditar: () => _editar(inquilino),
                      alArchivar: () => _archivar(inquilino),
                      alReactivar: () => _reactivar(inquilino),
                      alEliminar: () => _eliminar(inquilino),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaDeInquilino extends StatelessWidget {
  final Inquilino inquilino;
  final VoidCallback alEditar;
  final VoidCallback alArchivar;
  final VoidCallback alReactivar;
  final VoidCallback alEliminar;

  const _FilaDeInquilino(
    this.inquilino, {
    required this.alEditar,
    required this.alArchivar,
    required this.alReactivar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    // Solo se muestran los datos que existen: un "Documento: —" no aporta nada.
    final detalles = [
      if (inquilino.documento != null) inquilino.documento!,
      if (inquilino.telefono != null) inquilino.telefono!,
    ].join(' · ');
    final archivado = inquilino.archivado;
    final colores = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          archivado ? Icons.inventory_2_outlined : Icons.person_outline,
        ),
      ),
      title: Text(
        inquilino.nombre,
        // Atenuado y con su etiqueta: se distingue de un vistazo sin tachados
        // ni adornos.
        style: archivado ? TextStyle(color: colores.outline) : null,
      ),
      subtitle: detalles.isEmpty ? null : Text(detalles),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Un inquilino activo no lleva chip: la ausencia ya es la norma.
          if (archivado)
            const Chip(
              label: Text('Archivado'),
              visualDensity: VisualDensity.compact,
            ),
          PopupMenuButton<_Accion>(
            tooltip: 'Acciones',
            onSelected: (accion) => switch (accion) {
              _Accion.editar => alEditar(),
              _Accion.archivar => alArchivar(),
              _Accion.reactivar => alReactivar(),
              _Accion.eliminar => alEliminar(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _Accion.editar,
                child: Text('Editar'),
              ),
              if (archivado)
                const PopupMenuItem(
                  value: _Accion.reactivar,
                  child: Text('Reactivar'),
                )
              else
                const PopupMenuItem(
                  value: _Accion.archivar,
                  child: Text('Archivar'),
                ),
              const PopupMenuItem(
                value: _Accion.eliminar,
                child: Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SinInquilinos extends StatelessWidget {
  final _Vista vista;

  const _SinInquilinos({required this.vista});

  @override
  Widget build(BuildContext context) {
    final archivados = vista == _Vista.archivados;

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
              archivados
                  ? 'No hay inquilinos archivados'
                  : 'Todavía no hay inquilinos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              archivados
                  ? 'Al archivar a un inquilino lo verás aquí.'
                  : 'Registra al primero para poder crear contratos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
