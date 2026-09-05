# Consola CPGRTI — versión SaaS

Versión multi-organización de la Consola de Riesgo Tecnológico: cada banco/cliente entra con su propio
correo y contraseña, y ve únicamente los datos de su organización. Es la misma aplicación de un solo
archivo que ya conoces (`app.html`), a la que se le agregó una capa de autenticación y persistencia en
la nube (Supabase) en lugar de guardar los datos solo en el navegador (localStorage).

No hay nada que compilar: es HTML + JavaScript plano. Lo único que falta para que funcione es un
proyecto Supabase (gratis para este volumen de uso) y un lugar donde alojar estos archivos estáticos.

## 1. Crear el proyecto Supabase (una sola vez)

1. Entra a [supabase.com](https://supabase.com) y crea una cuenta gratuita (tú, no yo — no puedo crear
   cuentas en tu nombre).
2. Crea un **New project** (elige una región cercana a tus clientes, ej. São Paulo).
3. Ve a **SQL Editor > New query**, pega el contenido completo de [`schema.sql`](schema.sql) de esta
   carpeta y ejecútalo (`Run`). Esto crea las tablas `organizations`, `profiles`, `org_data` y las
   políticas de seguridad (cada organización solo ve sus propios datos).
4. (Recomendado para probar rápido) En **Authentication > Providers > Email**, desactiva
   "Confirm email" mientras pruebas, así no dependes de la bandeja de correo para crear tu primera
   cuenta. Actívalo de nuevo antes de dar acceso a clientes reales.
5. Ve a **Project Settings > API** y copia:
   - **Project URL**
   - **anon public key**

## 2. Configurar las credenciales localmente

En esta misma carpeta:

```bash
cp config.example.js config.js
```

Edita `config.js` y pega tu Project URL y tu anon key. Este archivo **no se sube** a ningún repositorio
(ya está en `.gitignore`) porque, aunque la clave "anon" está pensada para ser pública, cada quien maneja
sus propias credenciales por entorno (desarrollo, producción).

## 3. Probar en tu computador

No necesitas nada especial — es un sitio estático. Cualquier servidor HTTP simple sirve, por ejemplo:

```bash
python -m http.server 5500
```

y abre `http://localhost:5500/app.html`. Deberías ver la pantalla de inicio de sesión. Crea tu primera
cuenta ("Crear cuenta"), y al entrar te pedirá el nombre de tu organización — eso crea tu primer tenant.

## 4. Desplegar en producción

La forma más simple y gratuita para este tamaño de proyecto es **Vercel** o **Netlify** (arrastrar la
carpeta o conectar un repositorio de GitHub):

1. Sube esta carpeta a un repositorio de GitHub (recuerda: `config.js` no se sube, está en `.gitignore`).
2. En Vercel/Netlify, crea un proyecto nuevo apuntando a ese repositorio — no requiere build command
   (es HTML estático).
3. Como `config.js` no está en el repositorio, súbelo manualmente al hosting (Vercel: "Deploy" >
   arrastra el archivo; o usa variables de entorno + un pequeño script de build si prefieres no tener el
   archivo suelto — eso ya es una mejora de v2).
4. Configura tu dominio (ej. `riesgo.algerisk.com` o `cpgrti.primeconsultores.com`) en el proveedor de
   hosting.

## Qué incluye esta v1 y qué falta

**Incluido:**
- Login / creación de cuenta por correo y contraseña (Supabase Auth).
- Cada cuenta nueva crea o se une a **una organización** (tenant) — sus datos quedan aislados del resto
  por Row Level Security en la base de datos, no solo por lógica de la aplicación.
- Todo lo que ya hacía la app (identificar, evaluar, tratar, controlar, monitorear, informar riesgos)
  funciona igual, ahora guardado en la nube en vez de en el navegador.
- Varias personas de la misma organización pueden entrar con sus propias cuentas y ver los mismos datos.

**Pendiente para siguientes versiones (no crítico para arrancar):**
- **Invitar compañeros a una organización existente** — hoy cada cuenta nueva crea su propia
  organización; falta un flujo de "unirme a la organización de mi banco" (invitación por correo o código).
- **Roles y permisos reales** — el campo `role` en `profiles` ya existe (admin/ciso/cio/oficial_riesgo/
  miembro) pero la aplicación todavía no restringe acciones según el rol.
- **Edición concurrente fina** — hoy todo el registro de riesgos de una organización se guarda como un
  solo documento; si dos personas editan al mismo tiempo, gana el último guardado. Pasar a tablas
  normalizadas (una fila por riesgo) resuelve esto cuando haga falta.
- **Cobro/suscripción** — no hay integración de pagos. Cuando haya clientes reales pagando, se agrega
  Stripe (u otro) sobre esta misma base de datos (ej. una columna `plan` en `organizations`).
- **Confirmación de correo en producción** — recuerda reactivarla en Supabase antes de dar acceso a
  clientes reales, y personalizar la plantilla de correo con tu marca.
