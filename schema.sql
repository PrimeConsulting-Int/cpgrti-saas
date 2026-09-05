-- Consola CPGRTI — esquema Supabase (Postgres) para la versión SaaS multi-tenant.
-- Ejecutar completo en el SQL Editor de tu proyecto Supabase (Project > SQL Editor > New query).

-- 1) Organizaciones (cada banco/cliente = un tenant)
create table if not exists organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

-- 2) Perfiles: vincula cada usuario autenticado (auth.users) a una organización y un rol
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  org_id uuid not null references organizations(id) on delete cascade,
  full_name text,
  role text not null default 'miembro' check (role in ('admin','ciso','cio','oficial_riesgo','miembro')),
  created_at timestamptz not null default now()
);

-- 3) Estado de la aplicación por organización (v1: un solo documento JSON por tenant,
--    igual a lo que hoy vive en localStorage — riesgos, incidentes, indicadores, etc.)
create table if not exists org_data (
  org_id uuid primary key references organizations(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

-- Función auxiliar: org_id del usuario autenticado actual (evita subconsultas repetidas en las políticas RLS)
create or replace function auth_org_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select org_id from profiles where id = auth.uid()
$$;

-- 4) Row Level Security: cada usuario solo ve/edita los datos de su propia organización
alter table organizations enable row level security;
alter table profiles enable row level security;
alter table org_data enable row level security;

-- organizations: cualquier usuario autenticado puede crear una organización nueva (alta de cliente);
-- solo puede leer/actualizar la suya
create policy "org: crear" on organizations
  for insert to authenticated
  with check (true);

create policy "org: leer la propia" on organizations
  for select to authenticated
  using (id = auth_org_id());

create policy "org: actualizar la propia" on organizations
  for update to authenticated
  using (id = auth_org_id());

-- profiles: cada usuario gestiona únicamente su propio perfil;
-- además puede ver los perfiles de sus compañeros de organización (para futura gestión de equipo)
create policy "profile: crear el propio" on profiles
  for insert to authenticated
  with check (id = auth.uid());

create policy "profile: leer de mi organización" on profiles
  for select to authenticated
  using (org_id = auth_org_id() or id = auth.uid());

create policy "profile: actualizar el propio" on profiles
  for update to authenticated
  using (id = auth.uid());

-- org_data: solo miembros de la organización pueden leer/escribir su documento
create policy "org_data: leer de mi organización" on org_data
  for select to authenticated
  using (org_id = auth_org_id());

create policy "org_data: crear el de mi organización" on org_data
  for insert to authenticated
  with check (org_id = auth_org_id());

create policy "org_data: actualizar el de mi organización" on org_data
  for update to authenticated
  using (org_id = auth_org_id());

-- Nota de evolución (v2): cuando varias personas editen el mismo registro de riesgos en simultáneo,
-- conviene migrar org_data (un JSON gigante) a tablas normalizadas por entidad (risks, incidentes,
-- indicadores, controles, proveedores) para permitir ediciones concurrentes por fila en vez de por documento.
