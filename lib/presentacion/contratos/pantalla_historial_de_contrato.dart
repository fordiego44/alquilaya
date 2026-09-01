import 'package:flutter/material.dart';

import '../../aplicacion/contratos/consultar_historial_de_contrato.dart';
import '../../aplicacion/cuotas/cuota_con_estado.dart';
import '../../composicion.dart';
import '../../dominio/entidades/cuota.dart';
import '../../dominio/entidades/pago.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';

/// Historial completo de un contrato: qué se debía, qué se pagó y cuándo.
///
/// Es **de solo lectura**. Cobrar se hace desde la pantalla de cuotas y
/// finalizar desde el listado de contratos; repetir esas acciones aquí solo
/// daría dos caminos para lo mismo.
///
/// Todo sale de una única llamada a `ConsultarHistorialDeContrato`: el estado
/// de cada cuota y su monto pendiente vienen ya derivados, así que esta
/// pantalla no consulta repositorios ni recalcula nada.
class PantallaHistorialDeContrato extends StatefulWidget {
  final Dependencias dependencias;
  final String contratoId;

  const PantallaHistorialDeContrato({
    super.key,
    required this.dependencias,
    required this.contratoId,
  });

  @override
  State<PantallaHistorialDeContrato> createState() =>
      _PantallaHistorialDeContratoState();
}

class _PantallaHistorialDeContratoState
    extends State<PantallaHistorialDeContrato> {
  late Future<HistorialDeContrato> _historial;

  @override
  void initState() {
    super.initState();
    _historial = _consultar();
  }

  Future<HistorialDeContrato> _consultar() {
    final ahora = DateTime.now();
    return widget.dependencias.consultarHistorialDeContrato.ejecutar(
      contratoId: widget.contratoId,
      // El estado de una cuota depende del día en que se mire.
      hoy: DateTime(ahora.year, ahora.month, ahora.day),
    );
  }

  void _recargar() {
    setState(() {
      _historial = _consultar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: FutureBuilder<HistorialDeContrato>(
        future: _historial,
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

          final historial = snapshot.data!;
          // Para decir a qué mes corresponde cada pago.
          final periodos = {
            for (final c in historial.cuotas) c.cuota.id: '${c.cuota.periodo}',
          };

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Resumen(historial),
              const Divider(height: 1),
              _Titulo('Cuotas (${historial.cuotas.length})'),
              if (historial.cuotas.isEmpty)
                const _Vacio('Este contrato todavía no tiene cuotas.')
              else
                for (final cuota in historial.cuotas) _FilaDeCuota(cuota),
              const Divider(height: 1),
              _Titulo('Pagos (${historial.pagos.length})'),
              if (historial.pagos.isEmpty)
                const _Vacio('Todavía no se ha registrado ningún pago.')
              else
                for (final pago in historial.pagos)
                  _FilaDePago(pago: pago, periodo: periodos[pago.cuotaId]),
            ],
          );
        },
      ),
    );
  }
}

String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

/// Cabecera con los datos del contrato y si sigue vigente.
class _Resumen extends StatelessWidget {
  final HistorialDeContrato historial;

  const _Resumen(this.historial);

  @override
  Widget build(BuildContext context) {
    final contrato = historial.contrato;
    final activo = contrato.estaActivo;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${contrato.montoMensual} al mes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            activo
                ? 'Activo desde el ${_fecha(contrato.fechaInicio)}'
                : 'Finalizado · ${_fecha(contrato.fechaInicio)} — '
                      '${_fecha(contrato.fechaFin!)}',
          ),
          Text('Se cobra cada día ${contrato.diaBaseDeCobro} del mes'),
        ],
      ),
    );
  }
}

class _FilaDeCuota extends StatelessWidget {
  final CuotaConEstado cuota;

  const _FilaDeCuota(this.cuota);

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    // El estado ya viene derivado de los pagos y de la fecha; aquí solo se
    // elige cómo pintarlo.
    final (etiqueta, color, icono) = switch (cuota.estado) {
      EstadoCuota.pagada => ('Pagada', colores.primary, Icons.check_circle),
      EstadoCuota.vencida => ('Vencida', colores.error, Icons.error_outline),
      EstadoCuota.pendiente => (
        'Pendiente',
        colores.outline,
        Icons.schedule,
      ),
    };

    return ListTile(
      leading: Icon(icono, color: color),
      title: Text('${cuota.cuota.periodo} · ${cuota.cuota.monto}'),
      subtitle: Text(
        'Fecha de cobro: ${_fecha(cuota.cuota.fechaVencimiento)} · $etiqueta',
      ),
      trailing: cuota.estado == EstadoCuota.pagada
          ? null
          : Text(
              'Debe ${cuota.montoPendiente}',
              style: TextStyle(color: color),
            ),
    );
  }
}

class _FilaDePago extends StatelessWidget {
  final Pago pago;
  final String? periodo;

  const _FilaDePago({required this.pago, required this.periodo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.payments_outlined),
      title: Text('${pago.monto}'),
      subtitle: Text(
        periodo == null
            ? 'Pagado el ${_fecha(pago.fechaPago)}'
            : 'Cuota de $periodo · pagado el ${_fecha(pago.fechaPago)}',
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;

  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String texto;

  const _Vacio(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        texto,
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}
