
<div style="text-align: center; margin-bottom: 2rem;">
  <h1 style="color: #FFD700; font-size: 2.5rem; margin-bottom: 0;">MAIKO PRO GOLD 🏆</h1>
  <h3 style="color: #666; margin-top: 0;">Manual de Usuario y Estrategia</h3>
</div>

## 1. LO QUE SE ESPERA DE ESTE BOT
**MAIKO PRO GOLD** es nuestro algoritmo más agresivo y sofisticado, diseñado para aprovechar al máximo la alta volatilidad del mercado del Oro (XAUUSD). 
- **Perfil de Riesgo:** Medio-Alto. Está pensado para generar beneficios rápidos y diarios.
- **Rendimiento Esperado:** Busca cerrar un objetivo diario concreto (ej: $100 - $150) y luego "irse a dormir". 
- **Comportamiento en Flotante:** Es normal que a lo largo de su operativa acumule un "flotante negativo" temporal. El bot promedia precios para buscar un punto de salida matemático; por tanto, **ver operaciones en rojo es parte natural de su estrategia**. No te asustes, el algoritmo tiene sus propios cortafuegos.

## 2. LA ESTRATEGIA: CÓMO FUNCIONA
Utiliza una estrategia mixta de **Sniper Scalping** y **Recuperación Elástica (SOS)**:
1. **Análisis de Tendencia:** Internamente escanea el mercado en temporalidades largas (H4, H1 y M15) para identificar si el día es alcista o bajista.
2. **Entrada de Precisión:** Baja a la temporalidad de 1 Minuto (M1) para buscar divergencias y retrocesos usando RSI y ATR. Entra justo cuando el mercado está "sobre-estirado" en el corto plazo.
3. **Gestión de Crisis (SOS / Cascada):** Si el precio se gira repentinamente en contra tras la entrada, el bot no asume la pérdida inmediatamente. En su lugar, activa el Modo SOS: despliega operaciones adicionales más abajo con un lotaje fríamente calculado (Martingala dinámica) para "promediar" el precio de entrada. En cuanto el Oro hace un pequeño retroceso (que siempre lo hace), el bot cierra toda la cesta de golpe en ganancia.

## 3. CONSEJOS DE TEMPORALIDAD
- **Temporalidad (Timeframe) Obligatoria:** M1 (1 Minuto).
- **Aviso:** Aunque lo pongas en M1, su "cerebro" está analizando H4 y M15 en segundo plano. Nunca lo pongas en H1 o H4, ya que las distancias matemáticas se romperían.

## 4. INSTRUCCIONES DE USO E INSTALACIÓN
1. **Descarga:** Obtén el archivo `.ex5` desde tu dashboard de Kopytrading.
2. **Ubicación:** Cópialo en tu MetaTrader 5, dentro de `Archivo > Abrir Carpeta de Datos > MQL5 > Experts`.
3. **Permisos Web:** En MT5 ve a `Herramientas > Opciones > Asesores Expertos` y marca "Permitir WebRequest para las siguientes URL". Añade: `https://www.kopytrading.com`.
4. **Gráfico:** Abre un gráfico de XAUUSD (Oro) y ponlo en M1. Arrastra el bot al gráfico.
5. **Autenticación:** En la ventana que aparece, pon tu **Email de Kopytrading** y la **Clave de Licencia (ID)** que te aparece en la web.
6. **Ejecución:** Asegúrate de que el botón **"Algo Trading"** de arriba está en verde.

## 5. RECOMENDACIONES VITALES
- **Capital Mínimo:** Se recomienda encarecidamente $1,000 USD de balance para soportar los flotantes en modo SOS.
- **NO INTERVENIR:** Nunca cierres una operación manualmente si el bot tiene un grupo de operaciones abiertas. Romperías el cálculo matemático de su cierre automático.
- **Noticias:** Durante noticias extremas (NFP, IPC), el mercado se vuelve caótico. El bot tiene un filtro, pero se recomienda pausarlo 30 minutos antes de estos eventos.
