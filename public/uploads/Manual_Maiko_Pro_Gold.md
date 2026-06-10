
<div style="text-align: center; margin-bottom: 2rem;">
  <h1 style="color: #FFD700; font-size: 2.5rem; margin-bottom: 0;">MAIKO PRO GOLD 🏆</h1>
  <h3 style="color: #666; margin-top: 0;">Manual de Usuario y Estrategia</h3>
</div>

## 1. LO QUE SE ESPERA DE ESTE BOT
**MAIKO PRO GOLD** es nuestro algoritmo más agresivo y sofisticado, diseñado para aprovechar al máximo la alta volatilidad del mercado del Oro (XAUUSD). 
- **Perfil de Riesgo:** Medio-Alto. Está pensado para generar beneficios rápidos y diarios.
- **Rendimiento Esperado:** Busca cerrar un objetivo diario concreto (ej: $100 - $150 para una cuenta de $1000 aproximadamente) y luego "irse a dormir". No obstante, desde los parámetros del bot puedes modificar libremente este profit diario, así como el profit de cosecha individual.
- **Comportamiento en Flotante (Sin Stop Loss):** Nuestra estrategia **NO utiliza Stop Loss clásico**. En las exhaustivas pruebas realizadas, el bot ha demostrado ser capaz de manejar el flotante perfectamente, promediando precios para encontrar el punto de salida matemático óptimo. Por tanto, **ver operaciones en rojo es parte natural de su estrategia**.

## 2. LA ESTRATEGIA: CÓMO FUNCIONA
Utiliza una estrategia mixta de **Sniper Scalping** y **Recuperación Elástica (SOS)**:
1. **Análisis de Tendencia:** Internamente escanea el mercado en temporalidades largas (H4 y H1) para identificar la dirección del día.
2. **Entrada de Precisión:** Baja a la temporalidad de 5 Minutos (M5) para buscar divergencias y retrocesos usando RSI y ATR.
3. **Gestión de Crisis (SOS / Cascada):** Si el precio se gira en contra tras la entrada, el bot despliega operaciones adicionales más abajo con un lotaje fríamente calculado para "promediar" el precio. En cuanto el Oro hace un pequeño retroceso, el bot cierra toda la cesta de golpe en ganancia.

## 3. CONSEJOS DE TEMPORALIDAD Y HORARIOS
- **Temporalidad Obligatoria:** M5 (5 Minutos). Nunca lo cambies en el gráfico.
- **Horario Óptimo:** En las pruebas realizadas se ha comprobado que opera muy bien entre las **09:00 y las 13:00 (Hora Española)**, cuando el mercado aparentemente está más calmado y técnico. 
- **Horario por Defecto:** En los parámetros viene configurado de 09:00 a 19:00 de Lunes a Viernes, pero puedes adaptarlo a tu gusto.

## 4. INSTRUCCIONES DE USO E INSTALACIÓN
1. **Descarga:** Obtén el archivo `.ex5` desde tu dashboard.
2. **Ubicación:** Cópialo en tu MetaTrader 5, en `MQL5 > Experts`.
3. **Permisos Web:** En MT5 ve a `Herramientas > Opciones > Asesores Expertos` y añade: `https://www.kopytrading.com` en WebRequest.
4. **Gráfico:** Abre XAUUSD en M5 y arrastra el bot.
5. **Licencia:** Introduce tu **Licencia (ID)** en la pestaña de parámetros.

## 5. RECOMENDACIONES VITALES Y GESTIÓN DE RIESGO
- **Capital Mínimo:** Se recomienda un balance de **$1,000 USD**. Está probado con $500 y funciona perfectamente, aunque el hecho de tener que aguantar el flotante es evidentemente más arriesgado con $500. Ha superado las pruebas sin problema en ambos balances.
- **Intervención y Control Web:** A diferencia de otros bots "cerrados", con MAIKO PRO GOLD puedes operar perfectamente desde la web (apagarlo, encenderlo o usar el botón de pánico para cerrar operaciones). A pesar de ello, **se recomienda dejar operar al bot tranquilamente**. Solo debes intervenir en momentos puntuales donde consideres que hay un peligro extremo y no tengas disposición de arriesgar más.
- **Vigilancia en Volatilidad y Noticias:** Aunque el bot tiene sistemas de seguridad, se recomienda vigilarlo en horas de mucha volatilidad o noticias extremas. Si ves algo fuera de lo normal en el mercado, valora apagar el bot desde la web hasta el día siguiente.
- **Los Viernes y los Gaps:** El sistema deja de abrir operaciones nuevas los viernes a las 19:00 para dar tiempo a cerrar el ciclo. Se recomienda encarecidamente **cerrar las operaciones abiertas los viernes** antes del cierre del mercado. Si consideras que el mercado puede darse la vuelta el lunes o quieres evitar "gaps" de fin de semana que podrían quemar la cuenta, es preferible asumir una pérdida controlada (cerrando en negativo) el viernes a última hora, ya que por los cálculos de rentabilidad, el sistema puede asumir y recuperar esa pérdida la semana siguiente.
