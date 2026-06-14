
<div style="text-align: center; margin-bottom: 2rem;">
  <h1 style="color: #00FF7F; font-size: 2.5rem; margin-bottom: 0;">MAIKO PRO CENT 🟢</h1>
  <h3 style="color: #666; margin-top: 0;">Manual de Usuario y Estrategia</h3>
</div>

## 1. LO QUE SE ESPERA DE ESTE BOT
**MAIKO PRO CENT** es la versión "Blindada" del motor Maiko. Al estar diseñado exclusivamente para operar en Cuentas CENT (donde 100 dólares equivalen a 10.000 centavos), es un bot extremadamente conservador en cuanto a riesgo real, pero constante.
- **Perfil de Riesgo:** Muy Bajo.
- **Rendimiento Esperado:** Menos dólares netos al día que la versión Gold, pero con una curva de crecimiento mucho más suave y sostenida (ideal para Interés Compuesto).
- **Comportamiento en Flotante:** Soportará drawdowns enormes sin apenas inmutarse. Si el Oro cae 1000 pips de golpe, tu cuenta CENT apenas sufrirá un porcentaje minúsculo de riesgo gracias al amplio margen de los centavos.

## 2. LA ESTRATEGIA: CÓMO FUNCIONA
Es exactamente el mismo "Motor de Inteligencia" que el MAIKO PRO GOLD, pero sus distancias matemáticas están reajustadas:
1. **Entradas Sniper:** Analiza M5 para entrar en los retrocesos del mercado.
2. **Red de Seguridad Ampliada:** Al tener decenas de miles de "centavos" de margen, su modo Cascada/SOS puede permitirse abrir posiciones con mucha más distancia entre ellas. En lugar de estresarse por un retroceso rápido, el bot teje una red amplia que atrapará el precio con total seguridad, incluso si la tendencia tarda semanas en darse la vuelta.

## 3. CONSEJOS DE TEMPORALIDAD
- **Temporalidad (Timeframe) Obligatoria:** M5 (5 Minutos).
- Al igual que el Gold, aunque la gráfica esté en M5, el bot realiza sus cálculos de tendencia mayor analizando H1 y H4 de forma invisible.

## 4. INSTRUCCIONES DE USO E INSTALACIÓN
1. **Verificar Broker:** Asegúrate de que tu cuenta en el broker es tipo **CENT**, Micro o USC. Si instalas este bot en una cuenta Standard con $100, la quemarás.
2. **Instalación:** Pega el archivo `.ex5` en `MQL5 > Experts` de tu MetaTrader 5.
3. **WebRequests:** Añade `https://www.kopytrading.com` en las Opciones de Asesores Expertos.
4. **Gráfico:** Abre el gráfico de Oro (frecuentemente llamado XAUUSDc, XAUUSD.c o GOLD.c en cuentas Cent). Ponlo en M5.
5. **Configuración:** Pon tu Email y tu Licencia (ID). Enciende el "Algo Trading".

## 5. RECOMENDACIONES VITALES
- **Paciencia:** Al ver las ganancias en centavos, muchos usuarios se impacientan y suben los lotes. **No lo hagas**. El poder del bot CENT reside en sobrevivir a crisis mundiales del mercado sin estrés. Deja que el interés compuesto haga su magia mes a mes.

## 6. PREGUNTAS FRECUENTES Y SOLUCIÓN DE PROBLEMAS (FAQ)

### P: He arrastrado el bot y le he dado a "ENCENDER" pero no hace nada y no cambia de color.
- **Mercado cerrado o sin ticks de precio**: Los botones y textos de la interfaz del bot (HUD) solo se actualizan cuando el broker envía un movimiento de precio (tick). Si el mercado está cerrado (fin de semana) o hay bajísima liquidez, al hacer clic el botón parecerá no hacer nada. En cuanto abra el mercado y entre el primer precio, el bot se encenderá visualmente y actualizará todo su estado.
- **Algo Trading desactivado**: Asegúrate de que el botón general "Algo Trading" en la barra superior de MetaTrader 5 esté en **verde** y que hayas marcado la casilla "Permitir trading algorítmico" en las opciones comunes del bot al arrastrarlo.

### P: En el estado inferior pone "FUERA HORARIO: ESPERANDO" o "HORARIO BLOQUEADO (NOTICIAS)".
- El bot tiene horas operativas configuradas por defecto (de 09:00 a 19:00 hora del broker). Fuera de este rango, o durante periodos de noticias importantes (si tienes activado el bloqueo), el bot entrará en modo espera automática para proteger tu capital. Volverá a operar solo cuando se cumpla la hora programada.

### P: He instalado la versión de prueba (Trial/Demo) en una cuenta Real y no funciona.
- Las versiones de prueba están estrictamente limitadas por código para funcionar únicamente en cuentas de tipo **DEMO**. Si se intenta colocar en una cuenta Real, el bot lanzará una ventana de alerta y se retirará del gráfico de inmediato para evitar riesgos.

