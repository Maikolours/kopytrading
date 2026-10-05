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
    description: "Comprende qué es el trading algorítmico, por qué la gestión de riesgo lo es todo y cómo evitar los errores del principiante.",
    isVip: false,
    lessons: [
      {
        id: "m00-l01",
        moduleId: "modulo-00",
        lessonNumber: 1,
        globalIndex: 1,
        title: "Bienvenido a Kopytrading Academy",
        subtitle: "Aprende a operar con bots sin magia ni engaños",
        durationMinutes: 3,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "¿Por qué estamos aquí?",
            content: [
              "La mayoría de las personas que llegan al trading algorítmico lo hacen buscando rentabilidad mágica de la noche a la mañana. Ese es el primer error que arruina cuentas.",
              "Un bot de trading no es una lámpara maravillosa: es un programa informático que ejecuta reglas de matemática y estadística a alta velocidad sin emociones humanas.",
              "En esta academia vas a aprender cómo funciona un algoritmo, cómo evaluar su comportamiento y cómo gestionar el riesgo como un profesional."
            ],
            keyConceptCard: {
              tag: "REGLA NÚMERO 1",
              title: "LA REALIDAD DEL ALGORITMO",
              items: [
                { label: "Bot de Trading", value: "Ejecutor de matemática pura", color: "text-amber-400" },
                { label: "Control de Riesgo", value: "El verdadero secreto de la consistencia", color: "text-emerald-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "¿Qué aprenderás en este curso?",
            content: [
              "A lo largo de los módulos aprenderás a entender qué son las divisas y el oro, cómo se gestiona el capital, cómo funcionan los bots en MetaTrader y cómo mantener la calma cuando hay semanas de alta volatilidad.",
              "Al completar los módulos gratuitos, recibirás un pase especial para probar nuestros bots en cuenta demo de forma 100% gratuita."
            ]
          }
        ],
        quiz: {
          id: "quiz-m00-l01",
          badgeText: "EVALUACIÓN INICIAL",
          question: "¿Cuál es la función real de un bot de trading algorítmico?",
          options: [
            { id: "A", text: "Garantizar rentabilidades fijas todos los días sin ningún tipo de riesgo" },
            { id: "B", text: "Ejecutar reglas matemáticas y de gestión de riesgo programadas sin caer en emociones humanas" },
            { id: "C", text: "Predecir las noticias macroeconómicas antes de que sucedan" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Correcto! Un bot de trading no es magia; es una herramienta informática que ejecuta reglas matemáticas con disciplina perfecta y sin caer en el miedo o la codicia."
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
            totalPages: 1,
            title: "Las rachas negativas son inevitables",
            content: [
              "En el trading no existe ningún sistema con un 100% de operaciones ganadoras. Los mercados financieros se mueven por eventos macroeconómicos, noticias y liquidez que cambian de un momento a otro.",
              "Un bot profesional está diseñado para ganar puntos en las rachas favorables y limitar las pérdidas cuando el mercado está turbulento. Lo importante es medir el rendimiento en ventanas de varios meses, nunca en horas ni en días."
            ]
          }
        ],
        quiz: {
          id: "quiz-m00-l02",
          badgeText: "PRACTICA",
          question: "Si el mercado presenta alta volatilidad y tu cuenta experimenta un flotante negativo temporal, ¿cuál es la conducta más sensata?",
          options: [
            { id: "A", text: "Apagar el bot presa del pánico y cambiar los parámetros sin criterio" },
            { id: "B", text: "Mantener la calma, evaluar el rendimiento en plazos de varios meses y respetar la gestión de riesgo calibrada" },
            { id: "C", text: "Subir el lotaje para intentar recuperar las pérdidas rápidamente" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! El trading algorítmico se evalúa en plazos de semanas y meses. Respetar la gestión de riesgo inalterada es la clave para la supervivencia del capital."
        }
      }
    ]
  },
  {
    id: "modulo-01",
    moduleNumberStr: "01",
    title: "MERCADOS: FOREX Y ORO",
    subtitle: "Cómo funcionan los activos",
    description: "Conoce las dinámicas del mercado de divisas y el comportamiento del Oro (XAUUSD).",
    isVip: false,
    lessons: [
      {
        id: "m01-l01",
        moduleId: "modulo-01",
        lessonNumber: 1,
        globalIndex: 3,
        title: "¿Qué es el mercado y el trading?",
        subtitle: "Conceptos básicos explicados con sencillez",
        durationMinutes: 6,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "La idea base del trading",
            content: [
              "Vamos a empezar por lo más básico, sin prisa. El trading es, en palabras sencillas, comprar o vender un activo financiero cuando su valor cambia para aprovechar la diferencia a tu favor.",
              "Piénsalo como un puesto de fruta. Si compras naranjas a 10 y las vendes a 13, obtienes 3 de rendimiento. El trading es la misma idea, pero en lugar de fruta, se compran y venden monedas de países (como el Dólar o el Euro) o activos de refugio como el Oro.",
              "No necesitas tener las monedas físicamente. Todo se realiza desde una pantalla con un programa en tu teléfono o computadora."
            ],
            keyConceptCard: {
              tag: "EJEMPLO PRÁCTICO",
              title: "LA IDEA BASE DEL TRADING",
              items: [
                { label: "Precio Compra", value: "$10.00", color: "text-blue-400" },
                { label: "Precio Venta", value: "$13.00", color: "text-emerald-400" },
                { label: "Diferencia", value: "+$3.00 Rendimiento", color: "text-amber-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Mercado Forex y Pares de Divisas",
            content: [
              "El mercado Forex es el mercado financiero más grande del mundo. Se negocian pares como EUR/USD (Euro frente al Dólar).",
              "Los robots de trading monitorean estos pares buscando patrones repetitivos basados en indicadores matemáticos como el RSI, medias móviles o análisis bayesiano."
            ]
          }
        ],
        quiz: {
          id: "quiz-m01-l01",
          badgeText: "EVALUACIÓN",
          question: "¿Cómo se genera un resultado positivo al comerciar con divisas u oro en el mercado?",
          options: [
            { id: "A", text: "Comprando o vendiendo un activo y aprovechando la variación a tu favor entre el precio de entrada y salida" },
            { id: "B", text: "Esperando a que el broker te pague intereses fijos anuales" },
            { id: "C", text: "Comprando monedas físicas y guardándolas en un banco" }
          ],
          correctAnswerId: "A",
          feedbackExplanation: "¡Correcto! El trading consiste en aprovechar las variaciones de precio en los activos financieros mediante plataformas digitales como MetaTrader."
        }
      },
      {
        id: "m01-l02",
        moduleId: "modulo-01",
        lessonNumber: 2,
        globalIndex: 4,
        title: "El Oro (XAUUSD) como Activo de Volatilidad",
        subtitle: "Características especiales del activo rey",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Operar con Oro",
            content: [
              "El Oro (XAUUSD) es uno de los activos más populares para bots porque realiza movimientos limpios y amplios.",
              "Sin embargo, debido a su alta volatilidad, requiere una gestión de lotaje cuidadosa y filtros de protección ante noticias de impacto económico."
            ]
          }
        ],
        quiz: {
          id: "quiz-m01-l02",
          badgeText: "PRACTICA",
          question: "¿Por qué el Oro (XAUUSD) es un activo tan apreciado para operar con bots pero exige parámetros estrictos?",
          options: [
            { id: "A", text: "Porque el precio del Oro jamás cambia de valor" },
            { id: "B", text: "Porque ofrece impulsos y volatilidad muy amplios, lo que exige ajustar el lotaje para proteger el saldo" },
            { id: "C", text: "Porque MetaTrader solo permite instalar bots en el gráfico del Oro" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! El Oro realiza movimientos limpios pero muy potentes, por lo que ajustar el volumen (lotaje) es esencial para no sobrecargar la cuenta."
        }
      }
    ]
  },
  {
    id: "modulo-02",
    moduleNumberStr: "02",
    title: "GESTIÓN DE RIESGO Y CONTROL DE CAPITAL",
    subtitle: "Reglas fundamentales de supervivencia",
    description: "Aprende a proteger tu dinero y a calcular el volumen adecuado según el saldo de tu cuenta.",
    isVip: false,
    lessons: [
      {
        id: "m02-l01",
        moduleId: "modulo-02",
        lessonNumber: 1,
        globalIndex: 5,
        title: "El Mayor Enemigo del Trader: El Sobrelotaje",
        subtitle: "Por qué arriesgar de más arruina cualquier cuenta",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Volumen y Lotaje",
            content: [
              "El sobrelotaje ocurre cuando abres operaciones demasiado grandes para el saldo de tu cuenta.",
              "Si tienes una cuenta de $500 y abres lotes como si tuvieras $5,000, cualquier pequeño movimiento en contra acabará consumiendo tu capital.",
              "La regla de oro es mantener un volumen moderado para que la cuenta pueda respirar durante los retrocesos del mercado."
            ]
          }
        ],
        quiz: {
          id: "quiz-m02-l01",
          badgeText: "EVALUACIÓN DE RIESGO",
          question: "¿Qué significa 'sobrelotarse' y por qué representa el principal peligro para un principiante?",
          options: [
            { id: "A", text: "Configurar el bot en el gráfico equivocado" },
            { id: "B", text: "Usar un volumen de lote demasiado alto para el saldo de la cuenta, dejando sin margen de respiración al capital" },
            { id: "C", text: "Tener la computadora encendida durante la noche" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Correcto! El sobrelotaje consumirá cualquier cuenta ante un retroceso normal del mercado. Conservar lotajes moderados garantiza consistencia."
        }
      },
      {
        id: "m02-l02",
        moduleId: "modulo-02",
        lessonNumber: 2,
        globalIndex: 6,
        title: "Comprender el Drawdown y Flotantes",
        subtitle: "Pérdida temporal no realizada",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "¿Qué es el Drawdown?",
            content: [
              "El Drawdown es la diferencia entre el punto más alto del saldo de tu cuenta y el punto más bajo alcanzado durante las operaciones abiertas.",
              "Un flotante negativo no es una pérdida definitiva hasta que la operación se cierra. Un bot bien calibrado gestiona el flotante esperando a que el mercado vuelva a favor."
            ]
          }
        ],
        quiz: {
          id: "quiz-m02-l02",
          badgeText: "CONCEPTOS TÉCNICOS",
          question: "¿Qué es el 'Drawdown' en la operativa de un algoritmo de trading?",
          options: [
            { id: "A", text: "El beneficio total retirado al banco al final del mes" },
            { id: "B", text: "La diferencia entre el pico máximo del saldo y la caída temporal producida por operaciones abiertas" },
            { id: "C", text: "La comisión que cobra el broker por cada operación" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! El Drawdown mide la fluctuación o flotante temporal de la cuenta mientras las posiciones están en curso antes de cerrarse."
        }
      },
      {
        id: "m02-l03",
        moduleId: "modulo-02",
        lessonNumber: 3,
        globalIndex: 7,
        title: "Desbloqueo de tu Prueba Gratuita de Bot",
        subtitle: "¡Premio por completar la formación en riesgo!",
        durationMinutes: 4,
        isVip: false,
        isFreeTrialUnlocker: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "¡Premio de Graduación!",
            content: [
              "Has completado la formación fundamental sobre mercados y gestión de riesgo. ¡Enhorabuena!",
              "Como premio por tu compromiso, ya puedes reclamar tu pase de prueba gratuita para ver actuar a nuestros bots en entorno Demo de forma 100% segura."
            ]
          }
        ]
      }
    ]
  },
  {
    id: "modulo-03",
    moduleNumberStr: "03",
    title: "CÓMO FUNCIONAN LOS BOTS DE TRADING",
    subtitle: "Iniciación al trading automático",
    description: "Descubre cómo los algoritmos leen los gráficos y ejecutan órdenes 24/7 sin emociones.",
    isVip: false,
    lessons: [
      {
        id: "m03-l01",
        moduleId: "modulo-03",
        lessonNumber: 1,
        globalIndex: 8,
        title: "Cómo Piensa un Robot de Trading",
        subtitle: "Reglas matemáticas e indicadores técnicos",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Lógica sin emociones",
            content: [
              "Un bot de trading analiza los datos del gráfico (precios, volatilidad, medias móviles, RSI) y decide entrar al mercado únicamente cuando se cumplen el 100% de las condiciones programadas.",
              "A diferencia del ser humano, el bot no siente miedo, avaricia ni impulso de venganza tras una racha mala."
            ]
          }
        ]
      },
      {
        id: "m03-l02",
        moduleId: "modulo-03",
        lessonNumber: 2,
        globalIndex: 9,
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
              "MetaTrader es el programa donde rueda el bot. Una VPS (Servidor Privado Virtual) es una computadora en la nube que permite que el bot funcione 24 horas al día sin necesidad de dejar tu ordenador personal encendido."
            ]
          }
        ],
        quiz: {
          id: "quiz-m03-l02",
          badgeText: "INFRAESTRUCTURA TÉCNICA",
          question: "¿Por qué es recomendable ejecutar un bot en una VPS (Servidor Privado Virtual) en lugar de tu PC convencional?",
          options: [
            { id: "A", text: "Porque la VPS garantiza que todas las operaciones sean ganadoras" },
            { id: "B", text: "Porque la VPS funciona 24/7 con baja latencia y sin depender de que tu PC esté encendido o sufra cortes de luz e internet" },
            { id: "C", text: "Porque MetaTrader no se puede instalar en computadoras de escritorio" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Correcto! La VPS proporciona continuidad, estabilidad de conexión y velocidad de ejecución ininterrumpida para tus bots."
        }
      }
    ]
  },
  {
    id: "modulo-04",
    moduleNumberStr: "04",
    title: "PUESTA EN MARCHA DE TU BOT KOPYTRADING",
    subtitle: "Solo para usuarios con Bot contratado",
    description: "Módulo exclusivo de instalación y parámetros de configuración (En actualización según el bot oficial seleccionado).",
    isVip: true,
    lessons: [
      {
        id: "m04-l01",
        moduleId: "modulo-04",
        lessonNumber: 1,
        globalIndex: 10,
        title: "Instalación del Bot en MetaTrader 5",
        subtitle: "Paso a paso para cargar el bot oficial",
        durationMinutes: 8,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Instalación del Bot Oficial",
            content: [
              "Este contenido estará personalizado paso a paso para el robot oficial contratado.",
              "En este módulo aprenderás a instalar el archivo .ex5 en MetaTrader 5, vincular tu número de cuenta y activar el botón de Trading Algorítmico."
            ]
          }
        ]
      },
      {
        id: "m04-l02",
        moduleId: "modulo-04",
        lessonNumber: 2,
        globalIndex: 11,
        title: "Ajuste de Parámetros e Inputs del Panel",
        subtitle: "Configuración según tu capital inicial",
        durationMinutes: 7,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Configuración de Inputs",
            content: [
              "Aprenderás a ajustar el perfil de riesgo (Conservador, Balanceado o Agresivo), el lotaje base y la activación del Escudo Shield Diario."
            ]
          }
        ]
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
