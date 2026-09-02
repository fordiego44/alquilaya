# AlquilaYa — Especificación funcional

Documento funcional del proyecto. No contiene instrucciones para Claude (ver `CLAUDE.md`).

## 1. Problema

El propietario de una vivienda alquila habitaciones y hoy lleva el control **manualmente en un cuaderno**:

- datos del inquilino
- habitación ocupada
- fecha de ingreso
- monto mensual
- fecha en que corresponde cobrar
- pagos realizados

Consecuencias: no hay historial confiable, es fácil perder de vista quién debe, cuánto y desde cuándo, y no
existe una vista consolidada del estado de la vivienda.

**Objetivo:** reemplazar ese proceso manual por una aplicación que mantenga el historial completo y responda con
precisión a "quién debe", "cuánto" y "cuándo vence".

## 2. Modelo conceptual

```
Habitacion
  -> Contrato
      -> Inquilino
      -> Cuota
          -> Pago
```

Lectura del modelo:

- Una **Habitación** tiene a lo largo del tiempo varios **Contratos** (como máximo uno activo a la vez).
- Un **Contrato** vincula una habitación con un **Inquilino** y fija el monto mensual. La **fecha de inicio**
  determina además el día de cobro de todas sus cuotas.
- Un contrato genera **Cuotas** mensuales, cada una con su período, monto y fecha de vencimiento.
- Una cuota se salda mediante un **Pago** por su importe íntegro.

### Historial como requisito, no como efecto secundario

El sistema **no** guarda una simple "próxima fecha de pago". Guarda la serie completa de cuotas, de modo que el
estado de un contrato es siempre reconstruible y auditable:

```
Agosto 2026     - S/ 350 - PAGADO
Septiembre 2026 - S/ 350 - PENDIENTE
Octubre 2026    - S/ 350 - PENDIENTE
```

Esto es lo que permite responder por deudas pasadas, no solo por el próximo cobro.

## 3. Entidades

| Entidad | Responsabilidad | Datos esenciales |
|---|---|---|
| **Habitacion** | Espacio alquilable de la vivienda | identificador/nombre |
| **Inquilino** | Persona que alquila | datos de identificación y contacto |
| **Contrato** | Relación habitación–inquilino en el tiempo | habitación, inquilino, fecha de inicio, monto mensual, fecha de fin |
| **Cuota** | Obligación mensual derivada del contrato | contrato, período (mes/año), monto, fecha de vencimiento |
| **Pago** | Dinero efectivamente recibido | cuota, monto, fecha de pago |

Notas de alcance:

- El **día de cobro no es un dato propio del contrato**: se deriva de la fecha de inicio. Un contrato que empieza
  el 20/08/2026 vence el 20 de cada mes. No existe un día de cobro configurable distinto al de inicio.
- El estado de la **Habitación** (disponible/ocupada) es consecuencia de si existe o no un contrato activo; no es
  un dato que alguien edite.
- El estado de la **Cuota** (pendiente / pagada / vencida) se deriva de sus pagos y de la fecha actual. *Vencida*
  es una condición temporal, no un estado que alguien marque a mano.
- El estado del **Contrato** (activo / finalizado) se deriva de si tiene fecha de fin.
- Conceptualmente una cuota podría recibir varios pagos, pero el MVP aplica **YAGNI**: una cuota se paga de una
  vez y por su importe completo (reglas 10 y 11). `Pago` se mantiene como concepto propio, de modo que admitir
  pagos parciales en el futuro no obligue a rehacer el modelo.

### Importes

Todos los importes se manejan como **centavos enteros** (S/ 350.50 → `35050`), nunca como decimales de punto
flotante. Motivo: las sumas de cuotas, pagos y deuda deben cuadrar al céntimo; con punto flotante el dashboard
llegaría a mostrar totales como `1049.9999999999998`. La conversión entre lo que el usuario escribe y ve
("350.50") y el valor interno ocurre en la interfaz.

## 4. Alcance del MVP

### Habitaciones
- Registrar y editar habitaciones.
- Ver qué habitaciones están **disponibles** y cuáles **ocupadas**.
- **Archivar** y **reactivar** una habitación.
- **Eliminar** físicamente una habitación que nunca tuvo contratos.

### Inquilinos
- Registrar y editar inquilinos.
- **Archivar** y **reactivar** un inquilino.
- **Eliminar** físicamente a un inquilino que nunca tuvo contratos.

### Archivado y eliminación

Retirar una habitación o un inquilino tiene dos formas, y cuál corresponde no lo elige el usuario sino su
historial (reglas 13 y 14):

- **Archivar** conserva la entidad y todo lo que cuelga de ella. Es **reversible**: reactivar la devuelve a las
  opciones disponibles y no tiene condiciones.
- **Eliminar** es físico y definitivo, y **solo se admite si la entidad nunca tuvo contratos**. Basta uno, activo
  o finalizado, para que forme parte del historial y deje de poder borrarse.

Una entidad con **contrato activo** no puede archivarse: primero debe finalizarse el contrato. Eliminarla tampoco
es posible, porque la existencia de ese contrato ya forma parte de su historial. Una vez finalizado, sí puede
archivarse.

Los archivados **no se ofrecen al crear un contrato nuevo**, pero **siguen existiendo**: archivar no elimina
contratos, cuotas ni pagos, y los contratos históricos siguen mostrando a quién y dónde correspondieron.

Ese nombre es el **actual**, no el del momento del contrato: renombrar una habitación o un inquilino cambia
también lo que muestra el historial. Es lo deseable al corregir una errata, y para el caso contrario —una
identidad que de verdad cambia— la salida es archivar la vieja y dar de alta otra. **No se guardan copias
históricas de los nombres**: sería duplicar un dato para un problema que todavía no ha aparecido (YAGNI).

### Contratos
- Crear un contrato de alquiler sobre una habitación disponible.
- Establecer el **monto mensual**.
- El **día de cobro** queda fijado por la fecha de inicio; no se introduce por separado.
- Registrar el **pago inicial** de la primera cuota en el mismo acto de creación (regla 9).
- **Finalizar** un contrato conservando su historial (regla 12).

Finalizar registra una salida que **ya ocurrió**. La fecha de fin puede ser hoy o una fecha pasada —siempre que no
sea anterior al inicio del contrato—, pero **nunca una fecha futura**: la aplicación la rechaza.

El motivo es que el estado del contrato se deriva de si tiene fecha de fin, no de compararla con hoy. Admitir una
fecha futura dejaría la habitación como disponible antes de que el inquilino se haya ido, y permitiría crear otro
contrato solapado sobre ella.

Las **salidas programadas** —anotar por adelantado que un inquilino se marchará— quedan fuera del alcance actual.

### Cuotas y pagos
- Generar y controlar las cuotas mensuales del contrato.
- Registrar el pago de una cuota, siempre por su importe completo.

### Consultas
- Cuotas **pendientes**.
- Cuotas **vencidas**.
- **Próximos cobros**.
- **Historial** por contrato.

*Pendiente* y *vencida* son estados de la **cuota**, no del pago: se derivan de sus pagos y de la fecha actual, de
modo que la misma cuota se lee distinta en fechas distintas.

**Próximos cobros** no es una consulta aparte: son las cuotas **pendientes ordenadas por fecha de cobro**. La capa
de aplicación no impone ventana temporal ni cantidad máxima; devuelve la serie completa y es el consumidor quien
decide cuántas mostrar.

Las tres consultas son de **solo lectura**: `ListarCuotas`, `ListarContratos` y `ConsultarHistorialDeContrato` no
generan ni persisten cuotas. Consultar el estado de la vivienda nunca modifica la serie: leer una lista de deuda
no puede tener el efecto secundario de crear las cuotas que faltaban.

### Dashboard
- Resumen del estado: habitaciones ocupadas/disponibles, cobros del período, deuda vencida y próximos cobros.

Lo resuelve `ConsultarDashboard`, también de **solo lectura**: compone consultas existentes y agrega sus
resultados sin reimplementar reglas de negocio, y **no materializa cuotas**. Si nadie ha ejecutado la puesta al
día, el resumen muestra menos deuda de la real; actualizar sigue siendo una operación explícita y separada.

Qué significa cada cifra:

- **Ocupadas / disponibles**: se cuentan sobre el listado de habitaciones, donde *ocupada* es siempre "tiene un
  contrato activo" (regla 1).
- **Cobros del período**: dinero **recibido** durante ese mes, por **fecha de pago**. Es caja, no devengo: un pago
  tardío de la cuota de agosto realizado en septiembre cuenta como cobro de septiembre. El período es opcional;
  por defecto, el mes de la fecha consultada.
- **Deuda vencida**: la suma de los montos pendientes de las cuotas **vencidas e impagas** de toda la cartera,
  incluida la deuda que la regla 12 conservó de contratos ya finalizados. No incluye lo que aún no toca cobrar:
  mezclarlo haría parecer moroso a un inquilino que está al día.
- **Próximos cobros**: las cuotas **pendientes** ordenadas por fecha de cobro, con el mismo criterio que el resto
  de consultas: sin ventana temporal ni cantidad máxima. Traen además a quién y dónde cobrar, para que el panel
  sirva sin abrir otra pantalla.

Una cuota cuya fecha de cobro **es hoy sigue siendo pendiente**, no vencida: el día del vencimiento aún no cuenta
como vencido (regla 6). Aparece por tanto en *próximos cobros* y no en *deuda vencida*.

Ambas cifras son **excluyentes**: cada cuota cae en un único sitio —vencida, por cobrar o saldada—, de modo que no
hay doble conteo entre la deuda y los próximos cobros.

Las cifras derivadas de la fecha —deuda vencida y próximos cobros— se calculan siempre respecto al día consultado, no
respecto al período: mirar los cobros de un mes pasado no cambia cuánto se debe hoy.

## 5. Reglas de negocio

Reglas de negocio que el sistema debe garantizar:

1. Una habitación **no puede tener dos contratos activos simultáneamente**. La comprobación ocurre al crear un
   contrato, consultando si la habitación ya tiene uno activo.
2. Todo monto (monto mensual, monto de cuota, monto de pago) debe ser **positivo**, y se representa en
   **centavos enteros**.
3. **Finalizar un contrato no elimina su historial**: el contrato, sus cuotas y sus pagos siguen siendo
   consultables.
4. Al finalizar un contrato, su habitación **queda disponible**.
5. Toda cuota tiene una **fecha de vencimiento**.
6. Debe poder determinarse de forma inequívoca **cuándo una cuota está vencida**.
7. Las **reglas de fechas están centralizadas** en un único punto del dominio, no repartidas por la aplicación.
8. Los alquileres se cobran **por adelantado**. La primera cuota corresponde a la misma fecha de inicio del contrato y se paga al momento del ingreso. Los siguientes vencimientos ocurren mensualmente tomando como referencia el día de inicio del contrato.

   Si el día base no existe en determinado mes, el vencimiento se ajusta al **último día de ese mes**, conservando el día base original para los meses siguientes.

   Ejemplo:

   - Inicio del contrato: 31/01/2026
   - Primera cuota: 31/01/2026
   - Siguiente cuota: 28/02/2026
   - Siguiente cuota: 31/03/2026
   - Siguiente cuota: 30/04/2026
   - Siguiente cuota: 31/05/2026

9. Al **crear un contrato** se registra el pago de la primera cuota, por el monto mensual completo y con fecha
   igual a la de inicio. Un contrato recién creado **no queda con su primera cuota pendiente** en el flujo normal.
10. Un pago **salda la cuota entera**: el monto debe ser exactamente igual al **monto pendiente** de la cuota. No
    se admiten **pagos parciales** ni **sobrepagos**.
11. Una cuota **ya pagada no admite otro pago**, aunque el monto sea el correcto.
12. Al **finalizar un contrato** con una fecha de fin determinada:
    - se **conservan** las cuotas con vencimiento **anterior o igual** a la fecha de fin, pagadas o impagas;
    - se **eliminan** las cuotas con vencimiento **posterior** a la fecha de fin que **no tengan pagos**;
    - **nunca** se eliminan pagos, ni cuotas que tengan algún pago.

    La decisión se toma por **fecha de vencimiento**, no por período. Con día base 20 y fin el 15/10/2026, la
    cuota de octubre —que vencía el 20— aún no correspondía y se elimina; la de septiembre, ya vencida e impaga,
    se conserva como deuda.

13. Una habitación o un inquilino con **contrato activo** no puede archivarse. Archivar retira de las opciones
    futuras; hacerlo con un contrato en curso describiría la vivienda en falso.
14. Solo puede **eliminarse físicamente** lo que **nunca tuvo contratos**, activos o finalizados. En cuanto
    existe uno, la entidad pertenece al historial y la única salida es archivarla.
15. El **archivado es un estado explícito y reversible** de la entidad, no un filtro de la interfaz: se guarda,
    sobrevive a la edición y se deshace reactivando.

### Generación de cuotas

Las cuotas se generan de forma **incremental**: desde el mes de inicio hasta el mes actual, más un mes por delante
para que "próximos vencimientos" tenga algo que mostrar. Volver a ejecutar la puesta al día **no duplica** cuotas:
la identidad de una cuota dentro de su contrato es su **período**, de modo que un período que ya tiene cuota no
genera otra. Un contrato finalizado no genera cuotas con vencimiento posterior a su fecha de fin.

**Finalizar un contrato materializa antes las cuotas que le corresponden hasta la fecha de fin**, y solo después
aplica la regla 12. Si no se hiciera así, la deuda vencida de un contrato del que nadie ejecutó la puesta al día
desaparecería sin que nadie la perdonara: la regla 12 decide sobre la serie completa, no sobre las cuotas que
alguien hubiera generado antes.

La puesta al día es una **operación explícita**, nunca un efecto secundario de consultar. Se ejecuta de dos
formas, ambas capaces de materializar cuotas:

- `ActualizarCuotasDeContrato`, sobre un contrato concreto.
- `ActualizarCuotasDeTodosLosContratos`, que recorre la cartera y **procesa únicamente los contratos activos**,
  reutilizando el caso de uso anterior en lugar de repetir las reglas de fechas (regla 7). Un contrato finalizado
  se ignora por completo: sus cuotas hasta la fecha de fin ya las materializó `FinalizarContrato` durante el
  cierre, así que la puesta al día global no tiene nada que reparar ni completar en él.

### Decisiones pendientes

Estas reglas están identificadas pero **no cerradas**; se decidirán cuando toque implementarlas.

- **Prorrateo** de la primera y la última cuota. Hoy se cobra el mes completo, tanto al entrar como al salir, que
  es lo que hace el cuaderno. Se decidirá si el propietario pide medias mensualidades.
- **Modificación del monto mensual durante un contrato vigente**: fuera del MVP salvo indicación contraria.
- **Día de cobro configurable** distinto al de inicio: solo si el negocio llega a requerirlo.

## 6. Fuera de alcance (por ahora)

- Pagos parciales, sobrepagos, saldos y planes de pago.
- Multiusuario, roles y autenticación.
- Recibos, facturación o exportación contable.
- Notificaciones y recordatorios automáticos.
- Gestión de varias viviendas.
- Servicios, gastos comunes o depósitos en garantía.

## 7. Infraestructura

**Persistencia local elegida: SQLite, mediante `sqflite`.** `sqflite_common_ffi` es una dependencia **de
desarrollo** y existe solo para que los tests puedan abrir SQLite fuera de un dispositivo.

El alcance actual es **únicamente local**: los datos viven en el dispositivo y sobreviven al cierre de la
aplicación. No hay backend, API remota ni sincronización, y no se ha elegido ninguno todavía. Siguen sobre la mesa
para más adelante:

- `Flutter -> REST -> Spring Boot -> PostgreSQL`
- `Flutter -> Supabase -> PostgreSQL`

Requisito arquitectónico derivado: la aplicación debe permitir **sustituir el adaptador de persistencia sin tocar
las reglas de dominio**. La elección de SQLite no lo compromete: los repositorios SQLite implementan los puertos
**ya existentes**, y añadirlos no obligó a modificar ni el dominio ni la aplicación.

Para lograrlo, el acceso a datos ocurre siempre a través de **puertos**, con estas reglas de ubicación:

- Un puerto se define **en la capa que lo necesita**, junto a sus consumidores; no por defecto en el dominio.
- Los puertos de **persistencia y orquestación** viven en `lib/aplicacion/puertos/`, porque sus únicos
  consumidores son los casos de uso.
- Un puerto puede **extender a otro más estrecho** cuando el mismo adaptador sirve a ambos, de modo que quien
  solo necesita la consulta no dependa de la escritura. Caso real: `RepositorioDeContratos` extiende
  `ContratosActivos`, así que la ocupación de una habitación se responde siempre desde los contratos realmente
  guardados.
- La **infraestructura** implementa esos puertos, hoy en `lib/infraestructura/persistencia/`; ninguna capa interna
  conoce a sus implementaciones.
- El **dominio** no depende de la aplicación ni de la infraestructura: es el núcleo puro al que apuntan todas las
  dependencias.

Dirección de dependencias:

```
infraestructura
    ↓ implementa
aplicacion/puertos
    ↓ consumidos por
aplicacion (casos de uso)
    ↓ usa
dominio
```

### Esquema local (versión 2)

Cinco tablas, una por entidad: `habitaciones`, `inquilinos`, `contratos`, `cuotas` y `pagos`. Sus columnas salen
una a una de las entidades del dominio; no existe ninguna columna que el dominio no tenga.

Cómo se traduce cada tipo:

| Tipo de dominio | En la base |
|---|---|
| `Dinero` | `INTEGER`, en **centavos** — nunca un `REAL`, así los totales cuadran al céntimo |
| `Periodo` | dos `INTEGER`: año y mes |
| `DateTime` | `TEXT` en **ISO-8601**, con round-trip exacto para las fechas usadas por el dominio |
| id | `TEXT PRIMARY KEY` |
| `bool` | `INTEGER` 0/1 — SQLite no tiene booleano |
| estados derivados | **no se persisten** |

Ni `EstadoCuota` ni el estado de ocupación llegan a la base: son derivados y guardarlos crearía un dato capaz de
contradecir a los pagos o a los contratos.

El **archivado sí se persiste**, porque no es derivado: es un estado propio de la entidad que alguien decide.

```
habitaciones.archivada  INTEGER NOT NULL DEFAULT 0
inquilinos.archivado    INTEGER NOT NULL DEFAULT 0
```

El `DEFAULT 0` es lo que hace que todo lo que ya existía quede **activo**: ni al crear la base ni al migrarla se
archiva nada por su cuenta.

Las relaciones —contrato→habitación, contrato→inquilino, cuota→contrato, pago→cuota— son claves foráneas reales,
activadas con `PRAGMA foreign_keys = ON` en cada conexión.

Esas claves foráneas son además la **última barrera** del borrado: no hay `ON DELETE CASCADE` en ninguna parte, de
modo que la base rechaza eliminar una habitación o un inquilino referenciado por un contrato aunque la regla 14
fallara en comprobarlo. La regla vive en la aplicación, que da el mensaje comprensible; la base la respalda.

**El almacenamiento solo protege la integridad estructural**: claves, obligatoriedad y relaciones. Las reglas de
negocio siguen viviendo exclusivamente en el dominio y la aplicación: monto positivo, un único contrato activo por
habitación, pago exacto sin parciales ni sobrepagos, conservación al finalizar y calendario de vencimientos. No se
traducen a `CHECK` ni a índices únicos: quedarían en dos sitios y se desincronizarían. La clave foránea de `pagos`
no duplica la regla 12, la respalda, convirtiendo un incumplimiento futuro en un error inmediato.

### Escrituras: UPSERT no destructivo

Todos los guardados usan `INSERT ... ON CONFLICT(id) DO UPDATE SET ...`.

**No se usa `INSERT OR REPLACE` ni `ConflictAlgorithm.replace`**: REPLACE resuelve el conflicto *borrando* la fila
existente antes de reinsertarla, y con las claves foráneas activas eso rompe o arrastra las filas hijas. Ocurriría
de verdad en dos sitios: al finalizar un contrato que ya tiene cuotas, y al volver a guardar una cuota que ya
tiene pagos. La invariante es que **actualizar una entidad nunca borra su fila ni pone en riesgo sus relaciones**.

### Transacciones

Las transacciones atómicas **entre varios repositorios quedan fuera del alcance actual**. Los casos de uso que
escriben varias veces —`CrearContrato`, `FinalizarContrato`— validan todo antes de la primera escritura y guardan
de menos a más dependiente, de modo que un fallo intermedio exigiría un error del propio SQLite y dejaría datos
huérfanos recuperables, no inválidos. La aplicación es monousuario y local, sin concurrencia.

El riesgo se acepta a sabiendas: un corte a mitad de una finalización podría dejar un contrato finalizado con
cuotas posteriores sin depurar. Si llega a importar, se diseñará una abstracción de transacción/unidad de trabajo
apoyada en `Database.transaction`, evaluando entonces los cambios mínimos necesarios en el cableado o en los
adaptadores.

### Migraciones

El esquema actual es la **versión 2**. La v1 no tenía el archivado; la v2 lo añadió con una migración real, no
borrando la base local.

`onCreate` **crea directamente la v2**: una instalación nueva no pasa por `onUpgrade`, así que si se quedara atrás
nacería incompleta. `onUpgrade` pone al día las bases ya instaladas, con un bloque por salto y sin `else`, de modo
que una base en v1 los recorre todos:

```sql
-- v1 -> v2
ALTER TABLE habitaciones ADD COLUMN archivada INTEGER NOT NULL DEFAULT 0;
ALTER TABLE inquilinos   ADD COLUMN archivado INTEGER NOT NULL DEFAULT 0;
```

`ADD COLUMN` con `DEFAULT` rellena las filas existentes **sin reescribir la tabla ni tocar sus claves foráneas**:
nada se pierde y nada queda archivado.

Cuando el esquema vuelva a cambiar harán falta las tres cosas a la vez:

1. incrementar `version`;
2. añadir un bloque nuevo en `onUpgrade` —sin tocar los anteriores—, que migra las instalaciones **existentes**;
3. **actualizar también `onCreate`**, que debe crear directamente el esquema más reciente.

`onCreate` describe siempre el esquema vigente, nunca el histórico: una instalación nueva no dispara `onUpgrade`,
así que si se congelara nacería con un esquema antiguo. Los dos caminos —instalación nueva y actualización— tienen
que converger en el mismo esquema.

## 8. Estado actual

Estado validado al **01/09/2026**. Esta sección describe lo que **ya funciona**, no lo planificado.

### Interfaz

El MVP tiene interfaz Flutter funcional, con cinco destinos de navegación y una pantalla de detalle:

- **Inicio / Dashboard** — resumen del estado y puesta al día explícita de cuotas.
- **Cuotas** — listado con su estado y registro de pagos.
- **Contratos** — creación, finalización y acceso al historial.
- **Habitaciones** — registro, edición, estado de ocupación, archivado y borrado, con vistas separadas de
  activas y archivadas.
- **Inquilinos** — registro, edición, datos de contacto, archivado y borrado, con vistas de activos y archivados.
- **Historial de contrato** — cuotas y pagos de un contrato concreto.

### Persistencia local

SQLite funcionando en Android mediante `sqflite`, en la **versión 2** del esquema. **Habitaciones, inquilinos,
contratos, cuotas y pagos persisten** en el dispositivo. Se verificó cerrar por completo la aplicación y volver a
abrirla sin pérdida de datos.

### Migración v1 → v2 verificada

Además del test automatizado —que parte de una base v1 con datos y comprueba el resultado tras reabrirla—, la
migración se verificó **a mano sobre la instalación real del emulador**, que tenía una base v1 con una habitación,
un inquilino y un contrato activo. Tras actualizar la app y arrancarla:

- `user_version` pasó de **1 a 2**;
- las tres filas conservaron **sus mismos ids y datos**;
- las referencias del contrato quedaron intactas y su `fecha_fin` siguió en `NULL`;
- `archivada` y `archivado` quedaron en **0**.

### Flujo validado manualmente

Recorrido completo probado en el emulador Android S24:

1. crear una habitación;
2. crear un inquilino;
3. crear un contrato sobre la habitación disponible;
4. pago inicial por adelantado, registrado en el mismo acto (regla 9);
5. generación de las cuotas mensuales siguientes;
6. registrar un pago;
7. finalizar el contrato;
8. la habitación vuelve a quedar **disponible**;
9. el historial conserva cuotas y pagos (regla 3).

Y sobre esa misma base migrada: editar una habitación y un inquilino, archivarlos y reactivarlos, comprobar que
un contrato activo impide archivar, que el historial impide eliminar, que archivar es posible tras finalizar el
contrato, que los archivados no se ofrecen para contratos nuevos y que los contratos antiguos siguen mostrando
sus nombres.

### Calidad

- `flutter analyze`: **limpio**, sin incidencias.
- `flutter test`: **287 pruebas, todas en verde**.
- Prueba funcional completa realizada en el emulador Android S24, incluida la migración sobre datos reales.

### Límites de esta versión

- **MVP funcional local**: sin backend, sin sincronización remota y sin autenticación.
- Los datos viven **únicamente en el dispositivo**.
- El package Android es `com.example.alquilaya`, el valor por defecto de Flutter. **Debe cambiarse antes de
  cualquier publicación real.**

## 9. Glosario

- **Día base de cobro**: día del mes en que vencen las cuotas de un contrato. Es el día de su fecha de inicio.
- **Cuota**: obligación mensual de pago generada por un contrato para un período concreto.
- **Pago**: entrega de dinero que salda una cuota por su importe íntegro.
- **Monto pendiente**: importe que falta para saldar una cuota. En el MVP es el monto completo de la cuota, o cero
  si ya está pagada.
- **Vencida**: cuota cuya fecha de vencimiento ya pasó y que no está pagada.
- **Pendiente**: cuota aún no pagada cuya fecha de vencimiento no ha pasado.
- **Contrato activo**: contrato vigente, sin fecha de finalización registrada.
