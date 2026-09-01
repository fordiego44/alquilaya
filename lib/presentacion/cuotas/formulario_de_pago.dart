import 'package:flutter/material.dart';

import '../../aplicacion/cuotas/listar_cuotas_para_cobro.dart';
import '../../aplicacion/pagos/registrar_pago.dart';
import '../../dominio/entidades/cuota.dart';
import '../comun/mensajes.dart';
import '../comun/soles.dart';

/// Registro del pago de una cuota concreta, la que se eligió en el listado.
///
/// No busca ni ofrece cuotas: llega decidida, y con ella a quién se le cobra.
/// Se cierra devolviendo el `Pago` creado, o `null` si el usuario se echó atrás.
///
/// El importe pendiente viene precargado como comodidad, pero el campo es
/// editable a propósito: si lo que se escribe no salda la cuota exactamente,
/// quien lo rechaza es `Cuota.validarPago` a través de `RegistrarPago` (reglas
/// 10 y 11). Esta pantalla no comprueba parciales ni sobrepagos, ni da una
/// cuota por pagada: eso se deriva de los pagos guardados.
class FormularioDePago extends StatefulWidget {
  final CuotaParaCobro cuotaParaCobro;
  final RegistrarPago registrarPago;

  const FormularioDePago({
    super.key,
    required this.cuotaParaCobro,
    required this.registrarPago,
  });

  @override
  State<FormularioDePago> createState() => _FormularioDePagoState();
}

class _FormularioDePagoState extends State<FormularioDePago> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _monto;

  DateTime _fechaPago = _hoy();
  bool _guardando = false;

  /// El día de hoy sin hora: la fecha de pago es una fecha de calendario.
  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  @override
  void initState() {
    super.initState();
    // Se precarga el pendiente ya escrito, en centavos enteros, para que el
    // caso normal sea pulsar Cobrar sin teclear nada.
    final centavos = widget.cuotaParaCobro.cuota.montoPendiente.centavos;
    _monto = TextEditingController(
      text: '${centavos ~/ 100}.${(centavos % 100).toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaPago,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Fecha del pago',
    );
    if (!mounted || elegida == null) return;
    setState(() => _fechaPago = elegida);
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    // El validador ya comprobó que el texto es un importe escribible.
    final monto = dineroDesdeTexto(_monto.text)!;

    setState(() => _guardando = true);
    try {
      final pago = await widget.registrarPago.ejecutar(
        cuotaId: widget.cuotaParaCobro.cuota.cuota.id,
        monto: monto,
        fechaPago: _fechaPago,
      );
      if (mounted) Navigator.pop(context, pago);
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
    final paraCobro = widget.cuotaParaCobro;
    final cuota = paraCobro.cuota;
    final colores = Theme.of(context).colorScheme;

    // El estado llega ya derivado; aquí solo se elige cómo nombrarlo.
    final (etiqueta, color) = switch (cuota.estado) {
      EstadoCuota.pagada => ('Pagada', colores.primary),
      EstadoCuota.vencida => ('Vencida', colores.error),
      EstadoCuota.pendiente => ('Pendiente', colores.outline),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // A quién se le cobra, lo primero que hay que saber al abrir esto.
            Text(
              'Cobrar a ${paraCobro.nombreInquilino}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(paraCobro.nombreHabitacion),
            if (paraCobro.telefono != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: colores.outline),
                  const SizedBox(width: 6),
                  Text('Tel. ${paraCobro.telefono}'),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cuota de ${cuota.cuota.periodo}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fecha de cobro: '
                      '${_fecha(cuota.cuota.fechaVencimiento)}',
                    ),
                    Text('Importe de la cuota: ${cuota.cuota.monto}'),
                    Text('Pendiente: ${cuota.montoPendiente}'),
                    const SizedBox(height: 8),
                    Text(etiqueta, style: TextStyle(color: color)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _monto,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto del pago',
                prefixText: 'S/ ',
                border: OutlineInputBorder(),
              ),
              // Solo se comprueba que sea un importe escribible. Que salde la
              // cuota exactamente lo decide el dominio.
              validator: (valor) => dineroDesdeTexto(valor ?? '') == null
                  ? 'Escribe un importe, por ejemplo 350.50'
                  : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colores.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              leading: const Icon(Icons.event),
              title: const Text('Fecha del pago'),
              subtitle: Text(_fecha(_fechaPago)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _elegirFecha,
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
                        color: colores.onPrimary,
                      ),
                    )
                  : const Text('Cobrar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _fecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
