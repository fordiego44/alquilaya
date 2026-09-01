import 'package:flutter/material.dart';

import '../../composicion.dart';
import '../../dominio/entidades/contrato.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';
import 'formulario_de_contrato.dart';
import 'pantalla_historial_de_contrato.dart';

/// Los contratos junto a los nombres que hacen falta para reconocerlos.
///
/// `Contrato` guarda ids, no nombres: cruzarlos con las habitaciones y los
/// inquilinos es cosa de quien los muestra.
class _Listado {
  final List<Contrato> contratos;
  final Map<String, String> habitaciones;
  final Map<String, String> inquilinos;

  const _Listado(this.contratos, this.habitaciones, this.inquilinos);

  String habitacionDe(Contrato contrato) =>
      habitaciones[contrato.habitacionId] ?? 'Habitación eliminada';

  String inquilinoDe(Contrato contrato) =>
      inquilinos[contrato.inquilinoId] ?? 'Inquilino eliminado';
}

/// Listado de contratos, activos y finalizados.
class PantallaContratos extends StatefulWidget {
  final Dependencias dependencias;

  const PantallaContratos({super.key, required this.dependencias});

  @override
  State<PantallaContratos> createState() => _PantallaContratosState();
}

class _PantallaContratosState extends State<PantallaContratos> {
  late Future<_Listado> _listado;

  @override
  void initState() {
    super.initState();
    _listado = _consultar();
  }

  Future<_Listado> _consultar() async {
    final dependencias = widget.dependencias;
    final contratos = await dependencias.listarContratos.ejecutar();
    final habitaciones = await dependencias.listarHabitaciones.ejecutar();
    final inquilinos = await dependencias.listarInquilinos.ejecutar();

    return _Listado(
      contratos,
      {for (final l in habitaciones) l.habitacion.id: l.habitacion.nombre},
      {for (final i in inquilinos) i.id: i.nombre},
    );
  }

  void _recargar() {
    setState(() {
      _listado = _consultar();
    });
  }

  Future<void> _nuevoContrato() async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FormularioDeContrato(dependencias: widget.dependencias),
      ),
    );

    if (!mounted) return;
    if (creado != null) _recargar();
  }

  Future<void> _abrirHistorial(Contrato contrato) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaHistorialDeContrato(
          dependencias: widget.dependencias,
          contratoId: contrato.id,
        ),
      ),
    );

    // Desde el historial se puede finalizar el contrato, así que al volver la
    // lista puede haber cambiado.
    if (!mounted) return;
    _recargar();
  }

  /// Pide la fecha de fin, confirma y delega en `FinalizarContrato`.
  ///
  /// La UI no toca el contrato ni sus cuotas: qué se conserva y qué se elimina
  /// es la regla 12 y la aplica el caso de uso.
  Future<void> _finalizar(Contrato contrato) async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final inicio = DateTime(
      contrato.fechaInicio.year,
      contrato.fechaInicio.month,
      contrato.fechaInicio.day,
    );
    // Un contrato que aún no ha empezado no tiene ninguna fecha de fin válida:
    // tendría que ser posterior al inicio y anterior a hoy a la vez. Se dice y
    // no se abre el calendario.
    if (inicio.isAfter(hoy)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este contrato todavía no ha comenzado.')),
      );
      return;
    }

    final fechaFin = await showDatePicker(
      context: context,
      initialDate: hoy,
      // Un contrato no puede acabar antes de empezar; ofrecer esas fechas solo
      // llevaría al usuario a un error que el dominio va a rechazar igual.
      firstDate: inicio,
      // Finalizar registra una salida que ya ocurrió, así que el futuro no se
      // ofrece. La aplicación lo rechaza igualmente.
      lastDate: hoy,
      helpText: 'Fecha de fin',
    );
    if (!mounted || fechaFin == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Finalizar contrato'),
        content: Text(
          'El contrato terminará el ${_fecha(fechaFin)}.\n\n'
          'Se conservará el historial de cuotas y pagos correspondiente hasta '
          'esa fecha. El historial no se pierde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmado != true) return;

    try {
      await widget.dependencias.finalizarContrato.ejecutar(
        contratoId: contrato.id,
        fechaFin: fechaFin,
        hoy: hoy,
      );
      if (!mounted) return;
      _recargar();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeDeError(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contratos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoContrato,
        icon: const Icon(Icons.add),
        label: const Text('Contrato'),
      ),
      body: FutureBuilder<_Listado>(
        future: _listado,
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

          final listado = snapshot.data!;
          if (listado.contratos.isEmpty) {
            return const _SinContratos();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: listado.contratos.length,
            itemBuilder: (context, indice) {
              final contrato = listado.contratos[indice];
              return _FilaDeContrato(
                contrato: contrato,
                habitacion: listado.habitacionDe(contrato),
                inquilino: listado.inquilinoDe(contrato),
                alAbrir: () => _abrirHistorial(contrato),
                alFinalizar: () => _finalizar(contrato),
              );
            },
          );
        },
      ),
    );
  }
}

String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

class _FilaDeContrato extends StatelessWidget {
  final Contrato contrato;
  final String habitacion;
  final String inquilino;
  final VoidCallback alAbrir;
  final VoidCallback alFinalizar;

  const _FilaDeContrato({
    required this.contrato,
    required this.habitacion,
    required this.inquilino,
    required this.alAbrir,
    required this.alFinalizar,
  });

  @override
  Widget build(BuildContext context) {
    // Activo o finalizado lo dice el contrato, que lo deriva de su fecha de fin.
    final activo = contrato.estaActivo;
    final colores = Theme.of(context).colorScheme;

    return ListTile(
      onTap: alAbrir,
      leading: Icon(
        activo ? Icons.description : Icons.description_outlined,
        color: activo ? colores.primary : colores.outline,
      ),
      title: Text('$habitacion · $inquilino'),
      subtitle: Text(
        activo
            ? 'Activo · ${contrato.montoMensual} al mes · desde '
                  '${_fecha(contrato.fechaInicio)}'
            : 'Finalizado · ${contrato.montoMensual} al mes · '
                  '${_fecha(contrato.fechaInicio)} — '
                  '${_fecha(contrato.fechaFin!)}',
      ),
      isThreeLine: true,
      // Finalizar solo tiene sentido en un contrato vigente. El estado del
      // finalizado ya lo dice el subtítulo, así que no lleva nada aquí.
      trailing: activo
          ? IconButton(
              icon: const Icon(Icons.event_busy),
              tooltip: 'Finalizar',
              onPressed: alFinalizar,
            )
          : null,
    );
  }
}

class _SinContratos extends StatelessWidget {
  const _SinContratos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no hay contratos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea uno sobre una habitación disponible para empezar a '
              'controlar los cobros.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
