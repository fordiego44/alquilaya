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
- Pagos **pendientes**.
- Pagos **vencidos**.
- **Próximos vencimientos**.
- **Historial** (por habitación, por contrato o por inquilino).

### Dashboard
- Resumen del estado: habitaciones ocupadas/disponibles, cobros del período, deuda acumulada.

## 5. Reglas de negocio

Reglas que el dominio debe garantizar:

1. Una habitación **no puede tener dos contratos activos simultáneamente**.
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
para que "próximos vencimientos" tenga algo que mostrar. Volver a ejecutar la puesta al día **no duplica** cuotas.
Un contrato finalizado no genera cuotas con vencimiento posterior a su fecha de fin.

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
las reglas de dominio**. El dominio define los puertos; la infraestructura los implementa cuando exista una
decisión.

## 8. Glosario

- **Día base de cobro**: día del mes en que vencen las cuotas de un contrato. Es el día de su fecha de inicio.
- **Cuota**: obligación mensual de pago generada por un contrato para un período concreto.
- **Pago**: entrega de dinero que salda una cuota por su importe íntegro.
- **Monto pendiente**: importe que falta para saldar una cuota. En el MVP es el monto completo de la cuota, o cero
  si ya está pagada.
- **Vencida**: cuota cuya fecha de vencimiento ya pasó y que no está pagada.
- **Pendiente**: cuota aún no pagada cuya fecha de vencimiento no ha pasado.
- **Contrato activo**: contrato vigente, sin fecha de finalización registrada.
