-- Esquema inicial de AlquilaYa.
--
-- Traslada a PostgreSQL el modelo que hoy vive en SQLite
-- (lib/infraestructura/persistencia/base_de_datos.dart) añadiendo lo que aquel
-- no podía tener: propiedad por usuario y aislamiento entre cuentas.
--
-- Los identificadores siguen siendo TEXT, no UUID: el dominio Dart los trata
-- como String y los datos existentes en SQLite se migrarán tal cual.
--
-- Los importes se guardan en centavos como BIGINT, igual que `Dinero`. No hay
-- NUMERIC ni redondeo: el dominio ya trabaja en enteros.
--
-- Las fechas usan DATE y no TIMESTAMP: el dominio compara siempre por día
-- (`Cuota._soloDia`) y no conoce horas ni zonas horarias.

-- ---------------------------------------------------------------------------
-- Tablas
-- ---------------------------------------------------------------------------

-- El estado ocupada/disponible no se almacena: se deriva de la existencia de un
-- contrato activo, como hace `ConsultarOcupacionDeHabitacion`.
create table public.habitaciones (
  id text primary key,
  usuario_id uuid not null default auth.uid()
    references auth.users (id) on delete restrict,
  nombre text not null,
  archivada boolean not null default false,

  constraint habitaciones_usuario_id_key unique (usuario_id, id),
  constraint habitaciones_id_no_vacio check (btrim(id) <> ''),
  constraint habitaciones_nombre_no_vacio check (btrim(nombre) <> '')
);

-- documento y telefono admiten NULL: es como el dominio representa "no se
-- conoce". Nunca cadena vacía ni en blanco.
create table public.inquilinos (
  id text primary key,
  usuario_id uuid not null default auth.uid()
    references auth.users (id) on delete restrict,
  nombre text not null,
  documento text,
  telefono text,
  archivado boolean not null default false,

  constraint inquilinos_usuario_id_key unique (usuario_id, id),
  constraint inquilinos_id_no_vacio check (btrim(id) <> ''),
  constraint inquilinos_nombre_no_vacio check (btrim(nombre) <> ''),
  constraint inquilinos_documento_no_vacio
    check (documento is null or btrim(documento) <> ''),
  constraint inquilinos_telefono_no_vacio
    check (telefono is null or btrim(telefono) <> '')
);

-- fecha_fin NULL es lo que hace activo a un contrato, igual que
-- `Contrato.estaActivo`. El día de cobro se deriva de fecha_inicio
-- (`Contrato.diaBaseDeCobro`), por eso no hay columna propia.
--
-- Las claves foráneas incluyen usuario_id para que una fila jamás pueda
-- apuntar a datos de otra cuenta, aunque el id coincidiera.
create table public.contratos (
  id text primary key,
  usuario_id uuid not null default auth.uid()
    references auth.users (id) on delete restrict,
  habitacion_id text not null,
  inquilino_id text not null,
  fecha_inicio date not null,
  monto_mensual_centavos bigint not null,
  fecha_fin date,

  constraint contratos_usuario_id_key unique (usuario_id, id),
  constraint contratos_habitacion_fkey
    foreign key (usuario_id, habitacion_id)
    references public.habitaciones (usuario_id, id) on delete restrict,
  constraint contratos_inquilino_fkey
    foreign key (usuario_id, inquilino_id)
    references public.inquilinos (usuario_id, id) on delete restrict,
  constraint contratos_id_no_vacio check (btrim(id) <> ''),
  constraint contratos_habitacion_id_no_vacio check (btrim(habitacion_id) <> ''),
  constraint contratos_inquilino_id_no_vacio check (btrim(inquilino_id) <> ''),
  constraint contratos_monto_positivo check (monto_mensual_centavos > 0),
  constraint contratos_fecha_fin_posterior
    check (fecha_fin is null or fecha_fin >= fecha_inicio)
);

-- El período se guarda en dos enteros y no como texto: es exactamente lo que
-- contiene `Periodo`, y así vuelve sin parsear nada.
create table public.cuotas (
  id text primary key,
  usuario_id uuid not null default auth.uid()
    references auth.users (id) on delete restrict,
  contrato_id text not null,
  periodo_anio integer not null,
  periodo_mes integer not null,
  monto_centavos bigint not null,
  fecha_vencimiento date not null,

  constraint cuotas_usuario_id_key unique (usuario_id, id),
  constraint cuotas_contrato_fkey
    foreign key (usuario_id, contrato_id)
    references public.contratos (usuario_id, id) on delete restrict,
  -- `ActualizarCuotasDeContrato` genera una cuota por período; el UNIQUE impide
  -- que dos ejecuciones concurrentes creen la misma dos veces.
  constraint cuotas_periodo_unico
    unique (usuario_id, contrato_id, periodo_anio, periodo_mes),
  constraint cuotas_id_no_vacio check (btrim(id) <> ''),
  constraint cuotas_contrato_id_no_vacio check (btrim(contrato_id) <> ''),
  constraint cuotas_periodo_mes_valido check (periodo_mes between 1 and 12),
  constraint cuotas_monto_positivo check (monto_centavos > 0)
);

-- Una cuota se salda con un único pago exacto (`Cuota.validarPago`), de ahí el
-- UNIQUE sobre cuota_id. Si algún día se admiten pagos parciales, se retira.
create table public.pagos (
  id text primary key,
  usuario_id uuid not null default auth.uid()
    references auth.users (id) on delete restrict,
  cuota_id text not null,
  monto_centavos bigint not null,
  fecha_pago date not null,

  constraint pagos_usuario_id_key unique (usuario_id, id),
  constraint pagos_cuota_fkey
    foreign key (usuario_id, cuota_id)
    references public.cuotas (usuario_id, id) on delete restrict,
  constraint pagos_cuota_unica unique (usuario_id, cuota_id),
  constraint pagos_id_no_vacio check (btrim(id) <> ''),
  constraint pagos_cuota_id_no_vacio check (btrim(cuota_id) <> ''),
  constraint pagos_monto_positivo check (monto_centavos > 0)
);

-- Una habitación no puede tener dos contratos activos a la vez. Es la regla que
-- `CrearContrato` comprueba antes de insertar; el índice la hace cumplir también
-- ante dos inserciones simultáneas. Parcial porque solo restringe los activos:
-- el histórico de contratos finalizados sobre la misma habitación es ilimitado.
create unique index contratos_activo_por_habitacion_idx
  on public.contratos (usuario_id, habitacion_id)
  where fecha_fin is null;

-- ---------------------------------------------------------------------------
-- Seguridad
-- ---------------------------------------------------------------------------

alter table public.habitaciones enable row level security;
alter table public.inquilinos enable row level security;
alter table public.contratos enable row level security;
alter table public.cuotas enable row level security;
alter table public.pagos enable row level security;

-- Sin sesión no hay nada que ver: la app no expone datos públicos.
revoke all on public.habitaciones from anon;
revoke all on public.inquilinos from anon;
revoke all on public.contratos from anon;
revoke all on public.cuotas from anon;
revoke all on public.pagos from anon;

grant select, insert, update, delete on public.habitaciones to authenticated;
grant select, insert, update, delete on public.inquilinos to authenticated;
grant select, insert, update, delete on public.contratos to authenticated;
grant select, insert, update, delete on public.cuotas to authenticated;
grant select, insert, update, delete on public.pagos to authenticated;

-- Una política por operación en lugar de FOR ALL: así cada permiso se puede
-- ajustar por separado sin reescribir el resto.
--
-- `(select auth.uid())` y no `auth.uid()` a secas: envuelto en subconsulta el
-- planificador lo evalúa una vez por consulta y no una vez por fila.
--
-- UPDATE lleva USING y WITH CHECK: el primero decide qué filas se pueden
-- modificar, el segundo impide que la fila resultante cambie de dueño.

-- habitaciones
create policy habitaciones_select on public.habitaciones
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

create policy habitaciones_insert on public.habitaciones
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

create policy habitaciones_update on public.habitaciones
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create policy habitaciones_delete on public.habitaciones
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

-- inquilinos
create policy inquilinos_select on public.inquilinos
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

create policy inquilinos_insert on public.inquilinos
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

create policy inquilinos_update on public.inquilinos
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create policy inquilinos_delete on public.inquilinos
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

-- contratos
create policy contratos_select on public.contratos
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

create policy contratos_insert on public.contratos
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

create policy contratos_update on public.contratos
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create policy contratos_delete on public.contratos
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

-- cuotas
create policy cuotas_select on public.cuotas
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

create policy cuotas_insert on public.cuotas
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

create policy cuotas_update on public.cuotas
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create policy cuotas_delete on public.cuotas
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);

-- pagos
create policy pagos_select on public.pagos
  for select to authenticated
  using ((select auth.uid()) = usuario_id);

create policy pagos_insert on public.pagos
  for insert to authenticated
  with check ((select auth.uid()) = usuario_id);

create policy pagos_update on public.pagos
  for update to authenticated
  using ((select auth.uid()) = usuario_id)
  with check ((select auth.uid()) = usuario_id);

create policy pagos_delete on public.pagos
  for delete to authenticated
  using ((select auth.uid()) = usuario_id);
