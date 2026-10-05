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
    subtitle: "Módulo VIP de Instalación y Operativa Práctica",
    description: "Guía técnica paso a paso para la instalación de MetaTrader 5, servidor VPS 24/7, permisos de servidor, configuración de lotajes y monitoreo diario.",
    isVip: true,
    lessons: [
      {
        id: "m04-l01",
        moduleId: "modulo-04",
        lessonNumber: 1,
        globalIndex: 10,
        title: "Instalación de MetaTrader 5 y Servidor VPS 24/7",
        subtitle: "Cómo garantizar que tu bot ruede sin interrupciones",
        durationMinutes: 8,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "¿Por qué necesitas un Servidor VPS?",
            content: [
              "Un bot de trading ejecuta reglas matemáticas en tiempo real. Si tu ordenador personal se apaga, pierde la conexión a internet o entra en modo de suspensión, el bot no podrá gestionar las operaciones abiertas ni aplicar sus límites de seguridad.",
              "Un VPS (Virtual Private Server) es un ordenador en la nube optimizado para estar encendido las 24 horas del día, los 365 días del año, con bajísima latencia conectada directamente a los servidores del broker.",
              "En este primer paso instalamos MetaTrader 5 tanto en tu equipo como en tu VPS de prueba para garantizar continuidad operativa absoluta."
            ],
            keyConceptCard: {
              tag: "INFRAESTRUCTURA TÉCNICA",
              title: "REQUISITOS DE OPERATIVA 24/7",
              items: [
                { label: "Disponibilidad", value: "99.9% Uptime sin apagar el PC", color: "text-amber-400" },
                { label: "Latencia", value: "Menos de 15ms hacia el broker", color: "text-emerald-400" }
              ]
            }
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Pasos para abrir tu Cuenta Demo en MT5",
            content: [
              "1. Descarga MetaTrader 5 desde el enlace oficial de tu broker de confianza.",
              "2. Crea una cuenta Demo con el capital que planeas utilizar en el futuro (por ejemplo, 1.000$ o 10.000$ cent).",
              "3. Guarda tus credenciales de inicio de sesión (Número de cuenta, Contraseña de operador y Servidor)."
            ]
          }
        ],
        quiz: {
          id: "quiz-m04-l01",
          badgeText: "EVALUACIÓN TÉCNICA",
          question: "¿Cuál es la función principal de utilizar un servidor VPS para tu bot de trading?",
          options: [
            { id: "A", text: "Garantizar operaciones ganadoras en un 100% sin importar la estrategia" },
            { id: "B", text: "Mantener el bot funcionando 24/7 con baja latencia sin depender de tu PC encendido ni de la luz de tu casa" },
            { id: "C", text: "Duplicar automáticamente el apalancamiento concedido por el broker" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Correcto! El VPS proporciona ejecución ininterrumpida y baja latencia directamente con el servidor del broker."
        }
      },
      {
        id: "m04-l02",
        moduleId: "modulo-04",
        lessonNumber: 2,
        globalIndex: 11,
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
              "Vuelve a la ventana del Navegador en MT5, haz clic derecho sobre Asesores Expertos y pulsa en 'Actualizar'."
            ]
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Activación del Trading Algorítmico y WebRequest",
            content: [
              "Para que el bot valide su licencia y pueda abrir operaciones, debes habilitar dos permisos obligatorios:",
              "1. Haz clic en el botón superior de MT5 llamado 'Trading Algorítmico' hasta que el icono muestre un símbolo verde de reproducción.",
              "2. Ve a Herramientas > Opciones > Expert Advisors, marca 'Permitir WebRequest para las URL listadas' y añade https://kopytrading.com."
            ],
            keyConceptCard: {
              tag: "PERMISOS CRÍTICOS",
              title: "CHECKLIST DE SEGURIDAD MT5",
              items: [
                { label: "Trading Algorítmico", value: "Botón superior en VERDE", color: "text-emerald-400" },
                { label: "WebRequest URL", value: "https://kopytrading.com", color: "text-amber-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m04-l02",
          badgeText: "EVALUACIÓN DE PERMISOS",
          question: "¿Qué ocurre si no agregas https://kopytrading.com en los permisos de WebRequest de MetaTrader 5?",
          options: [
            { id: "A", text: "El bot no podrá conectar con el servidor de licencias para verificar su validez y se detendrá" },
            { id: "B", text: "El broker cerrará la cuenta automáticamente por incumplimiento" },
            { id: "C", text: "El gráfico de MetaTrader 5 cambiará de color" }
          ],
          correctAnswerId: "A",
          feedbackExplanation: "¡Correcto! WebRequest es indispensable para que el bot verifique su clave de activación y autentique la licencia."
        }
      },
      {
        id: "m04-l03",
        moduleId: "modulo-04",
        lessonNumber: 3,
        globalIndex: 12,
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
              "Arrastra el bot al gráfico deseado (por ejemplo XAUUSD en M5). Aparecerá la ventana de parámetros de entrada (Inputs).",
              "El parámetro más importante es el Lotaje Inicial. La regla institucional de Kopytrading recomienda utilizar 0.01 lotes por cada 1.000$ en cuentas Estándar/USD, o 0.01 por cada 100$ en cuentas Cent.",
              "Nunca aumentes el lotaje base para intentar recuperar rachas negativas en poco tiempo."
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
            title: "Activación del Escudo Diario (Daily Shield Stop)",
            content: [
              "Nuestros algoritmos incluyen un parámetro de seguridad llamado Escudo Diario o Max Daily Drawdown Limit.",
              "Si el flotante negativo alcanza el porcentaje establecido (por ejemplo, 5%), el algoritmo detendrá nuevas operaciones durante el resto de la jornada para proteger el balance global de tu cuenta."
            ]
          }
        ],
        quiz: {
          id: "quiz-m04-l03",
          badgeText: "EVALUACIÓN DE CONFIGURACIÓN",
          question: "Para una cuenta Estándar con 1.000$ de balance, ¿cuál es el lotaje inicial recomendado según la regla de conservación de capital?",
          options: [
            { id: "A", text: "0.10 lotes para obtener el máximo beneficio rápido" },
            { id: "B", text: "0.01 lotes para mantener un nivel de riesgo controlado y sostenible" },
            { id: "C", text: "1.00 lote completo para apalancarse al máximo" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Correcto! 0.01 lotes por cada 1.000$ garantiza un margen suficiente para absorber la volatilidad natural del mercado."
        }
      },
      {
        id: "m04-l04",
        moduleId: "modulo-04",
        lessonNumber: 4,
        globalIndex: 13,
        title: "Monitoreo Diario y Operativa en Eventos de Noticias",
        subtitle: "Buenas prácticas para mantener la consistencia a largo plazo",
        durationMinutes: 8,
        isVip: true,
        pages: [
          {
            pageIndex: 1,
            totalPages: 2,
            title: "Cómo interpretar la información del Panel en Gráfico (HUD)",
            content: [
              "Cuando el bot está activo en el gráfico, verás una tabla o panel frontal con información clave: Estado del bot (ONLINE), Flotante actual, Operaciones abiertas y Filtro de tendencia activa.",
              "Verifica de un vistazo que en la esquina superior derecha del gráfico aparezca la carita sonriente o el sombrero azul del Asesor Experto."
            ]
          },
          {
            pageIndex: 2,
            totalPages: 2,
            title: "Gestión durante Noticias de Alto Impacto (IPC, NFP, Tipos de Interés)",
            content: [
              "Durante eventos macroeconómicos de nivel 3 (marcados en rojo en ForexFactory o Investing), la volatilidad del precio puede dispararse de forma impredecible.",
              "Recomendamos revisar el calendario económico semanal. Si el bot cuenta con filtro automático de noticias, déjalo activado; de lo contrario, puedes poner en pausa las nuevas entradas 30 minutos antes y después del dato."
            ],
            keyConceptCard: {
              tag: "DISCIPLINA OPERATIVA",
              title: "REGLAS DE ORO DEL OPERADOR",
              items: [
                { label: "Monitoreo", value: "Revisión diaria de 2 minutos", color: "text-amber-400" },
                { label: "Noticias Nivel 3", value: "Respetar filtros de volatilidad", color: "text-emerald-400" }
              ]
            }
          }
        ],
        quiz: {
          id: "quiz-m04-l04",
          badgeText: "EVALUACIÓN FINAL DE OPERATIVA",
          question: "¿Qué actitud profesional se debe mantener durante una semana de alta volatilidad o noticias macroeconómicas?",
          options: [
            { id: "A", text: "Intervenir manualmente cerrando operaciones con prisa sin respetar las reglas del algoritmo" },
            { id: "B", text: "Respetar los parámetros de riesgo preestablecidos y permitir que el escudo de protección del bot gestione la volatilidad según lo diseñado" },
            { id: "C", text: "Aumentar el lotaje al doble para intentar compensar la volatilidad" }
          ],
          correctAnswerId: "B",
          feedbackExplanation: "¡Excelente! La disciplina y el respeto riguroso al plan matemático son la clave de la consistencia en el trading algorítmico."
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
