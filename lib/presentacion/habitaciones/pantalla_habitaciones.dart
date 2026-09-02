import 'package:flutter/material.dart';

import '../../aplicacion/habitaciones/estado_de_ocupacion.dart';
import '../../aplicacion/habitaciones/listar_habitaciones.dart';
import '../../composicion.dart';
import '../../dominio/entidades/habitacion.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';
import 'formulario_de_habitacion.dart';

/// Qué listado se está mirando. Archivar no borra: lo archivado sigue estando,
/// solo deja de ofrecerse para contratos nuevos.
enum _Vista { activas, archivadas }

/// Qué se puede hacer con una fila. El menú ofrece archivar o reactivar según
/// el estado, nunca las dos.
enum _Accion { editar, archivar, reactivar, eliminar }

/// Listado de habitaciones con su ocupación.
///
/// Si una habitación está ocupada o disponible no se calcula aquí: lo dice
/// `ListarHabitaciones`, que lo deriva de los contratos activos (regla 1). Esta
/// pantalla solo elige cómo pintarlo.
///
/// Tampoco decide quién puede archivarse o eliminarse: lo intenta y enseña lo
/// que responda el caso de uso. Repetir aquí "tiene contratos" sería tener la
/// regla en dos sitios.
class PantallaHabitaciones extends StatefulWidget {
  final Dependencias dependencias;

  const PantallaHabitaciones({super.key, required this.dependencias});

  @override
  State<PantallaHabitaciones> createState() => _PantallaHabitacionesState();
}

class _PantallaHabitacionesState extends State<PantallaHabitaciones> {
  /// La consulta en curso. Reasignarla dentro de `setState` es lo que hace que
  /// `FutureBuilder` vuelva a pedir los datos: no hace falta ningún otro
  /// mecanismo de estado.
  late Future<List<HabitacionListada>> _habitaciones;
  _Vista _vista = _Vista.activas;

  @override
  void initState() {
    super.initState();
    _habitaciones = _consultar();
  }

  /// La vista de archivadas pide el listado completo y se queda con las
  /// archivadas. El caso de uso no tiene un "solo archivadas" porque nadie más
  /// lo necesita: quedarse con unas cuantas de una lista es cosa de quien las
  /// muestra.
  Future<List<HabitacionListada>> _consultar() async {
    // Se captura antes del await: si alguien cambia de pestaña mientras la
    // consulta está en vuelo, el filtrado tiene que corresponder a la vista con
    // la que se pidió, no a la que haya cuando vuelva.
    final vista = _vista;
    final listado = await widget.dependencias.listarHabitaciones.ejecutar(
      incluirArchivadas: vista == _Vista.archivadas,
    );
    if (vista == _Vista.activas) return listado;
    return [
      for (final listada in listado)
        if (listada.habitacion.archivada) listada,
    ];
  }

  void _recargar() {
    setState(() {
      _habitaciones = _consultar();
    });
  }

  void _cambiarVista(_Vista vista) {
    setState(() {
      _vista = vista;
      _habitaciones = _consultar();
    });
  }

  /// Ejecuta una acción y refresca, o enseña por qué no se pudo.
  ///
  /// Existe porque archivar, reactivar y eliminar fallan igual y se recuperan
  /// igual. El error llega ya tipado desde la aplicación y se traduce con
  /// `mensajeDeError`; aquí no se interpreta ninguna regla.
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

  Future<void> _nuevaHabitacion() async {
    final creada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDeHabitacion(
          registrarHabitacion: widget.dependencias.registrarHabitacion,
          // El formulario es el mismo para alta y edición, así que siempre
          // recibe ambos casos de uso; `habitacion: null` es lo que lo pone en
          // modo alta.
          editarHabitacion: widget.dependencias.editarHabitacion,
        ),
      ),
    );

    // Se pudo cambiar de pestaña mientras el formulario estaba abierto, y
    // `_recargar` llama a `setState`.
    if (!mounted) return;
    // Vuelve con `null` cuando el usuario se echa atrás: nada que refrescar.
    if (creada != null) _recargar();
  }

  Future<void> _editar(Habitacion habitacion) async {
    final editada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDeHabitacion(
          registrarHabitacion: widget.dependencias.registrarHabitacion,
          editarHabitacion: widget.dependencias.editarHabitacion,
          habitacion: habitacion,
        ),
      ),
    );

    if (!mounted) return;
    if (editada != null) _recargar();
  }

  /// Archivar es reversible, así que no se pregunta: si fue un error, se
  /// reactiva desde la propia vista de archivadas.
  Future<void> _archivar(Habitacion habitacion) => _intentar(
    () => widget.dependencias.archivarHabitacion.ejecutar(habitacion.id),
  );

  Future<void> _reactivar(Habitacion habitacion) => _intentar(
    () => widget.dependencias.reactivarHabitacion.ejecutar(habitacion.id),
  );

  /// Eliminar sí pregunta: es físico y no se puede deshacer.
  Future<void> _eliminar(Habitacion habitacion) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar habitación'),
        content: Text(
          'Se eliminará "${habitacion.nombre}" definitivamente.\n\n'
          'Esta acción no se puede deshacer. Si la habitación tiene '
          'contratos, archívala en su lugar.',
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
      () => widget.dependencias.eliminarHabitacion.ejecutar(habitacion.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habitaciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaHabitacion,
        icon: const Icon(Icons.add),
        label: const Text('Habitación'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<_Vista>(
              segments: const [
                ButtonSegment(value: _Vista.activas, label: Text('Activas')),
                ButtonSegment(
                  value: _Vista.archivadas,
                  label: Text('Archivadas'),
                ),
              ],
              selected: {_vista},
              onSelectionChanged: (seleccion) => _cambiarVista(seleccion.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<HabitacionListada>>(
              future: _habitaciones,
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

                final habitaciones = snapshot.data ?? const [];
                if (habitaciones.isEmpty) {
                  return _SinHabitaciones(vista: _vista);
                }

                return ListView.builder(
                  // Deja sitio para que el botón no tape la última fila.
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: habitaciones.length,
                  itemBuilder: (context, indice) {
                    final listada = habitaciones[indice];
                    return _FilaDeHabitacion(
                      listada,
                      alEditar: () => _editar(listada.habitacion),
                      alArchivar: () => _archivar(listada.habitacion),
                      alReactivar: () => _reactivar(listada.habitacion),
                      alEliminar: () => _eliminar(listada.habitacion),
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

class _FilaDeHabitacion extends StatelessWidget {
  final HabitacionListada listada;
  final VoidCallback alEditar;
  final VoidCallback alArchivar;
  final VoidCallback alReactivar;
  final VoidCallback alEliminar;

  const _FilaDeHabitacion(
    this.listada, {
    required this.alEditar,
    required this.alArchivar,
    required this.alReactivar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final ocupada = listada.estado == EstadoDeOcupacion.ocupada;
    final archivada = listada.habitacion.archivada;
    final colores = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        archivada
            ? Icons.inventory_2_outlined
            : (ocupada ? Icons.meeting_room : Icons.meeting_room_outlined),
        color: ocupada && !archivada ? colores.primary : colores.outline,
      ),
      title: Text(
        listada.habitacion.nombre,
        // Atenuado y con su etiqueta: se distingue de un vistazo sin tachados
        // ni adornos.
        style: archivada ? TextStyle(color: colores.outline) : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              archivada ? 'Archivada' : (ocupada ? 'Ocupada' : 'Disponible'),
            ),
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
              if (archivada)
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

class _SinHabitaciones extends StatelessWidget {
  final _Vista vista;

  const _SinHabitaciones({required this.vista});

  @override
  Widget build(BuildContext context) {
    final archivadas = vista == _Vista.archivadas;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              archivadas
                  ? 'No hay habitaciones archivadas'
                  : 'Todavía no hay habitaciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              archivadas
                  ? 'Al archivar una habitación la verás aquí.'
                  : 'Registra la primera para poder crear contratos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
