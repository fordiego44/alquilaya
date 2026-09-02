import '../../aplicacion/excepciones.dart';

/// Convierte un error en algo que se le pueda enseñar a una persona.
///
/// Los errores esperables ya tienen tipo propio, así que se distinguen por él y
/// nunca leyendo su texto. Lo que no encaje en ninguno se trata como un fallo
/// técnico y recibe un mensaje genérico: el usuario no tiene por qué ver el
/// nombre de una excepción, una tabla ni una traza.
///
/// A propósito no se importa nada de infraestructura. Un error de la base de
/// datos cae en el caso general y se comunica sin mencionar SQLite, de modo que
/// la interfaz sigue sin conocer cómo se guardan las cosas.
String mensajeDeError(Object error) => switch (error) {
  // Reglas de negocio comprobadas contra el almacén.
  HabitacionOcupada() => 'Esa habitación ya tiene un contrato activo.',

  // Eliminar es físico: solo cabe para lo que nunca se usó. El mensaje ofrece
  // la salida correcta en vez de dejar al usuario adivinando.
  HabitacionConContratos() =>
    'Esa habitación tiene contratos. Archívala para conservar el historial.',
  InquilinoConContratos() =>
    'Ese inquilino tiene contratos. Archívalo para conservar el historial.',

  // Archivar sí es posible, pero no mientras alguien viva allí.
  HabitacionConContratoActivo() =>
    'Esa habitación tiene un contrato activo. Finalízalo antes de archivarla.',
  InquilinoConContratoActivo() =>
    'Ese inquilino tiene un contrato activo. Finalízalo antes de archivarlo.',

  // Finalizar significa que la salida ya ocurrió.
  FechaDeFinFutura() => 'No puedes finalizar un contrato en una fecha futura.',

  // Un invariante roto, no un fallo pasajero: reintentar no lo arregla, así que
  // el mensaje no lo sugiere.
  ReferenciaInconsistente() =>
    'Hay un problema con los datos guardados. No se pudo cargar la '
        'información de cobranza.',

  // Alguien borró o cambió algo mientras la pantalla estaba abierta.
  HabitacionNoEncontrada() => 'Esa habitación ya no existe.',
  InquilinoNoEncontrado() => 'Ese inquilino ya no existe.',
  ContratoNoEncontrado() => 'Ese contrato ya no existe.',
  CuotaNoEncontrada() => 'Esa cuota ya no existe.',

  // El dominio rechaza la operación por el estado de la entidad: una cuota ya
  // pagada, un contrato ya finalizado. No se muestra su `message` porque lleva
  // dentro el id interno de la entidad, que al usuario no le dice nada. Ambos
  // casos significan lo mismo de cara a quien mira la pantalla: lo que ve ya no
  // corresponde con lo guardado.
  StateError() =>
    'La operación ya no es posible porque los datos cambiaron. '
        'Actualiza la pantalla.',

  // Validaciones del dominio: monto que no cuadra con el pendiente, nombre
  // vacío, fecha de fin anterior al inicio. Se usa `message` y no `toString()`,
  // que añadiría el envoltorio "Invalid argument (campo): … : valor".
  ArgumentError() => '${error.message}',

  _ => 'No se pudo completar la operación. Inténtalo de nuevo.',
};
