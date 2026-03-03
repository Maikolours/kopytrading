# Desarrollo de Marketplace Web de Bots de Trading para MT5

## 1. Objetivo
Desarrollar una **aplicación web moderna, profesional y escalable** que funcione como **marketplace de bots de trading descargables para MetaTrader 5 (MT5)**.

**No será una plataforma de ejecución ni copy trading.**
Solo será una plataforma de **venta directa de bots descargables**.

## 2. Modelo de Negocio
- Pago único por bot.
- Sin suscripción mensual.
- Sin gestión de cuentas de trading.
- Sin ejecución en servidor.
- El usuario descarga el bot y lo instala en su propio MT5.

## 3. Producto que se Vende
- Formato: `.ex5` (compatible MT5).  
- Incluye:
  - Archivo descargable
  - Manual en PDF
  - Guía de configuración
  - Parámetros explicados

**Características de los bots:**
- Configurables por el usuario
- Editables en parámetros
- Probados en:
  - Backtesting
  - Demo
  - Real (según documentación)

## 4. Mercados Iniciales
Bots enfocados en:
- XAUUSD (Oro)  
- EURUSD  
- USDJPY  
- GBPUSD  
- BTCUSD  
- ETHUSD  
- US30  
- NAS100

**Compatibilidad con brokers MT5 como:**
- Vantage  
- VT Markets  
- Cualquier broker MT5

## 5. Estructura de la Web

### 5.1 Página Principal
- Diseño moderno tipo fintech.  
- Hero section impactante.  
- Mensaje claro: **“Bots profesionales para MetaTrader 5”**  
- Botones:  
  - Ver Bots  
  - Cómo Funciona

### 5.2 Página de Marketplace
- Mostrar bots en tarjetas modernas con:  
  - Nombre del bot  
  - Instrumento  
  - Tipo de estrategia (tendencial, scalping, grid, etc.)  
  - Nivel de riesgo  
  - Precio  
  - Botón “Ver Detalles”  
- Diseño minimalista tipo tarjetas.

### 5.3 Página Individual de Cada Bot
- Nombre completo  
- Descripción profesional  
- Explicación clara de la estrategia  
- Mercado que opera  
- Timeframes recomendados  
- Capital mínimo recomendado  
- Nivel de riesgo  
- Parámetros configurables explicados  
- Resultados de backtest (imagen o gráfico)  
- Disclaimer financiero claro  
- Botón: **“Comprar y Descargar”**

### 5.4 Sistema de Compra
- Integración con Stripe **o** sistema simple de pago manual.  
- Tras el pago:
  - Acceso inmediato a descarga
  - Email automático con enlace
  - Descarga protegida por login

## 6. Sistema de Usuarios
- Registro / Login  
- Perfil  
- Historial de compras  
- Re-descarga de productos comprados

## 7. Panel de Administración
Permite:
- Crear nuevo bot
- Subir archivo descargable
- Subir manual PDF
- Editar descripción
- Cambiar precio
- Ver ventas
- Desactivar producto

## 8. Tecnología Recomendada
**Frontend:**
- Next.js  
- TailwindCSS  
- Diseño oscuro moderno

**Backend:**
- Node.js o Python  
- API REST  
- Base de datos PostgreSQL

**Infraestructura:**
- Docker  
- Preparado para AWS

## 9. Diseño Visual
- Minimalista  
- Profesional  
- Oscuro (dark mode)  
- Inspiración: TradingView, Stripe, plataformas fintech modernas

## 10. Legal
- Aviso legal  
- Política de privacidad  
- Términos y condiciones  
- Disclaimer financiero claro:  
> “El trading conlleva riesgo y no se garantizan beneficios.”

## 11. Consideraciones Importantes
**No se desea:**
- Plataforma de copy trading  
- Gestión de cuentas de trading  
- Conexión directa a brokers  
- Ejecución en servidor

**Solo un marketplace profesional de bots descargables.**

