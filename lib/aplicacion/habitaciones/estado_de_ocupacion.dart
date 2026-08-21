/// Estado de ocupación de una habitación.
///
/// Es siempre un valor **derivado** de la existencia de un contrato activo:
/// nunca se guarda ni se edita. Se modela como enum y no como `bool` para que
/// las firmas digan qué significan y para poder crecer sin cambiarlas.
enum EstadoDeOcupacion { disponible, ocupada }
