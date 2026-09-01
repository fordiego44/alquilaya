import 'package:flutter/material.dart';

import '../../aplicacion/habitaciones/estado_de_ocupacion.dart';
import '../../composicion.dart';
import '../../dominio/entidades/habitacion.dart';
import '../../dominio/entidades/inquilino.dart';
import '../comun/error_con_reintento.dart';
import '../comun/mensajes.dart';
import '../comun/soles.dart';

/// Lo que hay que elegir para crear un contrato: sobre qué habitación y a quién.
class _Opciones {
  final List<Habitacion> disponibles;
  final List<Inquilino> inquilinos;

  const _Opciones(this.disponibles, this.inquilinos);
}

/// Alta de un contrato. Se cierra devolviendo el contrato creado, o `null` si
/// el usuario se echó atrás.
///
/// Solo recoge datos y llama a `CrearContrato`. En particular **no** genera la
/// primera cuota ni registra el pago inicial: eso es la regla 9 y la aplica el
/// caso de uso. Tampoco vuelve a mirar si una habitación está ocupada; se
/// ofrecen las que `ListarHabitaciones` da por disponibles, y si aun así la
/// regla 1 se incumpliera —porque alguien creó otro contrato entretanto—, el
/// error llega de `CrearContrato` y se muestra.
class FormularioDeContrato extends StatefulWidget {
  final Dependencias dependencias;

  const FormularioDeContrato({super.key, required this.dependencias});

  @override
  State<FormularioDeContrato> createState() => _FormularioDeContratoState();
}

class _FormularioDeContratoState extends State<FormularioDeContrato> {
  final _formulario = GlobalKey<FormState>();
  final _monto = TextEditingController();

  late Future<_Opciones> _opciones;

  String? _habitacionId;
  String? _inquilinoId;
  DateTime _fechaInicio = _hoy();
  bool _guardando = false;

  /// El día de hoy sin hora. El dominio trabaja con fechas de calendario y
  /// `showDatePicker` ya devuelve una así; arrancar con `DateTime.now()` a
  /// secas metería hora y microsegundos en la fecha de inicio del contrato.
  static DateTime _hoy() {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  @override
  void initState() {
    super.initState();
    _opciones = _consultar();
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<_Opciones> _consultar() async {
    final habitaciones = await widget.dependencias.listarHabitaciones.ejecutar();
    final inquilinos = await widget.dependencias.listarInquilinos.ejecutar();

    // La ocupación ya viene resuelta en el listado; aquí solo se filtra.
    final disponibles = [
      for (final listada in habitaciones)
        if (listada.estado == EstadoDeOcupacion.disponible) listada.habitacion,
    ];
    return _Opciones(disponibles, inquilinos);
  }

  void _recargar() {
    setState(() {
      _opciones = _consultar();
    });
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Fecha de inicio',
    );
    if (!mounted || elegida == null) return;
    setState(() => _fechaInicio = elegida);
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    // El validador ya comprobó que el texto es un importe escribible.
    final montoMensual = dineroDesdeTexto(_monto.text)!;

    setState(() => _guardando = true);
    try {
      final contrato = await widget.dependencias.crearContrato.ejecutar(
        habitacionId: _habitacionId!,
        inquilinoId: _inquilinoId!,
        fechaInicio: _fechaInicio,
        montoMensual: montoMensual,
      );
      if (mounted) Navigator.pop(context, contrato);
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
      appBar: AppBar(title: const Text('Nuevo contrato')),
      body: FutureBuilder<_Opciones>(
        future: _opciones,
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

          final opciones = snapshot.data!;
          if (opciones.disponibles.isEmpty) {
            return const _FaltaAlgo(
              icono: Icons.meeting_room_outlined,
              titulo: 'No hay habitaciones disponibles',
              detalle:
                  'Todas están ocupadas. Registra otra habitación o finaliza '
                  'un contrato antes de crear uno nuevo.',
            );
          }
          if (opciones.inquilinos.isEmpty) {
            return const _FaltaAlgo(
              icono: Icons.people_outline,
              titulo: 'Todavía no hay inquilinos',
              detalle: 'Registra a un inquilino para poder crear el contrato.',
            );
          }

          return _formularioCon(opciones);
        },
      ),
    );
  }

  Widget _formularioCon(_Opciones opciones) {
    return Form(
      key: _formulario,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _habitacionId,
            decoration: const InputDecoration(
              labelText: 'Habitación',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final habitacion in opciones.disponibles)
                DropdownMenuItem(
                  value: habitacion.id,
                  child: Text(habitacion.nombre),
                ),
            ],
            onChanged: (valor) => setState(() => _habitacionId = valor),
            validator: (valor) =>
                valor == null ? 'Elige una habitación' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _inquilinoId,
            decoration: const InputDecoration(
              labelText: 'Inquilino',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final inquilino in opciones.inquilinos)
                DropdownMenuItem(
                  value: inquilino.id,
                  child: Text(inquilino.nombre),
                ),
            ],
            onChanged: (valor) => setState(() => _inquilinoId = valor),
            validator: (valor) => valor == null ? 'Elige un inquilino' : null,
          ),
          const SizedBox(height: 16),
          // La fecha de inicio fija además el día de cobro de todas las cuotas.
          ListTile(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            leading: const Icon(Icons.event),
            title: const Text('Fecha de inicio'),
            subtitle: Text(
              '${_fechaInicio.day.toString().padLeft(2, '0')}/'
              '${_fechaInicio.month.toString().padLeft(2, '0')}/'
              '${_fechaInicio.year}  ·  se cobrará cada día '
              '${_fechaInicio.day}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _elegirFecha,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _monto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto mensual',
              prefixText: 'S/ ',
              hintText: '350.50',
              border: OutlineInputBorder(),
            ),
            // Solo se comprueba que sea un importe escribible. Que además sea
            // positivo es la regla 2, y la aplica el dominio.
            validator: (valor) => dineroDesdeTexto(valor ?? '') == null
                ? 'Escribe un importe, por ejemplo 350.50'
                : null,
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
                : const Text('Crear contrato'),
          ),
          const SizedBox(height: 8),
          Text(
            'Al crear el contrato se registra el pago de la primera cuota.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Falta un requisito para poder crear el contrato.
class _FaltaAlgo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;

  const _FaltaAlgo({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(detalle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
