# Plan de Implementación: Alertas de Actualización y Notificaciones por Correo de Nueva Versión

Este plan describe la implementación de un sistema de alertas en el panel de control del cliente (Dashboard) cuando se detecte una discrepancia entre la versión del bot ejecutándose en MetaTrader 5 (telemetría) y la versión disponible en el servidor (Base de Datos). Además, se incorpora la funcionalidad para que el administrador envíe un correo electrónico a todos los licenciatarios activos informando sobre la nueva actualización al subir una versión.

## User Review Required

> [!IMPORTANT]
> - Las alertas en el panel del cliente se basan en la comparación de `runningVersion` (enviado por telemetría del bot) o `lastDownloadedVersion` con `botProduct.version`.
> - En el panel de administración se agregará un formulario para "Actualizar Versión de Bot" que permitirá subir la versión del producto en BD e incluirá un selector opcional para enviar una notificación automática por correo electrónico a todos los clientes que tengan licencias activas para ese bot.
> - El correo utilizará la integración de **Resend** ya configurada en el sistema.

## Cambios Propuestos

### Componente: Backend & Helper de Emails

#### [MODIFY] [email.ts](file:///C:/proyectos/APP%20KOPYTRADING/src/lib/email.ts)
- Añadir la función `sendVersionUpdateEmail(email, botName, newVersion, purchaseId)` para enviar el correo con un diseño de alta calidad (glassmorphism/estilo oscuro) alineado con la estética de KopyTrading.
- Explicar las instrucciones para que el cliente actualice el archivo `.EX5` en su terminal de MetaTrader 5 sin alterar sus licencias.

#### [MODIFY] [route.ts](file:///C:/proyectos/APP%20KOPYTRADING/src/app/api/admin/bots/route.ts)
- Implementar el método `GET` para obtener el listado de todos los productos de bots y mostrarlos en el administrador.
- Implementar el método `PUT` para actualizar la versión de un bot de forma dinámica y, si `sendEmails === true`, buscar todos los usuarios con compras válidas y enviarles el correo de actualización.

---

### Componente: UI Panel de Control (Dashboard)

#### [MODIFY] [BotCard.tsx](file:///C:/proyectos/APP%20KOPYTRADING/src/components/BotCard.tsx)
- Recuperar la versión del bot de la telemetría almacenada en `purchase?.botSettings?.[0]?.settings` (`runningVersion`).
- Compararla con `botProduct.version` (`latestVersion`).
- Si `runningVersion` (o en su defecto `purchase.lastDownloadedVersion`) es menor o diferente a `latestVersion`, mostrar una alerta estética en color ámbar/dorado dentro del bloque de descargas invitando a descargar la versión `latestVersion`.

#### [MODIFY] [DashboardContainer.tsx](file:///C:/proyectos/APP%20KOPYTRADING/src/components/DashboardContainer.tsx)
- Agregar un indicador dinámico y parpadeante (Amber Badge: `ACTUALIZACIÓN vX.XX`) en la vista general (mini-tarjetas del catálogo) al lado del estado ONLINE/OFFLINE para alertar al cliente inmediatamente al ingresar al panel.

---

### Componente: UI Panel de Administración

#### [MODIFY] [page.tsx](file:///C:/proyectos/APP%20KOPYTRADING/src/app/admin/page.tsx)
- Cargar la lista de bots en el administrador a través de la API `GET /api/admin/bots`.
- Añadir una nueva pestaña o sección llamada **"Actualizar Versión de Bot"** con un formulario intuitivo.
- Campos del formulario:
  - Bot a actualizar (Selector dinámico de bots activos).
  - Nueva Versión (Texto, ej: `11.30`).
  - Descripción de cambios/notas (Texto).
  - Checkbox: "Enviar correo de notificación a todos los usuarios con licencia activa" (por defecto `true`).
  - Botón: "Actualizar y Notificar".

---

## Plan de Verificación

### Pruebas de Compilación y Servidor
1. Ejecutar compilación local (`npm run build`) para verificar la ausencia de errores en TypeScript o Next.js.
2. Comprobar que no hay warnings en las peticiones del dashboard.

### Pruebas Manuales
1. Cambiar temporalmente la versión de un bot en la base de datos (por ejemplo, el demo de Sakura) a una versión superior para forzar la aparición de la alerta de actualización.
2. Confirmar visualmente la presencia de la alerta en la mini-tarjeta del dashboard y dentro de la pestaña de descargas del bot del cliente.
3. Ejecutar el formulario de actualización de versión en el panel de administrador para el email `viajaconsakura@gmail.com` y comprobar en consola o Resend que se envíe el correo correspondiente con los datos exactos.
