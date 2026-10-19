export interface QuizOption {
  id: string; // 'A', 'B', 'C', 'D'
  text: string;
}

export interface QuizQuestion {
  id: string;
  badgeText?: string;
  question: string;
  options: QuizOption[];
  correctAnswerId: string;
  feedbackExplanation: string;
}

export interface LessonPage {
  pageIndex: number;
  totalPages: number;
  title: string;
  content: string[]; // Parágrafos explicativos sencillos
  keyConceptCard?: {
    tag: string;
    title: string;
    items: { label: string; value: string; color?: string }[];
  };
}

export interface Lesson {
  id: string;
  moduleId: string;
  lessonNumber: number; // e.g. 1, 2, 3
  globalIndex: number;  // 1 a N
  title: string;
  subtitle?: string;
  durationMinutes: number;
  isVip: boolean;
  isFreeTrialUnlocker?: boolean;
  pages?: LessonPage[];
  quiz?: QuizQuestion;
}

export interface Module {
  id: string;
  moduleNumberStr: string; // "00", "01", "02", etc.
  title: string;
  subtitle: string;
  description: string;
  isVip: boolean;
  lessons: Lesson[];
}

export const ACADEMIA_MODULES: Module[] = [
  {
    id: "modulo-00",
    moduleNumberStr: "00",
    title: "BIENVENIDA Y EXPECTATIVAS REALES",
    subtitle: "Primeros pasos y mentalidad",
    description: "Comprende qué es el trading algorítmico, por qué la gestión de riesgo lo es todo y cómo evitar los errores comunes del principiante.",
    isVip: false,
    lessons: [
      {
        id: "m00-l01",
        moduleId: "modulo-00",
        lessonNumber: 1,
        globalIndex: 1,
        title: "Bienvenido a Kopytrading Academy",
        subtitle: "Aprende a operar con bots sin magia ni engaños",
        durationMinutes: 4,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "¿Por qué estamos aquí?",
            content: [
              "La mayoría de las personas que llegan al trading algorítmico lo hacen buscando rentabilidad mágica de la noche a la mañana. Ese es el primer error que arruina cuentas.",
              "Un bot de trading no es una lámpara maravillosa: es un programa informático que ejecuta reglas de matemática, estadística y control de riesgo a alta velocidad sin emociones humanas.",
              "En esta academia vas a aprender cómo funciona un algoritmo, cómo evaluar su comportamiento en los gráficos y cómo gestionar el capital como un operador profesional."
            ],
            keyConceptCard: {
              tag: "REGLA NÚMERO 1",
              title: "LA REALIDAD DEL ALGORITMO",
              items: [
                { label: "Bot de Trading", value: "Ejecutor de matemática pura", color: "text-amber-400" },
                { label: "Control de Riesgo", value: "La base de la consistencia", color: "text-emerald-400" },
                { label: "Horizonte", value: "Evaluación en meses, no días", color: "text-blue-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "¿Qué aprenderás en este curso?",
            content: [
              "A lo largo de los módulos aprenderás a interpretar las velas japonesas, identificar la estructura del mercado (tendencias y rangos), entender la volatilidad del Oro (XAUUSD) y dominar la configuración de MetaTrader 5.",
              "Al completar los módulos y superar los cuestionarios de evaluación, desbloquearás un cupón del 100% de descuento (ACADEMIA100) para activar 1 mes gratis de MAIKO PRO GOLD CLIENT DEMO FIX en tu cuenta demo de MT5."
            ]
          }
        ],
        quiz: {
          id: "quiz-m00-l01",
          badgeText: "EVALUACIÓN INICIAL",
          question: "¿Cuál es la función real de un bot de trading algorítmico institucional?",
          options: [
            { id: "A", text: "Anticipar con certeza absoluta el impacto de las noticias macroeconómicas antes de que se publiquen" },
            { id: "B", text: "Eliminar el 100% del riesgo de mercado garantizando ganancias fijas diarias sin retrocesos" },
            { id: "C", text: "Ejecutar reglas matemáticas, estadísticas y de control de riesgo programadas con disciplina estricta y sin sesgos emocionales" },
            { id: "D", text: "Operar únicamente durante los fines de semana cuando los mercados financieros globales están cerrados" }
          ],
          correctAnswerId: "C",
          feedbackExplanation: "¡Correcto! Un bot de trading no predice el futuro ni hace magia; es un sistema que ejecuta reglas matemáticas con disciplina inquebrantable, eliminando el miedo, la avaricia y la indisciplina humana."
        }
      },
      {
        id: "m00-l02",
        moduleId: "modulo-00",
        lessonNumber: 2,
        globalIndex: 2,
        title: "Expectativas Reales y Semanas de Volatilidad",
        subtitle: "Cómo reaccionar ante los movimientos del mercado",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Las rachas y el flotante son parte del sistema",
            content: [
              "En los mercados financieros no existe ningún sistema que gane el 100% de las operaciones. El precio se mueve por flujos institucionales, tipos de interés y noticias geopolíticas que generan fluctuaciones continuas.",
              "Un algoritmo profesional está diseñado con un sesgo probabilístico: aprovecha las expansiones a favor de tendencia y gestiona el flotante en contra mediante coberturas o salidas calculadas.",
              "Intentar juzgar un bot por lo que ocurre en una sola tarde es el error típico del principiante. La solidez matemática se mide en muestras de cientos de operaciones a lo largo de trimestres."
            ]
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "El error de la intervención manual apresurada",
            content: [
              "Cuando el mercado experimenta una sacudida temporal, el operador inexperto siente pánico, cierra operaciones en el peor momento y altera los parámetros sin criterio estadístico.",
              "El operador cuantitativo confía en el backtest validado: sabe que la curva de capital experimentará valles temporales (drawdown) antes de marcar nuevos picos de balance."
            ],
            keyConceptCard: {
              tag: "MENTALIDAD CUANTITATIVA",
              title: "CLAVES DE RESILIENCIA",
              items: [
                { label: "Muestra Mínima", value: "100+ operaciones", color: "text-amber-400" },
                { label: "Intervención", value: "Cero alteraciones impulsivas", color: "text-red-400" },
                { label: "Objetivo", value: "Preservación del capital", color: "text-emerald-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m00-l02",
          badgeText: "DISCIPLINA DE MERCADO",
          question: "Si el mercado atraviesa una fase de alta volatilidad y tu cuenta experimenta un flotante negativo temporal, ¿cuál es la conducta cuantitativa correcta?",
          options: [
            { id: "A", text: "Aumentar de inmediato el volumen de lote para intentar compensar el flotante en la siguiente oscilación del precio" },
            { id: "B", text: "Mantener la calma, respetar los parámetros de riesgo preestablecidos y evaluar el rendimiento en ventanas temporales de varios meses" },
            { id: "C", text: "Cerrar manualmente todas las posiciones en el mínimo del retroceso y cambiar los parámetros del bot sin un backtest previo" },
            { id: "D", text: "Desconectar la conexión a internet de la computadora para evitar que el broker registre el movimiento del precio" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! La disciplina y el respeto al plan matemático son indispensables. Las rachas de volatilidad forman parte del mercado; alterar la gestión de riesgo por pánico suele ser la causa de quiebra de cuentas."
        }
      }
    ]
  },
  {
    id: "modulo-01",
    moduleNumberStr: "01",
    title: "MERCADOS, VELAS Y ESTRUCTURA TÉCNICA",
    subtitle: "Cómo se mueve el precio en M5 y cómo lo lee el bot",
    description: "Domina la anatomía de las velas japonesas, la lectura de mechas de rechazo, las tendencias y la volatilidad institucional en el Oro (XAUUSD).",
    isVip: false,
    lessons: [
      {
        id: "m01-l01",
        moduleId: "modulo-01",
        lessonNumber: 1,
        globalIndex: 3,
        title: "¿Qué es el mercado y cómo se generan beneficios?",
        subtitle: "Conceptos básicos de operativa en activos financieros",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "La lógica de la cotización de activos",
            content: [
              "El trading financiero consiste en comprar o vender contratos por diferencia (CFD) sobre activos (como divisas, materias primas o índices) aprovechando las fluctuaciones en su cotización.",
              "Si abres una posición de compra (largo) y el precio sube, obtienes un rendimiento proporcional a los puntos avanzados y al volumen contratado. Si abres una venta (corto) y el precio cae, también generas beneficio de esa caída.",
              "A través de MetaTrader 5, estas órdenes se transmiten de forma electrónica en milisegundos a los proveedores de liquidez."
            ],
            keyConceptCard: {
              tag: "MECÁNICA OPERATIVA",
              title: "DIRECCIÓN DEL BENEFICIO",
              items: [
                { label: "Posición BUY (Largo)", value: "Gana con la subida del precio", color: "text-emerald-400" },
                { label: "Posición SELL (Corto)", value: "Gana con la bajada del precio", color: "text-blue-400" },
                { label: "Fricción (Spread)", value: "Diferencia oferta / demanda", color: "text-amber-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Pares de Divisas y Materias Primas",
            content: [
              "En el mercado Forex se intercambian pares como EUR/USD (Euro frente al Dólar). En las materias primas, el activo reina por excelencia es el Oro (XAUUSD), valorado en dólares por onza troy.",
              "Los algoritmos monitorean continuamente la relación entre oferta y demanda para encontrar zonas de desequilibrio donde la probabilidad matemática está a nuestro favor."
            ]
          }
        ],
        quiz: {
          id: "quiz-m01-l01",
          badgeText: "EVALUACIÓN DE MERCADO",
          question: "¿Cómo se genera un rendimiento positivo al operar contratos de divisas o materias primas en MetaTrader?",
          options: [
            { id: "A", text: "Aprovechando la diferencia favorable entre el precio de entrada y el precio de salida de una orden de compra o venta" },
            { id: "B", text: "Esperando pasivamente a que el broker abone una tasa de interés fija anual por el simple hecho de tener la cuenta abierta" },
            { id: "C", text: "Comprando lingotes físicos de oro para almacenarlos en una bóveda bancaria personal" },
            { id: "D", text: "Manteniendo posiciones de compra y venta abiertas simultáneamente sin ninguna orden de Take Profit ni Stop Loss" }
          ],
          correctAnswerId: "A",
          feedbackExplanation: "¡Correcto! En el trading se monetiza la diferencia de cotización entre el punto de apertura y el punto de cierre, ya sea aprovechando una subida mediante compra o una caída mediante venta."
        }
      },
      {
        id: "m01-l02",
        moduleId: "modulo-01",
        lessonNumber: 2,
        globalIndex: 4,
        title: "El Oro (XAUUSD) como Activo de Volatilidad",
        subtitle: "Características especiales del activo rey",
        durationMinutes: 6,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Por qué el Oro es el favorito del trading algorítmico",
            content: [
              "El Oro (XAUUSD) es considerado el activo refugio global. Debido a su enorme volumen diario, presenta movimientos limpios, tendencias expansivas y ciclos de alta liquidez ideales para estrategias cuantitativas.",
              "A diferencia de pares de divisas lentos que pueden permanecer estancados durante semanas, el Oro se desplaza decenas de dólares en una sola sesión de Nueva York o Londres.",
              "Esta misma virtud exige prudencia: un movimiento de 30 dólares en el Oro representa cientos de pips de recorrido."
            ]
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "La necesidad de calibración precisa en M5",
            content: [
              "Operar Oro en gráficos demasiado lentos (como Diario o H4) requiere márgenes enormes para soportar el recorrido. Operar en M1 genera demasiado ruido aleatorio de microsegundos.",
              "El marco temporal de M5 (velas de 5 minutos) ofrece la ventana óptima: captura los impulsos de liquidez intradía permitiendo fijar salidas rápidas con riesgo estrictamente controlado."
            ],
            keyConceptCard: {
              tag: "CARACTERÍSTICAS XAUUSD",
              title: "PERFIL DEL METAL",
              items: [
                { label: "Volatilidad", value: "Alta y expansiva", color: "text-amber-400" },
                { label: "Timeframe Oficial", value: "M5 (5 Minutos)", color: "text-emerald-400" },
                { label: "Gestión de Lote", value: "0.01 por cada $1.000 USD", color: "text-purple-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m01-l02",
          badgeText: "VOLATILIDAD DEL ORO",
          question: "¿Por qué el Oro (XAUUSD) es un activo tan apreciado para operar con algoritmos, pero exige parámetros de lotaje estrictos?",
          options: [
            { id: "A", text: "Porque la cotización del Oro permanece inmóvil durante la sesión europea, lo que permite apalancarse al máximo" },
            { id: "B", text: "Porque los brokers regulados aplican comisiones nulas únicamente en los pares de metales preciosos" },
            { id: "C", text: "Porque MetaTrader 5 solo es compatible con Asesores Expertos programados para materias primas" },
            { id: "D", text: "Porque ofrece recorridos limpios y alta liquidez institucional, pero su rápida volatilidad puede agotar el margen de la cuenta si el lotaje es excesivo" }
          ],
          correctAnswerId: "D",
          feedbackExplanation: "¡Exacto! El Oro ofrece oportunidades excepcionales por su liquidez y amplitud de movimiento, pero esa misma velocidad castiga severamente a las cuentas que no respetan un lotaje proporcional al balance."
        }
      },
      {
        id: "m01-l03",
        moduleId: "modulo-01",
        lessonNumber: 3,
        globalIndex: 5,
        title: "Conoce las Velas Japonesas: Mechas, Cuerpos y Rechazos en M5",
        subtitle: "Cómo interpretar la fuerza y el agotamiento en cada vela",
        durationMinutes: 7,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Anatomía de una Vela Japonesa",
            content: [
              "Cada vela japonesa en tu gráfico representa el resumen visual de lo que ocurrió durante un intervalo de tiempo específico (por ejemplo, 5 minutos en el gráfico M5).",
              "Una vela se compone de dos partes esenciales: el Cuerpo Real (la distancia entre el precio de apertura y el de cierre) y las Sombras o Mechas (los precios extremos máximo y mínimo alcanzados durante esos 5 minutos).",
              "Si el precio cierra por encima de donde abrió, la vela es alcista (generalmente verde o blanca). Si cierra por debajo, es bajista (roja o negra). Un cuerpo amplio refleja fuerte convicción de los participantes; un cuerpo comprimido refleja indecisión."
            ],
            keyConceptCard: {
              tag: "ELEMENTOS DE LA VELA",
              title: "ANATOMÍA BÁSICA M5",
              items: [
                { label: "Cuerpo Amplio", value: "Impulso y volumen direccional", color: "text-emerald-400" },
                { label: "Cuerpo Pequeño (Doji)", value: "Indecisión o agotamiento", color: "text-amber-400" },
                { label: "Mechas (Extremos)", value: "Zonas de liquidez exploradas", color: "text-blue-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "La importancia de las Mechas de Rechazo y Absorción",
            content: [
              "Las mechas no son simples líneas: son huellas de batallas entre compradores y vendedores. Una mecha larga superior en una zona de resistencia indica que el precio subió, pero una oleada de ventas institucionales absorbió las compras y empujó el precio hacia abajo antes del cierre.",
              "Por el contrario, una mecha inferior pronunciada (patrón de rechazo o martillo) sobre un soporte muestra que los compradores defendieron ese nivel con contundencia.",
              "Los algoritmos cuantitativos como MAIKO analizan el ratio entre la mecha y el cuerpo de la vela M5 para detectar cuándo un movimiento se ha agotado y preparar coberturas o salidas en breakeven."
            ]
          }
        ],
        quiz: {
          id: "quiz-m01-l03",
          badgeText: "ANÁLISIS DE VELAS",
          question: "¿Qué nos indica la formación de una vela M5 con una mecha superior muy alargada y un cuerpo pequeño al llegar a una zona de resistencia en el Oro?",
          options: [
            { id: "A", text: "Que los compradores tienen el control absoluto y el precio continuará subiendo sin retrocesos" },
            { id: "B", text: "Que el broker ha suspendido temporalmente la cotización y se debe reiniciar el terminal" },
            { id: "C", text: "Que hubo un rechazo de precios altos donde la oferta vendedora absorbió las compras, sugiriendo un agotamiento del impulso alcista" },
            { id: "D", text: "Que la vela garantiza matemáticamente una caída de 200 pips en los siguientes 60 segundos" }
          ],
          correctAnswerId: "C",
          feedbackExplanation: "¡Correcto! Una mecha superior prolongada con cuerpo estrecho refleja absorción vendedora y rechazo de precios más altos, lo que advierte de un posible freno o giro del movimiento."
        }
      },
      {
        id: "m01-l04",
        moduleId: "modulo-01",
        lessonNumber: 4,
        globalIndex: 6,
        title: "Estructura de Mercado: Tendencias Alcistas vs Bajistas y Rangos",
        subtitle: "Alineación algorítmica con el flujo mayor del mercado",
        durationMinutes: 7,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Estructura de Máximos y Mínimos (Higher Highs / Lower Lows)",
            content: [
              "El mercado no se mueve en línea recta, sino en ondas de impulso y retroceso. Identificar la estructura permite saber quién tiene el control del mercado:",
              "• Tendencia Alcista: Se caracteriza por una sucesión continua de máximos más altos (Higher Highs o HH) y mínimos más altos (Higher Lows o HL). Cada retroceso se frena por encima del mínimo anterior, protegiendo la estructura compradora.",
              "• Tendencia Bajista: Se forma mediante máximos más bajos (Lower Highs o LH) y mínimos más bajos (Lower Lows o LL). Cada rebote alcista es frenado por debajo del techo previo.",
              "• Rango Lateral (Consolidación): El precio rebota entre un techo y un suelo sin definir una dirección clara."
            ],
            keyConceptCard: {
              tag: "ESTRUCTURA DE MERCADO",
              title: "PATRONES DE FLUJO TÉCNICO",
              items: [
                { label: "Estructura Alcista", value: "Mínimos crecientes (HL)", color: "text-emerald-400" },
                { label: "Estructura Bajista", value: "Máximos decrecientes (LH)", color: "text-red-400" },
                { label: "Ruptura de Estructura", value: "Alerta de cambio de sesgo (ChoCH)", color: "text-amber-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Filtros de Tendencia y Medias Móviles en Algoritmos",
            content: [
              "Para evitar operar en contra de la corriente institucional, los bots profesionales utilizan filtros de tendencia como las Medias Móviles Exponenciales (EMA de 50 y 200 períodos en M5).",
              "Si el precio cotiza con claridad por encima de las medias móviles y la estructura es de mínimos crecientes, el algoritmo prioriza entradas de compra.",
              "Cuando el precio entra en un rango lateral caótico, los filtros de volatilidad y spread bloquean las entradas para evitar falsas rupturas que puedan atrapar la cuenta."
            ]
          }
        ],
        quiz: {
          id: "quiz-m01-l04",
          badgeText: "ESTRUCTURA TÉCNICA",
          question: "¿Cuál es la característica técnica distintiva de una estructura de mercado en tendencia alcista consolidada?",
          options: [
            { id: "A", text: "Una sucesión ordenada de máximos cada vez más altos (Higher Highs) y mínimos crecientes (Higher Lows) que respetan los soportes previos" },
            { id: "B", text: "Un movimiento puramente horizontal donde las velas no tienen cuerpo ni mechas durante varias horas" },
            { id: "C", text: "Una serie de velas consecutivas donde cada nuevo mínimo rompe con fuerza el soporte anterior con volumen vendedor creciente" },
            { id: "D", text: "Un gráfico donde el volumen transaccional desciende automáticamente a cero en cada cierre de vela" }
          ],
          correctAnswerId: "A",
          feedbackExplanation: "¡Excelente! Una tendencia alcista saludable se define precisamente por la formación continua de máximos y mínimos crecientes progresivos, donde la demanda institucional defiende cada retroceso."
        }
      }
    ]
  },
  {
    id: "modulo-02",
    moduleNumberStr: "02",
    title: "GESTIÓN DE RIESGO Y CONTROL DE CAPITAL",
    subtitle: "Reglas fundamentales de supervivencia y graduación",
    description: "Aprende a proteger tu dinero, calcular el volumen según tu balance y desbloquea tu cupón para la prueba gratuita de 30 días.",
    isVip: false,
    lessons: [
      {
        id: "m02-l01",
        moduleId: "modulo-02",
        lessonNumber: 1,
        globalIndex: 7,
        title: "El Mayor Enemigo del Trader: El Sobrelotaje",
        subtitle: "Por qué arriesgar de más arruina cualquier cuenta",
        durationMinutes: 6,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Volumen, Margen y Riesgo de Ruina",
            content: [
              "El sobrelotaje ocurre cuando un operador abre posiciones con un volumen desproporcionado respecto al saldo real de su cuenta.",
              "Por ejemplo, abrir 0.10 lotes en una cuenta de solo $500 USD significa que un retroceso de tan solo 5 dólares en el Oro consumirá más del 10% del capital en cuestión de minutos.",
              "La regla de oro institucional de Kopytrading para cuentas estándar es mantener un volumen base de 0.01 lotes por cada $1.000 USD de balance (o 0.01 por cada $100 en cuentas Cent)."
            ],
            keyConceptCard: {
              tag: "PROPORCIÓN DE LOTAJE",
              title: "GESTIÓN INSTITUCIONAL",
              items: [
                { label: "Cuenta USD ($1.000)", value: "Base: 0.01 lotes", color: "text-amber-400" },
                { label: "Cuenta Cent ($100 / 10k cent)", value: "Base: 0.01 lotes", color: "text-emerald-400" },
                { label: "Margen Libre", value: "Mínimo 80% preservado", color: "text-blue-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Dar espacio para que la estrategia respire",
            content: [
              "Los mercados retroceden de forma natural antes de continuar su camino. Cuando tu lotaje es moderado, tu cuenta puede absorber la fluctuación sin ningún tipo de estrés ni riesgo de llamada de margen (Margin Call).",
              "El operador consistente no busca duplicar la cuenta en una semana: busca sumar puntos consistentes mes a mes protegiendo el balance."
            ]
          }
        ],
        quiz: {
          id: "quiz-m02-l01",
          badgeText: "EVALUACIÓN DE CAPITAL",
          question: "¿Por qué el sobrelotaje representa el principal peligro de quiebra para una cuenta de trading?",
          options: [
            { id: "A", text: "Porque los brokers cobran multas administrativas a los clientes que usan lotajes superiores a 0.05" },
            { id: "B", text: "Porque MetaTrader 5 desconecta los Asesores Expertos cuando se detecta un volumen alto en el gráfico" },
            { id: "C", text: "Porque satura la memoria RAM del servidor VPS disminuyendo la velocidad de internet" },
            { id: "D", text: "Porque reduce drásticamente el margen libre de la cuenta, haciendo que una oscilación normal del precio active el Stop Out del broker antes de que el bot pueda resolver la posición" }
          ],
          correctAnswerId: "D",
          feedbackExplanation: "¡Correcto! El sobrelotaje asfixia el margen de garantía de la cuenta. Un retroceso común del mercado provocará el cierre forzoso por falta de margen si el tamaño de posición es desmedido."
        }
      },
      {
        id: "m02-l02",
        moduleId: "modulo-02",
        lessonNumber: 2,
        globalIndex: 8,
        title: "Comprender el Drawdown y Flotantes",
        subtitle: "Fluctuación temporal vs pérdida realizada",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "¿Qué es el Drawdown y cómo se evalúa?",
            content: [
              "El Drawdown mide la distancia porcentual entre el punto más alto alcanzado por la cuenta (pico de balance o equidad) y el punto más bajo durante las operaciones abiertas.",
              "Es vital distinguir entre flotante temporal y pérdida definitiva: una posición en flotante negativo aún no está cerrada; el algoritmo utiliza mecanismos de salida rápida y cobertura para cerrarla favorablemente cuando el precio se realinea.",
              "En los backtests oficiales de 2026 de MAIKO PRO GOLD en M5 con corte a las 19:00 los viernes, el drawdown máximo se mantuvo en un conservador 7.05%, demostrando un control de equidad excelente."
            ],
            keyConceptCard: {
              tag: "MÉTRICA CLAVE",
              title: "DRAWDOWN VS RENDIMIENTO",
              items: [
                { label: "Flotante Abierto", value: "Oscilación no realizada", color: "text-amber-400" },
                { label: "Drawdown Máximo", value: "Medida del riesgo histórico", color: "text-red-400" },
                { label: "Recuperación", value: "Retorno a máximos de balance", color: "text-emerald-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m02-l02",
          badgeText: "CONCEPTOS TÉCNICOS",
          question: "¿Cómo se define con exactitud el concepto de 'Drawdown' y qué diferencia al flotante temporal de una pérdida definitiva?",
          options: [
            { id: "A", text: "Es la suma de los swaps nocturnos que el broker retiene al mantener operaciones abiertas de un día para otro" },
            { id: "B", text: "Es la caída porcentual desde el máximo del balance hasta el punto más bajo durante operaciones en curso, que solo se consolida como pérdida real si las órdenes se cierran negativamente" },
            { id: "C", text: "Es el total de comisiones fijas que se pagan al adquirir una licencia de software algorítmico" },
            { id: "D", text: "Es el porcentaje de operaciones con Take Profit que el algoritmo ejecuta en la sesión europea" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! El drawdown refleja la fluctuación temporal de la cuenta. Un sistema maduro tolera fluctuaciones controladas y permite al algoritmo resolver las operaciones sin comprometer el capital global."
        }
      },
      {
        id: "m02-l03",
        moduleId: "modulo-02",
        lessonNumber: 3,
        globalIndex: 9,
        title: "Desbloqueo de tu Cupón 100% y Licencia Demo de 30 Días",
        subtitle: "¡Premio por completar la formación en riesgo!",
        durationMinutes: 4,
        isVip: false,
        isFreeTrialUnlocker: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "¡Premio de Graduación: Tu Cupón 100% Gratuito!",
            content: [
              "Has completado con éxito los módulos formativos sobre fundamentos de mercado, análisis de velas japonesas, tendencias y control de riesgo estricto. ¡Enhorabuena!",
              "Como premio por tu compromiso, has desbloqueado el cupón de descuento del 100% (código: ACADEMIA100) para obtener 1 mes gratis de MAIKO PRO GOLD CLIENT DEMO FIX.",
              "Podrás instalar el bot en tu cuenta DEMO de MetaTrader 5 (en gráfico M5) y comprobar su operativa real sin arriesgar ni un solo céntimo de tu bolsillo. Al mismo tiempo, ¡tus Módulos VIP de instalación técnica quedan desbloqueados a continuación!"
            ],
            keyConceptCard: {
              tag: "CUPÓN DESBLOQUEADO",
              title: "CÓDIGO DE GRADUACIÓN",
              items: [
                { label: "Cupón 100% OFF", value: "ACADEMIA100", color: "text-amber-400" },
                { label: "Producto", value: "MAIKO PRO GOLD CLIENT DEMO FIX", color: "text-emerald-400" },
                { label: "Duración", value: "30 Días de Prueba Completa", color: "text-blue-400" }
              ]
            }
          }
        ]
      }
    ]
  },
  {
    id: "modulo-03",
    moduleNumberStr: "03",
    title: "CÓMO FUNCIONAN LOS BOTS DE TRADING",
    subtitle: "Iniciación al trading automático y servidores",
    description: "Descubre cómo los algoritmos leen los gráficos, ejecutan órdenes 24/7 sin emociones y por qué se utiliza un VPS.",
    isVip: false,
    lessons: [
      {
        id: "m03-l01",
        moduleId: "modulo-03",
        lessonNumber: 1,
        globalIndex: 10,
        title: "Cómo Piensa un Robot de Trading",
        subtitle: "Reglas matemáticas e indicadores técnicos",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Lógica sistemática y frialdad matemática",
            content: [
              "Un Asesor Experto (bot) evalúa continuamente variables cuantitativas en cada tick del mercado: volatilidad del ATR, inclinación de las medias móviles, confirmación de velas M5 y filtros de spread.",
              "Entra al mercado únicamente cuando el 100% de las condiciones preestablecidas se cumplen de manera simultánea. No sufre de cansancio, dudas ni euforia.",
              "A diferencia del ser humano, el bot respeta los límites de riesgo con precisión milimétrica."
            ]
          }
        ],
        quiz: {
          id: "quiz-m03-l01",
          badgeText: "LÓGICA ALGORÍTMICA",
          question: "¿Cuál es la principal ventaja operativa de un algoritmo cuantitativo frente a un operador que ejecuta órdenes de forma manual?",
          options: [
            { id: "A", text: "Que el algoritmo puede negociar de forma secreta para anular el cobro de spreads con el broker" },
            { id: "B", text: "Que el bot predice con certeza absoluta el precio del Oro antes de que abra el mercado" },
            { id: "C", text: "Que el algoritmo ejecuta con frialdad matemática su plan sin dudar, sin codicia y sin cometer el error de venganza tras una racha negativa" },
            { id: "D", text: "Que el bot funciona exclusivamente durante los fines de semana cuando no hay participantes en el mercado" }
          ],
          correctAnswerId: "C",
          feedbackExplanation: "¡Correcto! La disciplina matemática y la ausencia total de sesgos emocionales permiten al bot ejecutar con precisión sistemática cada regla programada."
        }
      },
      {
        id: "m03-l02",
        moduleId: "modulo-03",
        lessonNumber: 2,
        globalIndex: 11,
        title: "¿Qué es MetaTrader 4/5 y una VPS?",
        subtitle: "La infraestructura técnica de un bot",
        durationMinutes: 6,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Servidor VPS y Ejecución 24/7",
            content: [
              "MetaTrader 5 es la plataforma donde se ejecuta el archivo compilado (.EX5) del algoritmo.",
              "Una VPS (Virtual Private Server) es un ordenador en un centro de datos conectado a internet de fibra óptica de ultra-baja latencia con alimentación eléctrica ininterrumpida.",
              "Ejecutar tu bot en una VPS garantiza que las órdenes de protección y salidas se gestionen 24/7 sin depender de si tu ordenador personal está encendido, se suspende o sufre un corte de luz."
            ],
            keyConceptCard: {
              tag: "INFRAESTRUCTURA",
              title: "VENTAJAS DEL VPS",
              items: [
                { label: "Disponibilidad", value: "99.9% Uptime continuo", color: "text-emerald-400" },
                { label: "Latencia Broker", value: "Menor a 15 ms", color: "text-amber-400" },
                { label: "Seguridad", value: "Independiente de tu PC", color: "text-blue-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m03-l02",
          badgeText: "INFRAESTRUCTURA TÉCNICA",
          question: "¿Por qué un servidor VPS (Servidor Privado Virtual) es un componente crítico para operar un algoritmo de trading?",
          options: [
            { id: "A", text: "Porque garantiza una ejecución 24/7 con baja latencia y alta disponibilidad, evitando cortes de luz, desconexiones de red o el apagado involuntario de tu PC" },
            { id: "B", text: "Porque el servidor VPS multiplica automáticamente por 10 el saldo depositado en la cuenta del broker" },
            { id: "C", text: "Porque sin un VPS los brokers no permiten abrir cuentas Demo en MetaTrader 5" },
            { id: "D", text: "Porque los VPS modifican el spread del mercado convirtiendo todas las operaciones en ganadoras" }
          ],
          correctAnswerId: "A",
          feedbackExplanation: "¡Correcto! El VPS asegura continuidad operativa ininterrumpida y proximidad de red a los servidores de liquidez del broker, vital para que el bot gestione el riesgo en todo momento."
        }
      }
    ]
  },
  {
    id: "modulo-04",
    moduleNumberStr: "04",
    title: "PUESTA EN MARCHA DE TU BOT KOPYTRADING",
    subtitle: "Módulo VIP de Instalación y Operativa Práctica",
    description: "Guía técnica paso a paso para la instalación en MetaTrader 5, permisos WebRequest, configuración de lotajes, gestión SOS y protocolo de corte los viernes a las 19:00.",
    isVip: true,
    lessons: [
      {
        id: "m04-l01",
        moduleId: "modulo-04",
        lessonNumber: 1,
        globalIndex: 12,
        title: "Instalación de MetaTrader 5 y Servidor VPS 24/7",
        subtitle: "Cómo garantizar que tu bot ruede sin interrupciones",
        durationMinutes: 8,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Selección del Broker y Tipo de Cuenta",
            content: [
              "Para operar algoritmos en el Oro (XAUUSD) con máxima eficiencia, es prioritario elegir brokers que ofrezcan cuentas con spreads reducidos (cuentas RAW, ECN o cuentas CENT).",
              "Un spread bajo reduce la fricción en cada operación, permitiendo que las órdenes alcancen su objetivo de Take Profit o breakeven con mayor rapidez.",
              "En este primer paso instalamos MetaTrader 5 tanto en tu equipo como en tu VPS de prueba para asegurar una latencia inferior a 20 ms hacia los servidores del broker."
            ],
            keyConceptCard: {
              tag: "CRITERIOS DE BROKER",
              title: "CONDICIONES ÓPTIMAS",
              items: [
                { label: "Tipo de Cuenta", value: "RAW / ECN o CENT", color: "text-amber-400" },
                { label: "Spread en Oro", value: "Inferior a 20-25 puntos", color: "text-emerald-400" },
                { label: "Ejecución", value: "Market Execution sin recotizaciones", color: "text-blue-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Apertura de Cuenta Demo y Conexión",
            content: [
              "1. Descarga el terminal MetaTrader 5 oficial desde tu broker de preferencia.",
              "2. Crea una cuenta Demo con el capital que planeas utilizar en el futuro (por ejemplo, 1.000$ USD o 10.000$ Cent).",
              "3. Inicia sesión con tus credenciales de operador (Login, Contraseña y Servidor) y verifica que el gráfico de XAUUSD cotice en tiempo real."
            ]
          }
        ],
        quiz: {
          id: "quiz-m04-l01",
          badgeText: "EVALUACIÓN TÉCNICA",
          question: "¿Cuál es el criterio técnico más relevante al seleccionar una cuenta y servidor para operar un bot en MetaTrader 5?",
          options: [
            { id: "A", text: "Elegir un apalancamiento superior a 1:3000 para arriesgar el máximo capital en una sola orden" },
            { id: "B", text: "Operar siempre a través de una conexión Wi-Fi pública para mantener el anonimato de la cuenta" },
            { id: "C", text: "Utilizar una cuenta que no permita el uso de órdenes pendientes ni modificaciones de Stop Loss" },
            { id: "D", text: "Contar con un broker con cuentas de spread reducido (RAW/ECN o CENT) y un servidor con latencia inferior a 20 milisegundos" }
          ],
          correctAnswerId: "D",
          feedbackExplanation: "¡Exacto! Los spreads reducidos y la baja latencia de ejecución garantizan que las entradas y salidas del algoritmo se ejecuten al precio óptimo sin deslizamientos perjudiciales."
        }
      },
      {
        id: "m04-l02",
        moduleId: "modulo-04",
        lessonNumber: 2,
        globalIndex: 13,
        title: "Carga del Archivo .EX5 y Permisos WebRequest",
        subtitle: "Instalación del bot en MetaTrader 5",
        durationMinutes: 7,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Cómo instalar el archivo .EX5 en MT5",
            content: [
              "Una vez descargado el bot oficial desde tu panel de Kopytrading, abre MetaTrader 5 y dirígete a Archivo > Abrir Carpeta de Datos.",
              "Navega a la carpeta MQL5 > Experts y pega ahí el archivo ejecutable (.ex5).",
              "Vuelve a la ventana del Navegador en MT5, haz clic derecho sobre Asesores Expertos y pulsa en 'Actualizar'. El bot aparecerá en tu lista."
            ]
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Activación del Trading Algorítmico y WebRequest",
            content: [
              "Para que el bot valide su licencia y pueda abrir operaciones, debes habilitar dos permisos obligatorios:",
              "1. Haz clic en el botón superior de MT5 llamado 'Trading Algorítmico' hasta que el icono muestre un símbolo verde de reproducción ▶️.",
              "2. Ve a Herramientas > Opciones > Expert Advisors, marca 'Permitir WebRequest para las URL listadas' y añade https://kopytrading.com."
            ],
            keyConceptCard: {
              tag: "PERMISOS CRÍTICOS",
              title: "CHECKLIST DE ACTIVACIÓN",
              items: [
                { label: "Trading Algorítmico", value: "Botón superior en VERDE", color: "text-emerald-400" },
                { label: "WebRequest URL", value: "https://kopytrading.com", color: "text-amber-400" },
                { label: "Gráfico", value: "XAUUSD en M5", color: "text-purple-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m04-l02",
          badgeText: "EVALUACIÓN DE PERMISOS",
          question: "¿Por qué es imprescindible autorizar la URL https://kopytrading.com en la pestaña de WebRequest dentro de MetaTrader 5?",
          options: [
            { id: "A", text: "Porque permite al algoritmo conectarse con el servidor de licencias institucional de Kopytrading para validar la clave y autorizar la operativa" },
            { id: "B", text: "Porque de lo contrario MetaTrader 5 bloqueará permanentemente la cuenta de usuario del broker" },
            { id: "C", text: "Porque WebRequest es necesario para descargar los gráficos históricos de velas japonesas del broker" },
            { id: "D", text: "Porque permite al broker enviar publicidad dentro de la ventana de chat del terminal" }
          ],
          correctAnswerId: "A",
          feedbackExplanation: "¡Correcto! La directiva WebRequest autoriza al bot a comunicarse de forma segura con la API de validación para certificar la licencia activa del usuario."
        }
      },
      {
        id: "m04-l03",
        moduleId: "modulo-04",
        lessonNumber: 3,
        globalIndex: 14,
        title: "Configuración de Inputs, Lotajes y Escudo Shield",
        subtitle: "Parámetros de gestión de riesgo según tu capital",
        durationMinutes: 9,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Cálculo del Lotaje Inicial según tu Cuenta",
            content: [
              "Arrastra el bot al gráfico de XAUUSD en temporalidad M5. Aparecerá la ventana de parámetros de entrada (Inputs).",
              "El parámetro primordial es el Lotaje Inicial. La regla institucional de Kopytrading recomienda utilizar 0.01 lotes por cada 1.000$ en cuentas Estándar/USD, o 0.01 por cada 100$ en cuentas Cent.",
              "Introduce tu número de cuenta en el parámetro 'MiLicencia' y carga el archivo .SET optimizado si deseas aplicar los parámetros de fábrica."
            ],
            keyConceptCard: {
              tag: "GESTIÓN DE CAPITAL",
              title: "PROPORCIÓN RECOMENDADA DE LOTAJE",
              items: [
                { label: "Cuenta USD ($1.000)", value: "Lotaje Base: 0.01", color: "text-amber-400" },
                { label: "Cuenta Cent ($100 / 10k cent)", value: "Lotaje Base: 0.01", color: "text-emerald-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Activación del Escudo Diario y Parámetros SOS",
            content: [
              "Nuestros algoritmos incluyen un parámetro de seguridad llamado Escudo Diario o Max Daily Drawdown Limit.",
              "Si el flotante negativo alcanza el porcentaje establecido (por ejemplo, 15%), el algoritmo pausará la apertura de nuevas posiciones para proteger el balance global.",
              "El sistema de cobertura SOS está configurado para buscar un breakeven rápido (0.75$ a 1.00$ de beneficio) en el retroceso, reduciendo la exposición al mercado en el menor tiempo posible."
            ]
          }
        ],
        quiz: {
          id: "quiz-m04-l03",
          badgeText: "EVALUACIÓN DE CONFIGURACIÓN",
          question: "Siguiendo la regla de gestión institucional de Kopytrading, ¿cuál es el dimensionamiento de lotaje inicial recomendado para una cuenta estándar con un saldo de $1,000 USD?",
          options: [
            { id: "A", text: "0.50 lotes para buscar retornos del 100% en las primeras 48 horas de operativa" },
            { id: "B", text: "0.10 lotes, ya que el Oro siempre se mueve en la misma dirección durante la sesión americana" },
            { id: "C", text: "0.01 lotes por cada $1,000 USD para mantener un margen de protección amplio y tolerar retrocesos normales de volatilidad" },
            { id: "D", text: "1.00 lote completo para aprovechar al máximo el apalancamiento que otorga el broker" }
          ],
          correctAnswerId: "C",
          feedbackExplanation: "¡Correcto! 0.01 lotes por cada $1,000 en estándar (o 0.01 por cada $100 en cuentas Cent) preserva el margen y salvaguarda el capital ante movimientos bruscos de volatilidad."
        }
      },
      {
        id: "m04-l04",
        moduleId: "modulo-04",
        lessonNumber: 4,
        globalIndex: 15,
        title: "Monitoreo Diario, Noticias y Protocolo Viernes 19:00",
        subtitle: "Buenas prácticas para mantener la consistencia a largo plazo",
        durationMinutes: 8,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Cómo interpretar la información del Panel en Gráfico (HUD)",
            content: [
              "Cuando el bot está activo en el gráfico M5, verás un panel frontal (HUD) con información clave: Estado del bot (ONLINE), Flotante actual, Operaciones abiertas y Filtro de tendencia activa.",
              "Verifica de un vistazo que en la esquina superior derecha del gráfico aparezca el icono azul del Asesor Experto indicando que AlgoTrading está activado.",
              "Con una revisión diaria de solo 2 minutos es suficiente para verificar que el VPS funcione y que la conexión con el broker sea estable."
            ]
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "El Protocolo de Seguridad de Viernes a las 19:00",
            content: [
              "El mayor peligro para una cuenta de trading en el Oro no es el movimiento intradía, sino los GAPS de apertura de los domingos por la noche generados por noticias geopolíticas de fin de semana.",
              "Nuestros backtests de 2026 confirman que detener nuevas entradas y cerrar posiciones los viernes a las 19:00 (hora del broker) reduce drásticamente el drawdown del 38% a tan solo un 7.05%.",
              "Durante eventos macroeconómicos de Nivel 3 (como el NFP o decisiones de la FED), el algoritmo pausa nuevas órdenes para evitar deslizamientos de precio."
            ],
            keyConceptCard: {
              tag: "DISCIPLINA OPERATIVA",
              title: "REGLAS DE ORO DEL OPERADOR",
              items: [
                { label: "Corte de Viernes", value: "Apagado preventivo a las 19:00", color: "text-amber-400" },
                { label: "Gaps de Fin de Semana", value: "Cero exposición de balance", color: "text-emerald-400" },
                { label: "Monitoreo Diario", value: "Revisión rápida de 2 minutos", color: "text-blue-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m04-l04",
          badgeText: "EVALUACIÓN FINAL DE OPERATIVA",
          question: "¿Cuál es el protocolo de seguridad recomendado ante noticias macroeconómicas de alto impacto y durante los viernes por la tarde?",
          options: [
            { id: "A", text: "Duplicar el lotaje inicial 5 minutos antes de la noticia para capturar el mechazo inicial del precio" },
            { id: "B", text: "Respetar los filtros de noticias del algoritmo, pausar nuevas entradas durante eventos de alta fricción y aplicar el corte de operativa los viernes a las 19:00 para evitar el riesgo de gap en la apertura semanal" },
            { id: "C", text: "Dejar abiertas todas las posiciones durante el fin de semana sin importar el flotante para ahorrar comisiones de apertura" },
            { id: "D", text: "Cerrar manualmente la plataforma y desinstalar el terminal MetaTrader 5 cada vez que haya una noticia" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! Desactivar nuevas entradas en noticias extremas y apagar el algoritmo a las 19:00 los viernes previene deslizamientos por falta de liquidez y protege contra los temidos gaps de apertura de los domingos."
        }
      }
    ]
  }
];

export const TOTAL_LESSONS_COUNT = ACADEMIA_MODULES.reduce((acc, mod) => acc + mod.lessons.length, 0);

export function getLessonById(lessonId: string): { lesson: Lesson; module: Module } | null {
  for (const mod of ACADEMIA_MODULES) {
    const found = mod.lessons.find(l => l.id === lessonId);
    if (found) return { lesson: found, module: mod };
  }
  return null;
}
