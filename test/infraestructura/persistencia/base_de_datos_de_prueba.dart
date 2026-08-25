import 'package:alquilaya/infraestructura/persistencia/base_de_datos.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Registra la implementación de SQLite para la VM de escritorio.
///
/// `sqflite` es un plugin: en un dispositivo lo resuelve la plataforma, pero
/// `flutter test` corre fuera de ella. `sqflite_common_ffi` aporta el motor
/// nativo y solo hace falta aquí, por eso es una dependencia de desarrollo.
///
/// Llamar desde un `setUpAll`. Es idempotente.
void inicializarSqliteParaTests() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Base efímera, distinta en cada llamada: los tests no se ven entre sí y no
/// dejan ficheros. Para comprobar que los datos sobreviven a un cierre hace
/// falta un fichero de verdad, no esto.
Future<Database> abrirBaseEnMemoria() =>
    abrirBaseDeDatos(ruta: inMemoryDatabasePath);
