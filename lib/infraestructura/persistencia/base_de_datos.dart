import 'package:sqflite/sqflite.dart';

/// Versión del esquema. Se incrementa cuando cambia la forma de las tablas.
///
/// La v2 añadió el archivado de habitaciones e inquilinos.
const int versionDelEsquema = 2;

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
  onUpgrade: _migrar,
);

/// Las claves foráneas no están activas por defecto en SQLite: hay que pedirlas
/// en cada conexión.
Future<void> _configurar(Database db) =>
    db.execute('PRAGMA foreign_keys = ON');

/// Crea el esquema **más reciente** de una sola vez.
///
/// Una instalación nueva nunca ejecuta `onUpgrade`, así que este método tiene
/// que quedarse siempre al día: cuando el esquema cambie hay que subir
/// [versionDelEsquema], añadir la rama correspondiente en [_migrar] **y**
/// actualizar también estas sentencias. Los dos caminos —instalación nueva y
/// actualización— deben terminar en el mismo esquema.
Future<void> _crearEsquema(Database db, int version) async {
  // Las restricciones que viven aquí son estructurales: claves, obligatoriedad
  // y relaciones. Las reglas de negocio —monto positivo, un solo contrato
  // activo por habitación, pago exacto, conservación al finalizar— se quedan en
  // el dominio y la aplicación, que ya las implementan; repetirlas como CHECK
  // las pondría en dos sitios que se desincronizarían.
  await db.execute('''
    CREATE TABLE habitaciones (
      id         TEXT PRIMARY KEY,
      nombre     TEXT NOT NULL,
      archivada  INTEGER NOT NULL DEFAULT 0
    )
  ''');

  // documento y telefono admiten NULL: es como el dominio representa "no se
  // conoce". Nunca cadena vacía.
  await db.execute('''
    CREATE TABLE inquilinos (
      id         TEXT PRIMARY KEY,
      nombre     TEXT NOT NULL,
      documento  TEXT,
      telefono   TEXT,
      archivado  INTEGER NOT NULL DEFAULT 0
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

/// Pone al día una base **ya instalada** hasta [versionDelEsquema].
///
/// Un bloque por salto, en orden y sin `else`: una base en v1 los recorre todos
/// hasta quedar al día. Cuando exista una v3 se añade aquí su propio
/// `if (versionAnterior < 3)` sin tocar los anteriores.
Future<void> _migrar(Database db, int versionAnterior, int versionNueva) async {
  if (versionAnterior < 2) {
    // `ADD COLUMN` con DEFAULT rellena las filas que ya existen sin reescribir
    // la tabla ni tocar sus claves foráneas: lo que había queda como activo.
    await db.execute(
      'ALTER TABLE habitaciones '
      'ADD COLUMN archivada INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE inquilinos '
      'ADD COLUMN archivado INTEGER NOT NULL DEFAULT 0',
    );
  }
}
