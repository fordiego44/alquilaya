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

### Inquilinos
- Registrar y editar inquilinos.

### Contratos
- Crear un contrato de alquiler sobre una habitación disponible.
- Establecer el **monto mensual**.
- El **día de cobro** queda fijado por la fecha de inicio; no se introduce por separado.
- Registrar el **pago inicial** de la primera cuota en el mismo acto de creación (regla 9).
- **Finalizar** un contrato conservando su historial (regla 12).

### Cuotas y pagos
- Generar y controlar las cuotas mensuales del contrato.
- Registrar el pago de una cuota, siempre por su importe completo.

### Consultas
- Cuotas **pendientes**.
- Cuotas **vencidas**.
- **Próximos vencimientos**.
- **Historial** por contrato.

*Pendiente* y *vencida* son estados de la **cuota**, no del pago: se derivan de sus pagos y de la fecha actual, de
modo que la misma cuota se lee distinta en fechas distintas.

**Próximos vencimientos** no es una consulta aparte: son las cuotas **pendientes ordenadas por fecha de
vencimiento**. La capa de aplicación no impone ventana temporal ni cantidad máxima; devuelve la serie completa y
es el consumidor quien decide cuántas mostrar.

Las tres consultas son de **solo lectura**: `ListarCuotas`, `ListarContratos` y `ConsultarHistorialDeContrato` no
generan ni persisten cuotas. Consultar el estado de la vivienda nunca modifica la serie: leer una lista de deuda
no puede tener el efecto secundario de crear las cuotas que faltaban.

### Dashboard
- Resumen del estado: habitaciones ocupadas/disponibles, cobros del período, deuda acumulada.

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

**No hay infraestructura seleccionada y no debe seleccionarse todavía.**

Opciones consideradas para el futuro:

- `Flutter -> REST -> Spring Boot -> PostgreSQL`
- `Flutter -> Supabase -> PostgreSQL`
- Almacenamiento local como punto de partida

Requisito arquitectónico derivado: la aplicación debe permitir **sustituir el adaptador de persistencia sin tocar
las reglas de dominio**.

Para lograrlo, el acceso a datos ocurre siempre a través de **puertos**, con estas reglas de ubicación:

- Un puerto se define **en la capa que lo necesita**, junto a sus consumidores; no por defecto en el dominio.
- Los puertos de **persistencia y orquestación** viven en `lib/aplicacion/puertos/`, porque sus únicos
  consumidores son los casos de uso.
- Un puerto puede **extender a otro más estrecho** cuando el mismo adaptador sirve a ambos, de modo que quien
  solo necesita la consulta no dependa de la escritura. Caso real: `RepositorioDeContratos` extiende
  `ContratosActivos`, así que la ocupación de una habitación se responde siempre desde los contratos realmente
  guardados.
- La **infraestructura** futura implementará esos puertos; ninguna capa interna conoce a sus implementaciones.
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

## 8. Glosario

- **Día base de cobro**: día del mes en que vencen las cuotas de un contrato. Es el día de su fecha de inicio.
- **Cuota**: obligación mensual de pago generada por un contrato para un período concreto.
- **Pago**: entrega de dinero que salda una cuota por su importe íntegro.
- **Monto pendiente**: importe que falta para saldar una cuota. En el MVP es el monto completo de la cuota, o cero
  si ya está pagada.
- **Vencida**: cuota cuya fecha de vencimiento ya pasó y que no está pagada.
- **Pendiente**: cuota aún no pagada cuya fecha de vencimiento no ha pasado.
- **Contrato activo**: contrato vigente, sin fecha de finalización registrada.
