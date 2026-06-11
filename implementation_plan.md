# Plan de Implementación: Ajuste de Bots Maiko y Notificaciones de Trial

Este plan detalla los cambios técnicos realizados y planificados para los bots de trading Maiko (MQL5) y la plataforma de copytrading (Next.js backend) para cumplir con los requerimientos del usuario.

## Cambios Solicitados e Implementados

### 1. Bot MQL5 CENT (`Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5`)
* **Ajuste de Parámetros:**
  - `ProfitCosechaIndividual` establecido por defecto a `0.06` (6 centavos).
  - `ProfitNetoFlush` establecido por defecto a `0.25` (25 centavos).
  - `LimitePosicionesSOS` establecido por defecto a `1` (lo que limita las posiciones abiertas simultáneamente a un máximo de 2: 1 de ataque + 1 de SOS).
* **Corrección del Escape TP:**
  - Corregido el error de conversión de unidades dividiendo el `priceDiff` (que viene en centavos) por `multCent` (100) antes de calcular el take profit final en USD: `avgPrice + (priceDiff / multCent)`.
* **Visualización del HUD:**
  - Se añade la etiqueta estática `LICENCIA: ACTIVA` en color amarillo para mantener consistencia visual y no mostrar ningún contador de trial.

### 2. Bot MQL5 NORMAL (`Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5`)
* **Limpieza de Trial:**
  - Eliminado el parámetro de entrada `DiasDeTrial`.
  - Desactivado el chequeo del trial en `OnInit()`.
  - Modificado el HUD para que muestre de forma fija: `LICENCIA: ACTIVA` en color amarillo.

### 3. Bot MQL5 TRIAL (`Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5`)
* **Contador HUD con Cuenta Regresiva:**
  - Modificado `OnTick()` para recalcular de forma dinámica el tiempo restante del ciclo diario de 24 horas y los días restantes de trial.
  - El HUD ahora muestra: `TRIAL: DIA X [HHh MMm]` en color amarillo.
* **Avisos de Expiración:**
  - Cuando quedan 7 o menos días, el color cambia a naranja/rojo y el texto se actualiza dinámicamente a: `EXPIRA EN X DIAS [HHh MMm] | ADQUIERE REAL`.
  - Cuando el trial expira, se muestra `TRIAL EXPIRADO` en color rojo y el bot apaga automáticamente la operativa.

### 4. Automatización de Emails y Copia a Sakura
* **Copia de seguridad a Sakura:**
  - Todos los correos electrónicos de Kopytrading (`sendWelcomeEmail`, `sendTrialProgressEmail`, `sendTrialExpiredEmail`) incluyen automáticamente en el BCC a `viajaconsakura@gmail.com` para que el dueño reciba copia de todo y pueda auditarlos.
* **Emails Semanales de Progreso:**
  - Envío automático de emails de progreso a los usuarios registrados al completar cada semana de operativa:
    - **Semana 1 Completada:** a los 23 días restantes (7 días transcurridos).
    - **Semana 2 Completada:** a los 16 días restantes (14 días transcurridos).
    - **Semana 3 Completada:** a los 9 días restantes (21 días transcurridos).
    - **Semana 4 / Alerta Final:** a los 2 días restantes (28 días transcurridos).
* **Email de Expiración:**
  - Envío automático del correo recordando adquirir la versión Real en el momento exacto en que expira la demo (`diasRestantes <= 0` o `trialExpirado == true`).

---

## Estado del Plan y Siguientes Pasos

1. **[HECHO]** Modificación del bot CENT con los parámetros por defecto de fábrica (0.06 individual, 0.25 colectivo, límite 1 SOS, escape TP corregido).
2. **[HECHO]** Modificación del bot NORMAL para quitar todo rastro de Trial y mostrar `LICENCIA: ACTIVA` permanentemente en el HUD.
3. **[HECHO]** Modificación del bot TRIAL para añadir la cuenta regresiva en formato `[HHh MMm]` y las alertas de última semana en color naranja/rojo.
4. **[HECHO]** Compilación exitosa de todos los bots mediante MetaEditor64 y sincronización a los 3 terminales locales y a la carpeta de descargas de la web (`public/uploads/bots`).
5. **[PENDIENTE]** Modificar `src/lib/email.ts` para estructurar la plantilla de los correos semanales (Semana 1, 2, 3, 4) y de expiración.
6. **[PENDIENTE]** Modificar la lógica del endpoint de sincronización (`src/app/api/sync-positions/route.ts`) para despachar los emails de progreso semanales y de expiración usando flags guardados en los settings del bot para evitar envíos duplicados.
