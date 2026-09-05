import 'dart:async';

import 'package:flutter/material.dart';

import '../../composicion.dart';
import '../navegacion_principal.dart';
import 'pantalla_login.dart';

/// Decide qué se ve: la app o el login.
///
/// Es un `StatefulWidget` con suscripción propia y no un `StreamBuilder` porque
/// el estado inicial no viene del stream. `haySesion` ya sabe si hay sesión al
/// montar —el cliente restaura la guardada—, mientras que el stream solo avisa
/// de los cambios. Con `StreamBuilder` habría que elegir entre un
/// `initialData` que se contradice con el primer evento o un parpadeo del login
/// en cada arranque con sesión válida.
class PuertaDeAutenticacion extends StatefulWidget {
  final Dependencias dependencias;

  const PuertaDeAutenticacion({super.key, required this.dependencias});

  @override
  State<PuertaDeAutenticacion> createState() => _PuertaDeAutenticacionState();
}

class _PuertaDeAutenticacionState extends State<PuertaDeAutenticacion> {
  late bool _haySesion;
  StreamSubscription<bool>? _suscripcion;

  @override
  void initState() {
    super.initState();
    final autenticacion = widget.dependencias.autenticacion;
    _haySesion = autenticacion.haySesion;
    _suscripcion = autenticacion.cambiosDeSesion.listen((haySesion) {
      if (mounted) setState(() => _haySesion = haySesion);
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _haySesion
      ? NavegacionPrincipal(dependencias: widget.dependencias)
      : PantallaLogin(autenticacion: widget.dependencias.autenticacion);
}
