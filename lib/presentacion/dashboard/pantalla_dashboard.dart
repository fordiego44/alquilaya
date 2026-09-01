import 'package:flutter/material.dart';

import '../../aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import '../../aplicacion/dashboard/consultar_dashboard.dart';
import '../../composicion.dart';
import '../../dominio/entidades/cuota.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';

/// Panel de inicio: el estado de la vivienda de un vistazo.
///
/// Todas las cifras salen de una sola llamada a `ConsultarDashboard`, que las
/// agrega. La pantalla no consulta otros casos de uso ni recompone métricas por
/// su cuenta.
///
/// Consultar no genera cuotas. Ponerlas al día es una operación aparte, y aquí
/// solo ocurre cuando el usuario pulsa refrescar: primero se actualiza, después
/// se consulta.
class PantallaDashboard extends StatefulWidget {
  final Dependencias dependencias;

  const PantallaDashboard({super.key, required this.dependencias});

  @override
  State<PantallaDashboard> createState() => _PantallaDashboardState();
}

class _PantallaDashboardState extends State<PantallaDashboard> {
  late Future<ResumenDelDashboard> _resumen;
  bool _refrescando = false;

  @override
  void initState() {
    super.initState();
    _resumen = _consultar();
  }

  /// El día de hoy sin hora: de él dependen la deuda vencida y los próximos
  /// cobros.
  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  Future<ResumenDelDashboard> _consultar() =>
      widget.dependencias.consultarDashboard.ejecutar(hoy: _hoy());

  void _recargar() {
    setState(() {
      _resumen = _consultar();
    });
  }

  /// Pone la cartera al día y vuelve a consultar, en ese orden y de forma
  /// explícita.
  Future<void> _refrescar() async {
    if (_refrescando) return;
    setState(() => _refrescando = true);

    Object? falloAlActualizar;
    try {
      await widget.dependencias.actualizarCuotas.ejecutar(hoy: _hoy());
    } catch (error) {
      falloAlActualizar = error;
    }

    if (!mounted) return;
    setState(() {
      _refrescando = false;
      // Se consulta igual: si la puesta al día falló, el panel sigue siendo
      // válido con las cuotas que ya existían.
      _resumen = _consultar();
    });

    if (falloAlActualizar != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeDeError(falloAlActualizar))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlquilaYa'),
        actions: [
          IconButton(
            icon: _refrescando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Actualizar cuotas',
            onPressed: _refrescando ? null : _refrescar,
          ),
        ],
      ),
      body: FutureBuilder<ResumenDelDashboard>(
        future: _resumen,
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

          final resumen = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Cifra(
                      titulo: 'Ocupadas',
                      valor: '${resumen.habitacionesOcupadas}',
                      icono: Icons.meeting_room,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Cifra(
                      titulo: 'Disponibles',
                      valor: '${resumen.habitacionesDisponibles}',
                      icono: Icons.meeting_room_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Cifra(
                titulo: 'Cobrado en ${resumen.periodo}',
                valor: '${resumen.cobrosDelPeriodo}',
                icono: Icons.payments_outlined,
              ),
              const SizedBox(height: 12),
              _Cifra(
                titulo: 'Deuda vencida',
                valor: '${resumen.deudaVencida}',
                icono: Icons.account_balance_wallet_outlined,
                destacarValor: resumen.deudaVencida.esPositivo,
              ),
              const SizedBox(height: 24),
              Text(
                'Próximos cobros',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (resumen.proximosCobros.isEmpty)
                Text(
                  'No hay cobros próximos.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                )
              else
                // La lista llega ordenada por fecha de cobro y ya filtrada a lo
                // que aún no toca cobrar: se muestra tal cual.
                for (final cuota in resumen.proximosCobros)
                  _FilaDeVencimiento(cuota),
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

class _Cifra extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final bool destacarValor;

  const _Cifra({
    required this.titulo,
    required this.valor,
    required this.icono,
    this.destacarValor = false,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: colores.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: destacarValor ? colores.error : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDeVencimiento extends StatelessWidget {
  final CuotaParaCobro cuota;

  const _FilaDeVencimiento(this.cuota);

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final derivada = cuota.cuota;
    final color = switch (derivada.estado) {
      EstadoCuota.pagada => colores.primary,
      EstadoCuota.vencida => colores.error,
      EstadoCuota.pendiente => colores.outline,
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(Icons.schedule, color: color),
      // A quién cobrar, lo primero: el panel se mira de un vistazo.
      title: Text('${cuota.nombreInquilino} · ${cuota.nombreHabitacion}'),
      subtitle: Text(
        cuota.telefono == null
            ? 'Cobrar el ${_fecha(derivada.cuota.fechaVencimiento)} · '
                  'Debe ${derivada.montoPendiente}'
            : 'Cobrar el ${_fecha(derivada.cuota.fechaVencimiento)} · '
                  'Debe ${derivada.montoPendiente}\nTel. ${cuota.telefono}',
      ),
    );
  }
}
