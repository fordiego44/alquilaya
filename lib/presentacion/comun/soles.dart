import '../../dominio/valores/dinero.dart';

/// Lo que el usuario escribe ("350.50") convertido a [Dinero] (35050 centavos).
///
/// Para **mostrar** un importe no hay nada aquí: `Dinero.toString()` ya produce
/// `S/ 350.50`, así que la interfaz lo interpola tal cual.
///
/// La conversión es entera de principio a fin. En ningún punto aparece un
/// `double`: convertir "350.50" a coma flotante y multiplicar por 100 puede dar
/// 35049,999… y perder un céntimo.

final _soloDigitos = RegExp(r'^\d+$');

/// Devuelve `null` si [texto] no es un importe escribible.
///
/// Comprueba **solo el formato**: que haya dígitos, un único separador y como
/// mucho dos decimales. Si el importe debe ser positivo, o coincidir con el
/// pendiente de una cuota, lo decide el dominio cuando reciba el valor; aquí
/// se acepta el cero como escritura válida.
///
/// El separador decimal puede llegar como punto o como coma, según el teclado
/// del dispositivo, y ambos significan lo mismo.
Dinero? dineroDesdeTexto(String texto) {
  final normalizado = texto.trim().replaceAll(',', '.');
  if (normalizado.isEmpty) return null;

  final partes = normalizado.split('.');
  if (partes.length > 2) return null;

  final enteros = partes.first;
  if (!_soloDigitos.hasMatch(enteros)) return null;

  // Sin separador son cero céntimos; con él tiene que haber uno o dos dígitos.
  // "350." se considera a medio escribir, no un importe.
  var decimales = '';
  if (partes.length == 2) {
    decimales = partes.last;
    if (decimales.isEmpty ||
        decimales.length > 2 ||
        !_soloDigitos.hasMatch(decimales)) {
      return null;
    }
  }

  // "350.5" son cincuenta céntimos, no cinco.
  final centavosDecimales = decimales.padRight(2, '0');

  final unidades = int.tryParse(enteros);
  if (unidades == null) return null;

  return Dinero(unidades * 100 + int.parse(centavosDecimales));
}
