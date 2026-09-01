import 'package:flutter/material.dart';

import '../composicion.dart';
import 'contratos/pantalla_contratos.dart';
import 'cuotas/pantalla_cuotas.dart';
import 'dashboard/pantalla_dashboard.dart';
import 'habitaciones/pantalla_habitaciones.dart';
import 'inquilinos/pantalla_inquilinos.dart';

/// Navegación de primer nivel: una barra inferior con los cinco sitios a los
/// que se llega desde cualquier parte.
///
/// Guarda **solo** el índice seleccionado y construye la pantalla que le
/// corresponde. No conserva vivas las demás: cada una carga sus datos al
/// entrar, así que volver a una pestaña la muestra al día después de haber
/// cobrado o creado algo en otra. Mantenerlas montadas obligaría a inventar un
/// mecanismo para avisarlas de que sus datos ya no valen.
///
/// El precio es perder la posición del scroll al cambiar de pestaña, asumido
/// para el MVP.
class NavegacionPrincipal extends StatefulWidget {
  final Dependencias dependencias;

  const NavegacionPrincipal({super.key, required this.dependencias});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indice = 0;

  /// Cada pantalla trae su propio `Scaffold` con su barra superior y sus
  /// acciones; aquí solo se elige cuál se muestra.
  Widget _pantallaActual() {
    final dependencias = widget.dependencias;
    return switch (_indice) {
      0 => PantallaDashboard(dependencias: dependencias),
      1 => PantallaCuotas(dependencias: dependencias),
      2 => PantallaContratos(dependencias: dependencias),
      3 => PantallaHabitaciones(dependencias: dependencias),
      _ => PantallaInquilinos(dependencias: dependencias),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallaActual(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (indice) => setState(() => _indice = indice),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Cuotas',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Contratos',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Habitaciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Inquilinos',
          ),
        ],
      ),
    );
  }
}
