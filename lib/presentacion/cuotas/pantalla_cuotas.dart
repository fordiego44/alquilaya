import 'package:flutter/material.dart';

import '../../aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import '../../composicion.dart';
import '../../dominio/entidades/cuota.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';
import 'formulario_de_pago.dart';

/// Las cuotas de toda la vivienda, para saber qué toca cobrar y a quién.
///
/// El estado de cada cuota, su pendiente y el inquilino y la habitación a los
/// que corresponde los da `ListarCuotasParaCobro`. Esta pantalla no calcula ni
/// cruza nada: filtra pidiéndole al caso de uso las de un estado concreto, y
/// pinta lo que recibe.
///
/// Tampoco pone al día la cartera: generar cuotas es una operación explícita
/// que ocurre al arrancar y al refrescar el panel.
class PantallaCuotas extends StatefulWidget {
  final Dependencias dependencias;

  const PantallaCuotas({super.key, required this.dependencias});

  @override
  State<PantallaCuotas> createState() => _PantallaCuotasState();
}

class _PantallaCuotasState extends State<PantallaCuotas> {
  /// `null` significa "todas": es lo que espera `ListarCuotasParaCobro`.
  EstadoCuota? _filtro;

  late Future<List<CuotaParaCobro>> _cuotas;

  @override
  void initState() {
    super.initState();
    _cuotas = _consultar();
  }

  Future<List<CuotaParaCobro>> _consultar() {
    final ahora = DateTime.now();
    return widget.dependencias.listarCuotasParaCobro.ejecutar(
      // Que una cuota esté vencida depende del día en que se mire.
      hoy: DateTime(ahora.year, ahora.month, ahora.day),
      estado: _filtro,
    );
  }

  void _recargar() {
    setState(() {
      _cuotas = _consultar();
    });
  }

  void _cambiarFiltro(EstadoCuota? estado) {
    setState(() {
      _filtro = estado;
      _cuotas = _consultar();
    });
  }

  Future<void> _cobrar(CuotaParaCobro cuota) async {
    final pago = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioDePago(
          cuotaParaCobro: cuota,
          registrarPago: widget.dependencias.registrarPago,
        ),
      ),
    );

    if (!mounted) return;
    if (pago != null) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuotas')),
      body: Column(
        children: [
          _Filtros(seleccionado: _filtro, alCambiar: _cambiarFiltro),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<CuotaParaCobro>>(
              future: _cuotas,
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

                final cuotas = snapshot.data ?? const [];
                if (cuotas.isEmpty) {
                  return _SinCuotas(filtro: _filtro);
                }

                return ListView.builder(
                  itemCount: cuotas.length,
                  itemBuilder: (context, indice) => _FilaDeCuota(
                    cuota: cuotas[indice],
                    alCobrar: () => _cobrar(cuotas[indice]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

/// Cada opción pide al caso de uso las cuotas de ese estado; el filtrado no se
/// repite aquí.
class _Filtros extends StatelessWidget {
  final EstadoCuota? seleccionado;
  final ValueChanged<EstadoCuota?> alCambiar;

  const _Filtros({required this.seleccionado, required this.alCambiar});

  @override
  Widget build(BuildContext context) {
    const opciones = <(String, EstadoCuota?)>[
      ('Todas', null),
      ('Pendientes', EstadoCuota.pendiente),
      ('Vencidas', EstadoCuota.vencida),
      ('Pagadas', EstadoCuota.pagada),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final (etiqueta, estado) in opciones)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(etiqueta),
                selected: seleccionado == estado,
                onSelected: (_) => alCambiar(estado),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaDeCuota extends StatelessWidget {
  final CuotaParaCobro cuota;
  final VoidCallback alCobrar;

  const _FilaDeCuota({required this.cuota, required this.alCobrar});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final estilos = Theme.of(context).textTheme;
    final derivada = cuota.cuota;

    final (etiqueta, color, icono) = switch (derivada.estado) {
      EstadoCuota.pagada => ('Pagada', colores.primary, Icons.check_circle),
      EstadoCuota.vencida => ('Vencida', colores.error, Icons.error_outline),
      EstadoCuota.pendiente => ('Pendiente', colores.outline, Icons.schedule),
    };

    // Una cuota ya pagada no admite otro pago (regla 11), así que ni se ofrece.
    final pagada = derivada.estado == EstadoCuota.pagada;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icono, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lo primero: a quién hay que cobrarle y dónde vive.
                Text(
                  '${cuota.nombreInquilino} · ${cuota.nombreHabitacion}',
                  style: estilos.titleMedium,
                ),
                const SizedBox(height: 2),
                Text('${derivada.cuota.periodo} · ${derivada.cuota.monto}'),
                Text(
                  'Fecha de cobro: ${_fecha(derivada.cuota.fechaVencimiento)} '
                  '· $etiqueta',
                  style: estilos.bodySmall?.copyWith(color: color),
                ),
                if (cuota.telefono != null)
                  Text(
                    'Tel. ${cuota.telefono}',
                    style: estilos.bodySmall,
                  ),
                if (!pagada)
                  Text(
                    'Debe ${derivada.montoPendiente}',
                    style: estilos.bodyMedium,
                  ),
              ],
            ),
          ),
          if (!pagada) ...[
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: alCobrar,
              child: const Text('Cobrar'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SinCuotas extends StatelessWidget {
  final EstadoCuota? filtro;

  const _SinCuotas({required this.filtro});

  @override
  Widget build(BuildContext context) {
    final texto = switch (filtro) {
      EstadoCuota.pendiente => 'No hay cuotas pendientes.',
      EstadoCuota.vencida => 'No hay cuotas vencidas. Todo al día.',
      EstadoCuota.pagada => 'Todavía no hay cuotas pagadas.',
      null => 'Todavía no hay cuotas. Crea un contrato para generarlas.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(texto, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
