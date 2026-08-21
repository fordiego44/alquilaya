/// Fuente de identificadores para las entidades que se registran.
///
/// Existe como puerto para que el formato del id sea una decisión del
/// adaptador —todavía sin tomar— y no acabe inventándolo quien llama a los
/// casos de uso. En los tests se sustituye por un generador secuencial, lo que
/// hace deterministas los ids.
abstract interface class GeneradorDeId {
  Future<String> nuevoId();
}
