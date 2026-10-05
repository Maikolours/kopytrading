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
              "A lo largo de los módulos aprenderás a entender qué son las divisas y el oro, cómo se instala un robot en MetaTrader 4/5, qué es una VPS y cómo mantener la calma cuando hay semanas en números rojos.",
              "Al completar los dos primeros módulos gratuitos, recibirás un pase especial para probar nuestros bots en cuenta demo de forma 100% gratuita."
            ]
          }
        ]
      },
      {
        id: "m00-l02",
        moduleId: "modulo-00",
        lessonNumber: 2,
        globalIndex: 2,
        title: "Expectativas Reales y Semanas Rojas",
        subtitle: "Cómo reaccionar ante la volatilidad",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Las rachas negativas son inevitables",
            content: [
              "En el trading no existe ningún sistema con un 100% de operaciones ganadoras. Los mercados financieros se mueven por eventos macroeconómicos, noticias y liquidez que cambian de un momento a otro.",
              "Un bot profesional está diseñado para ganar puntos en las rachas favorables y limitar las pérdidas cuando el mercado está turbulento. Lo importante es medir el rendimiento en meses, nunca en horas ni en días."
            ]
          }
        ],
        quiz: {
          id: "quiz-m00-l02",
          badgeText: "PRACTICA",
          question: "Tu bot lleva una semana en números rojos por alta volatilidad. ¿Qué es lo más sensato?",
          options: [
            { id: "A", text: "Apagarlo y cambiar toda la configuración de inmediato" },
            { id: "B", text: "Entender que las rachas negativas son normales y mantener tu plan de gestión de riesgo" },
            { id: "C", text: "Subir el lotaje para intentar recuperar lo acumulado rápidamente" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Correcto! Las semanas rojas son parte totalmente normal del trading. Lo crucial es mantener tu gestión de riesgo inalterada y evaluar los resultados a largo plazo."
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
              "Vamos a empezar por lo más básico, sin prisa. El trading es, en palabras sencillas, comprar algo a un precio y venderlo cuando su valor cambia para quedarte con la diferencia.",
              "Piénsalo como un puesto de fruta. Si compras naranjas a 10 y las vendes a 13, obtienes 3 de rendimiento. El trading es la misma idea, pero en lugar de fruta, se compran y venden monedas de países (como el Dólar o el Euro) o activos de refugio como el Oro.",
              "No necesitas tener los billetes físicamente. Todo se realiza desde una pantalla con un programa en tu teléfono o computadora."
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
        ]
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
          question: "¿Por qué el Oro (XAUUSD) requiere parámetros de riesgo específicos en los bots?",
          options: [
            { id: "A", text: "Porque el Oro nunca cambia de precio" },
            { id: "B", text: "Porque es un activo de alta volatilidad con impulsos fuertes que requieren lotajes controlados" },
            { id: "C", text: "Porque los bots no pueden leer el gráfico del Oro" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! El Oro se mueve con mucha fuerza, por lo que ajustar el lotaje y usar Stop Loss de protección es fundamental para cuidar el capital."
        }
      },
      {
        id: "m01-l03",
        moduleId: "modulo-01",
        lessonNumber: 3,
        globalIndex: 5,
        title: "Desbloqueo de tu Prueba Gratuita",
        subtitle: "¡Felicidades por completar el módulo inicial!",
        durationMinutes: 4,
        isVip: false,
        isFreeTrialUnlocker: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Tu premio por completar los fundamentos",
            content: [
              "Has completado la introducción y los fundamentos de los mercados. ¡Enhorabuena!",
              "Como prometimos, ahora estás listo para probar uno de nuestros robots en entorno seguro de prueba (Demo) sin ningún coste ni compromiso."
            ]
          }
        ]
      }
    ]
  },
  {
    id: "modulo-02",
    moduleNumberStr: "02",
    title: "TU ROBOT DE TRADING",
    subtitle: "Instalación y configuración",
    description: "Aprende a configurar MetaTrader 4/5, conectar una VPS y poner a rodar tu primer algoritmo.",
    isVip: false,
    lessons: [
      {
        id: "m02-l01",
        moduleId: "modulo-02",
        lessonNumber: 1,
        globalIndex: 6,
        title: "¿Qué es MetaTrader 4 y MetaTrader 5?",
        subtitle: "La plataforma estándar de la industria",
        durationMinutes: 5,
        isVip: false,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "El conector con el mercado",
            content: [
              "MetaTrader es el programa donde se conectan tu cuenta de corretaje (Broker) y tu robot de trading.",
              "El bot se instala en MetaTrader como un 'Expert Advisor' (EA) y lee el gráfico segundo a segundo para ejecutar las órdenes automáticamente."
            ]
          }
        ]
      },
      {
        id: "m02-l02",
        moduleId: "modulo-02",
        lessonNumber: 2,
        globalIndex: 2,
        title: "Instalación del Robot Maiko Bayesian",
        subtitle: "Paso a paso para cargar el archivo .ex5",
        durationMinutes: 8,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Cargar el EA en MetaTrader 5",
            content: [
              "1. Abre MT5 y haz clic en Archivo > Abrir Carpeta de Datos.",
              "2. Entra en MQL5 > Experts y pega el archivo Maiko_PRO.ex5.",
              "3. Reinicia MT5 o actualiza el navegador de Expert Advisors.",
              "4. Arrastra el bot al gráfico de XAUUSD en temporalidad H1 y activa 'Permitir Trading Algorítmico'."
            ]
          }
        ]
      }
    ]
  },
  {
    id: "modulo-03",
    moduleNumberStr: "03",
    title: "ESTRATEGIA Y OPERACIÓN",
    subtitle: "Operar como un profesional",
    description: "Profundiza en la estrategia bayesiana, backtesting y psicología aplicada al trading automático.",
    isVip: true,
    lessons: [
      {
        id: "m03-l01",
        moduleId: "modulo-03",
        lessonNumber: 1,
        globalIndex: 8,
        title: "La Estrategia Bayesian Explicada",
        subtitle: "Filtros matemáticos de alta probabilidad",
        durationMinutes: 7,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 1,
            title: "Lógica probabilística",
            content: [
              "La estrategia bayesiana calcula la probabilidad condicional de que una dirección continúe evaluando el RSI y la volatilidad histórica.",
              "Esto reduce las falsas entradas en momentos de consolidación de precio."
            ]
          }
        ]
      },
      {
        id: "m03-l02",
        moduleId: "modulo-03",
        lessonNumber: 2,
        globalIndex: 9,
        title: "Gestión de Riesgo y Control de Lotaje",
        subtitle: "Ajuste seguro según el balance de tu cuenta",
        durationMinutes: 6,
        isVip: true,
        quiz: {
          id: "quiz-m03-l02",
          badgeText: "EVALUACIÓN VIP",
          question: "Si tu cuenta tiene $500 y el manual del bot sugiere 0.01 lotes por cada $500, ¿cuál es el lotaje correcto?",
          options: [
            { id: "A", text: "0.10 lotes para acelerar los puntos" },
            { id: "B", text: "0.01 lotes exactamente para cumplir la gestión estricta" },
            { id: "C", text: "0.05 lotes según si el mercado parece subir" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Correcto! Respetar el lotaje recomendado es la única forma de garantizar la supervivencia del capital a largo plazo."
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
