# Walkthrough: Cambios de Bots, Lógica de Emails de Trial y Sistema de Actualizaciones

Se han completado y verificado con éxito todos los cambios solicitados para los bots Maiko, la lógica de emails de la plataforma de copytrading y el sistema de actualizaciones con alertas visuales en el panel del cliente y correos electrónicos automáticos desde el panel de administración.

## Cambios Realizados

### 1. Bots de Trading (MQL5)
* **Clarificación de Límite de Operaciones:**
  - Se modificaron los comentarios de la variable `LimitePosicionesSOS` en todos los bots a `// Maximo de posiciones SOS (Rescate)`. 
  - Esto actualiza la etiqueta en MetaTrader 5 (que antes decía de forma errónea "Máximo de operaciones abiertas"), aclarando que el valor de configuración representa únicamente el límite de **posiciones de rescate (SOS)**. 
  - Con un valor de `1`, el bot permite: **1 posición inicial (Ataque) + 1 posición de rescate (SOS) = 2 operaciones en total**.
* **CENT Bot (`Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5`):**
  - Parámetros por defecto ajustados: `ProfitCosechaIndividual = 0.06`, `ProfitNetoFlush = 0.25`, `LimitePosicionesSOS = 1` (límite de 2 operaciones en total: 1 ataque + 1 SOS) de fábrica.
  - Corregido el bug del `ESCAPE TP` dividiendo `priceDiff` (centavos) por `multCent` (100) para operar en dólares correctos: `avgPrice + (priceDiff / multCent)`.
  - Añadida la etiqueta `LICENCIA: ACTIVA` en color amarillo al HUD.
* **NORMAL Bot (`Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5`):**
  - Eliminado el input `DiasDeTrial` y la lógica de verificación del trial en `OnInit()`.
  - Actualizado el HUD para mostrar permanentemente `LICENCIA: ACTIVA` en color amarillo.
* **TRIAL Bot (`Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5`):**
  - Añadida una cuenta regresiva dinámica en `OnTick()` para el ciclo de 24 horas y los días restantes de la licencia de prueba.
  - El HUD ahora muestra: `TRIAL: DIA X [HHh MMm]` en color amarillo.
  - Cuando quedan 7 o menos días, se muestra el aviso de expiración en color naranja/rojo: `EXPIRA EN X DIAS [HHh MMm] | ADQUIERE REAL`.
  - Al expirar, muestra `TRIAL EXPIRADO` en color rojo y apaga el bot.
* **Optimización de Frecuencia y Desacople de Ticks (Nuevo):**
  - Se modificó la frecuencia de sincronización de telemetría de 3 segundos a **2 segundos** para una transmisión ultra-rápida.
  - Se cambió la comprobación del temporizador de `TimeCurrent()` a `TimeLocal()` en la función `OnTimer()` de todos los EAs. Esto evita que el bot deje de transmitir datos en fines de semana, días festivos o momentos de baja volatilidad (cuando no llegan nuevos ticks del broker), garantizando un estado "ONLINE" constante en el dashboard de la web.

### 2. Backend de Copytrading & Notificaciones de Expiración
* **Copia en BCC a Sakura:**
  - Todos los correos de Kopytrading (`sendWelcomeEmail`, `sendTrialProgressEmail`, `sendTrialExpiredEmail`) ahora incluyen de forma automatizada `bcc: 'viajaconsakura@gmail.com'` para que el dueño reciba copia de toda la comunicación.
* **Alertas Semanales de Progreso:**
  - Añadido el soporte de emails semanales a:
    - **Semana 1:** 23 días restantes (7 días de operativa).
    - **Semana 2:** 16 días restantes (14 días de operativa).
    - **Semana 3:** 9 días restantes (21 días de operativa).
    - **Semana 4 / Alerta Final:** 2 días restantes (28 días de operativa).
  - Al expirar la cuenta demo (`trialExpirado` o `diasRestantes <= 0`), se envía de inmediato el email de expiración recordando que pueden adquirir el bot Real.
  - Implementados flags persistentes (`warnEmail23Sent`, `warnEmail16Sent`, `warnEmail9Sent`, `warnEmail2Sent`, `expireEmailSent`) en los settings del bot para evitar envíos duplicados.

### 3. Sistema de Actualizaciones de Bots y Notificaciones por Correo
* **Notificación de Versión (`src/lib/email.ts`):**
  - Se implementó la función `sendVersionUpdateEmail` que construye una plantilla premium de correo electrónico (estilo oscuro/glassmorphism a tono con KopyTrading).
  - Incluye detalles específicos de la nueva versión, enlace al dashboard del cliente, e instrucciones paso a paso para actualizar el archivo `.EX5` en MetaTrader 5 sin interferir con las licencias vigentes.
* **API de Administración (`src/app/api/admin/bots/route.ts`):**
  - **`GET`**: Ahora expone el catálogo completo de productos de bots en base de datos para cargarlos en los selectores dinámicos del panel de administración.
  - **`PUT`**: Permite actualizar en base de datos la versión del producto (y opcionalmente las rutas de descarga del `.EX5` y manual `.PDF`). Si el checkbox de notificaciones está activo (`sendEmails: true`), busca a todos los usuarios con licencias válidas de ese bot (`Purchase` con estado `COMPLETED`), remueve duplicados de correo y les envía de forma secuencial la notificación de actualización.
* **Indicador en Catálogo General (`src/components/DashboardContainer.tsx`):**
  - Al cargar el panel principal, si un bot del usuario tiene una versión de telemetría (`runningVersion`) o de descarga anterior a la versión oficial del servidor (`botProduct.version`), la mini-tarjeta se resalta con un borde ámbar/dorado difuminado y muestra un badge parpadeante: `ACTUALIZAR vX.XX ⚠️`.
* **Detalle del Bot (`src/components/BotCard.tsx`):**
  - Dentro de la vista detallada del bot, se muestra un banner informativo muy visible de color ámbar que indica la versión actual de su terminal frente a la disponible en el servidor.
  - El botón "🤖 DESCARGAR BOT (.EX5)" se ilumina en ámbar con un destello para guiar al usuario a obtener la última versión.
* **Pestaña "Actualizar Versión" (`src/app/admin/page.tsx`):**
  - Se incorporó la pestaña "🔔 Actualizar Versión" al panel de administrador.
  - Selector dinámico de bots activos: Al seleccionar un bot, autocompila los campos de versión y rutas actuales en el formulario para evitar errores humanos.
  - Checkbox para enviar correo de notificación masiva y botón dinámico que ejecuta la llamada a la API `PUT` mostrando confirmación con el número de correos enviados.

### 4. Corrección de Visualización de Cuentas y Dashboard (Nuevo)
* **Selector Multicuenta Dinámico en BotCard:**
  - Cuando una misma clave de licencia tiene múltiples cuentas MetaTrader 5 sincronizadas (por ejemplo, tus cuentas Demo `1028690`, `11649344` y la cuenta histórica `27625151`), se muestra un selector desplegable premium de estilo glassmorphic en la esquina superior del panel de control.
  - Al cambiar de cuenta en el selector, el panel actualiza al instante el balance, equidad, profit acumulado hoy, versión en ejecución y filtra la lista de posiciones abiertas de la terminal a esa cuenta específica.
* **Deduplicación de Mapeo de Cuentas (Demo vs Real):**
  - Modificado el endpoint `/api/sync-positions` para mapear de forma explícita la cuenta de pruebas normal histórica `27625151` a la ficha de **MAIKO PRO GOLD (Real)** de Sakura, manteniendo las cuentas clientes de prueba (`1028690` y `11649344`) en la ficha de **MAIKO PRO GOLD DEMO**. Esto evita que el balance y la telemetría de una cuenta de pruebas de Sakura sobrescriba la del cliente o viceversa.
  - Corregido el catálogo de tarjetas en el Dashboard para que lea el balance de la cuenta de trading del bot más recientemente actualizada en lugar del balance global de la licencia en base de datos.
* **Persistencia de Estado del Dashboard en `sessionStorage`:**
  - Se implementó el almacenamiento persistente de la categoría activa (BTC, Gold, Cent, etc.) y la ID del bot abierto en el detalle del panel. De esta manera, cada vez que el componente actualiza datos en segundo plano (cada 10 segundos), el panel **mantiene su estado en pantalla** y no se cierra de forma inesperada ni salta de regreso a la pestaña de Bitcoin.

---

## Verificación

### Compilación MQL5
Se ejecutó el compilador oficial de MetaTrader 5 (`metaeditor64.exe`) sobre los bots modificados, logrando una compilación **100% limpia sin errores**:
- `Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5` -> **SUCCESSFUL** (0 errors, 0 warnings)
- `Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5` -> **SUCCESSFUL** (0 errors, 1 warning (deprecated function))
- `Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5` -> **SUCCESSFUL** (0 errors, 1 warning (deprecated function))
- `Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5` -> **SUCCESSFUL** (0 errors, 1 warning (deprecated function))

Todos los archivos compilados (`.ex5` y `.mq5`) se sincronizaron automáticamente a los terminales de trading activos del sistema y al directorio público de descargas de la plataforma web (`public/uploads/bots`).

### Verificación TypeScript y Build de Next.js
Se ejecutó la verificación del compilador de TypeScript y la generación de páginas de Next.js (`npm run build`) en toda la aplicación, resultando en una **compilación exitosa libre de errores**.

### Despliegue en Vercel
Todos los cambios se han desplegado de forma exitosa en Vercel y se encuentran online en [kopytrading.com](https://www.kopytrading.com).

### 5. Renombrado de Directorio y Corrección de Rutas
* **Actualización del Directorio del Proyecto:**
  - Se corrigió el archivo `patch_bots.js` y todos los scripts en la carpeta `scratch/` para que apunten al nuevo directorio `APP KOPYTRADING` en lugar de `APP KOPYTRADE`.
  - Se recompilaron y sincronizaron con éxito los 4 bots MetaTrader 5 activos (`REAL`, `TRIAL`, `NORMAL` y `CENT`) utilizando el script de compilación y sincronización actualizado.
  - Se validó el build de producción de Next.js (`npm run build`) de forma exitosa y se subieron los cambios a producción mediante `git push`.
