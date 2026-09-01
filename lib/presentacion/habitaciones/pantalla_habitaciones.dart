import 'package:flutter/material.dart';

import '../../aplicacion/habitaciones/estado_de_ocupacion.dart';
import '../../aplicacion/habitaciones/listar_habitaciones.dart';
import '../../composicion.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';
import 'formulario_de_habitacion.dart';

/// Listado de habitaciones con su ocupación.
///
/// Si una habitación está ocupada o disponible no se calcula aquí: lo dice
/// `ListarHabitaciones`, que lo deriva de los contratos activos (regla 1). Esta
/// pantalla solo elige cómo pintarlo.
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

  @override
  void initState() {
    super.initState();
    _habitaciones = _consultar();
  }

  Future<List<HabitacionListada>> _consultar() =>
      widget.dependencias.listarHabitaciones.ejecutar();

  void _recargar() {
    setState(() {
      _habitaciones = _consultar();
    });
  }

  Future<void> _nuevaHabitacion() async {
    final creada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDeHabitacion(
          registrarHabitacion: widget.dependencias.registrarHabitacion,
        ),
      ),
    );

    // Se pudo cambiar de pestaña mientras el formulario estaba abierto, y
    // `_recargar` llama a `setState`.
    if (!mounted) return;
    // Vuelve con `null` cuando el usuario se echa atrás: nada que refrescar.
    if (creada != null) _recargar();
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
      body: FutureBuilder<List<HabitacionListada>>(
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
            return const _SinHabitaciones();
          }

          return ListView.builder(
            // Deja sitio para que el botón no tape la última fila.
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: habitaciones.length,
            itemBuilder: (context, indice) =>
                _FilaDeHabitacion(habitaciones[indice]),
          );
        },
      ),
    );
  }
}

class _FilaDeHabitacion extends StatelessWidget {
  final HabitacionListada listada;

  const _FilaDeHabitacion(this.listada);

  @override
  Widget build(BuildContext context) {
    final ocupada = listada.estado == EstadoDeOcupacion.ocupada;
    final colores = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        ocupada ? Icons.meeting_room : Icons.meeting_room_outlined,
        color: ocupada ? colores.primary : colores.outline,
      ),
      title: Text(listada.habitacion.nombre),
      trailing: Chip(
        label: Text(ocupada ? 'Ocupada' : 'Disponible'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SinHabitaciones extends StatelessWidget {
  const _SinHabitaciones();

  @override
  Widget build(BuildContext context) {
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
              'Todavía no hay habitaciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra la primera para poder crear contratos.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
