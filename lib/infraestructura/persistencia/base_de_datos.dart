import 'package:sqflite/sqflite.dart';

/// Versión del esquema. Se incrementa cuando cambia la forma de las tablas.
const int versionDelEsquema = 1;

/// Abre —creándola si hace falta— la base de datos local en [ruta].
///
/// La ruta llega desde fuera a propósito: calcularla es cosa de quien conoce la
/// plataforma. La app usará el directorio de documentos; los tests, un fichero
/// temporal o `inMemoryDatabasePath`. Así la infraestructura no depende de
/// `path_provider` y sigue siendo ejecutable en la VM de escritorio.
///
/// En Android e iOS `sqflite` funciona tal cual. En Windows, Linux y macOS hace
/// falta registrar la factory de `sqflite_common_ffi` antes de llamar aquí; hoy
/// solo lo hacen los tests, que es donde se usa ese paquete.
Future<Database> abrirBaseDeDatos({required String ruta}) => openDatabase(
  ruta,
  version: versionDelEsquema,
  onConfigure: _configurar,
  onCreate: _crearEsquema,
);

/// Las claves foráneas no están activas por defecto en SQLite: hay que pedirlas
/// en cada conexión.
Future<void> _configurar(Database db) =>
    db.execute('PRAGMA foreign_keys = ON');

/// Crea el esquema **más reciente** de una sola vez.
///
/// Una instalación nueva nunca ejecuta `onUpgrade`, así que este método tiene
/// que quedarse siempre al día: cuando el esquema cambie hay que subir
/// [versionDelEsquema], añadir la rama correspondiente en un `onUpgrade` que
/// migre las bases ya instaladas **y** actualizar también estas sentencias. Los
/// dos caminos —instalación nueva y actualización— deben terminar en el mismo
/// esquema.
///
/// Mientras la app no esté distribuida no hay bases que migrar: el esquema se
/// puede seguir cambiando dentro de la v1 borrando la base local.
Future<void> _crearEsquema(Database db, int version) async {
  // Las restricciones que viven aquí son estructurales: claves, obligatoriedad
  // y relaciones. Las reglas de negocio —monto positivo, un solo contrato
  // activo por habitación, pago exacto, conservación al finalizar— se quedan en
  // el dominio y la aplicación, que ya las implementan; repetirlas como CHECK
  // las pondría en dos sitios que se desincronizarían.
  await db.execute('''
    CREATE TABLE habitaciones (
      id      TEXT PRIMARY KEY,
      nombre  TEXT NOT NULL
    )
  ''');

  // documento y telefono admiten NULL: es como el dominio representa "no se
  // conoce". Nunca cadena vacía.
  await db.execute('''
    CREATE TABLE inquilinos (
      id         TEXT PRIMARY KEY,
      nombre     TEXT NOT NULL,
      documento  TEXT,
      telefono   TEXT
    )
  ''');

  // fecha_fin NULL es lo que hace activo a un contrato. El predicado no se
  // escribe en SQL: quien pregunta usa `Contrato.estaActivo`.
  await db.execute('''
    CREATE TABLE contratos (
      id                      TEXT PRIMARY KEY,
      habitacion_id           TEXT NOT NULL REFERENCES habitaciones(id),
      inquilino_id            TEXT NOT NULL REFERENCES inquilinos(id),
      fecha_inicio            TEXT NOT NULL,
      monto_mensual_centavos  INTEGER NOT NULL,
      fecha_fin               TEXT
    )
  ''');

  // El período se guarda en dos enteros y no como texto: es exactamente lo que
  // `Periodo` contiene, y así vuelve sin parsear nada.
  await db.execute('''
    CREATE TABLE cuotas (
      id                 TEXT PRIMARY KEY,
      contrato_id        TEXT NOT NULL REFERENCES contratos(id),
      periodo_anio       INTEGER NOT NULL,
      periodo_mes        INTEGER NOT NULL,
      monto_centavos     INTEGER NOT NULL,
      fecha_vencimiento  TEXT NOT NULL
    )
  ''');

  // La FK contra cuotas respalda la regla 12 —nunca se elimina una cuota con
  // pagos— convirtiendo un incumplimiento en un error inmediato.
  await db.execute('''
    CREATE TABLE pagos (
      id              TEXT PRIMARY KEY,
      cuota_id        TEXT NOT NULL REFERENCES cuotas(id),
      monto_centavos  INTEGER NOT NULL,
      fecha_pago      TEXT NOT NULL
    )
  ''');
}
