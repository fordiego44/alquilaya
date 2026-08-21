/// Mes y año al que corresponde una cuota. No conoce días.
class Periodo implements Comparable<Periodo> {
  final int anio;
  final int mes;

  Periodo(this.anio, this.mes) {
    if (mes < 1 || mes > 12) {
      throw ArgumentError.value(mes, 'mes', 'Debe estar entre 1 y 12');
    }
  }

  Periodo.deFecha(DateTime fecha) : anio = fecha.year, mes = fecha.month;

  Periodo siguiente() =>
      mes == 12 ? Periodo(anio + 1, 1) : Periodo(anio, mes + 1);

  Periodo anterior() =>
      mes == 1 ? Periodo(anio - 1, 12) : Periodo(anio, mes - 1);

  /// Meses transcurridos desde [otro] hasta este período. Negativo si este
  /// período es anterior.
  int mesesDesde(Periodo otro) => (anio - otro.anio) * 12 + (mes - otro.mes);

  @override
  int compareTo(Periodo otro) => mesesDesde(otro);

  @override
  bool operator ==(Object other) =>
      other is Periodo && other.anio == anio && other.mes == mes;

  @override
  int get hashCode => Object.hash(anio, mes);

  @override
  String toString() => '$anio-${mes.toString().padLeft(2, '0')}';
}
