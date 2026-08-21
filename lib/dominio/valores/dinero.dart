/// Importe monetario expresado en centavos enteros.
///
/// Nunca se usa punto flotante: las sumas de cuotas, pagos y deuda deben
/// cuadrar al céntimo. La conversión entre lo que el usuario escribe ("350.50")
/// y este valor interno (35050) ocurre en la interfaz, no aquí.
class Dinero implements Comparable<Dinero> {
  final int centavos;

  const Dinero._(this.centavos);

  /// Crea un importe. Rechaza negativos: no existe el dinero negativo en este
  /// dominio. El cero sí es válido (el monto pendiente de una cuota saldada).
  factory Dinero(int centavos) {
    if (centavos < 0) {
      throw ArgumentError.value(centavos, 'centavos', 'No puede ser negativo');
    }
    return Dinero._(centavos);
  }

  static const Dinero cero = Dinero._(0);

  bool get esPositivo => centavos > 0;

  Dinero operator +(Dinero otro) => Dinero(centavos + otro.centavos);

  /// Resta. Lanza si el resultado sería negativo.
  Dinero operator -(Dinero otro) => Dinero(centavos - otro.centavos);

  bool operator <(Dinero otro) => centavos < otro.centavos;
  bool operator <=(Dinero otro) => centavos <= otro.centavos;
  bool operator >(Dinero otro) => centavos > otro.centavos;
  bool operator >=(Dinero otro) => centavos >= otro.centavos;

  @override
  int compareTo(Dinero otro) => centavos.compareTo(otro.centavos);

  @override
  bool operator ==(Object other) =>
      other is Dinero && other.centavos == centavos;

  @override
  int get hashCode => centavos.hashCode;

  @override
  String toString() {
    final unidades = centavos ~/ 100;
    final resto = (centavos % 100).toString().padLeft(2, '0');
    return 'S/ $unidades.$resto';
  }
}
