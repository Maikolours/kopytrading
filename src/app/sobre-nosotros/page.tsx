import Link from "next/link";
import { Metadata } from "next";
import {
    Terminal,
    Cpu,
    Code2,
    ShieldCheck,
    CheckCircle2,
    ArrowRight,
    Scale,
    AlertTriangle,
    Layers,
    Lock,
    Clock,
    Sparkles,
    Activity,
    Check,
    X,
    Server,
    BarChart3
} from "lucide-react";

export const metadata: Metadata = {
    title: "Sobre Nosotros | KopyTrading - De la Ingeniería de Software a la Automatización Algorítmica",
    description: "No venimos del trading manual, sino de la ingeniería de software y la creación de automatizaciones complejas. Diseñamos algoritmos cuantitativos para MetaTrader 5 que eliminan el desgaste psicológico y las emociones.",
    keywords: [
        "sobre nosotros kopytrading",
        "trading algorítmico",
        "ingeniería de software trading",
        "bots metatrader 5",
        "expert advisors mt5",
        "automatización de trading",
        "transparencia trading bots",
        "trading sin emociones"
    ],
    alternates: {
        canonical: "https://www.kopytrading.com/sobre-nosotros",
    },
    openGraph: {
        title: "Sobre Nosotros | KopyTrading - Ingeniería y Algoritmos MT5",
        description: "No venimos del trading, sino de la ingeniería de software y la automatización. Construimos robots para MT5 que ejecutan estrategias precisas sin sesgo emocional.",
        url: "https://www.kopytrading.com/sobre-nosotros",
        type: "website",
    },
};

export default function SobreNosotrosPage() {
    const aboutSchema = {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "AboutPage",
                "@id": "https://www.kopytrading.com/sobre-nosotros#webpage",
                "url": "https://www.kopytrading.com/sobre-nosotros",
                "name": "Sobre Nosotros | KopyTrading - De la Ingeniería de Software a la Automatización Algorítmica",
                "description": "No venimos del sector del trading, sino de la ingeniería de software y la creación de automatizaciones complejas. Vimos que el trading manual es extremadamente difícil y psicológicamente agotador (requiere años de estudio), así que decidimos aplicar nuestra verdadera especialidad: construir robots y algoritmos que automaticen el proceso sin emociones.",
                "isPartOf": {
                    "@id": "https://www.kopytrading.com/#website"
                },
                "about": {
                    "@id": "https://www.kopytrading.com/#organization"
                },
                "inLanguage": "es-ES",
                "mainEntity": {
                    "@type": "Organization",
                    "@id": "https://www.kopytrading.com/#organization",
                    "name": "KopyTrading",
                    "url": "https://www.kopytrading.com",
                    "logo": "https://www.kopytrading.com/logo-kopytrading.png",
                    "description": "Plataforma tecnológica especializada en ingeniería de software, arquitectura algorítmica y sistemas automatizados para MetaTrader 5.",
                    "knowsAbout": [
                        "Ingeniería de Software",
                        "Trading Algorítmico",
                        "MetaTrader 5 MQL5",
                        "Automatización de Procesos Críticos",
                        "Gestión Cuantitativa de Riesgo",
                        "Backtesting y Modelado Estadístico"
                    ],
                    "sameAs": [
                        "https://t.me/Kpytrading",
                        "https://www.facebook.com/profile.php?id=61591397057399"
                    ]
                }
            },
            {
                "@type": "BreadcrumbList",
                "@id": "https://www.kopytrading.com/sobre-nosotros#breadcrumb",
                "itemListElement": [
                    {
                        "@type": "ListItem",
                        "position": 1,
                        "name": "Inicio",
                        "item": "https://www.kopytrading.com"
                    },
                    {
                        "@type": "ListItem",
                        "position": 2,
                        "name": "Sobre Nosotros",
                        "item": "https://www.kopytrading.com/sobre-nosotros"
                    }
                ]
            }
        ]
    };

    return (
        <div className="min-h-screen pt-24 md:pt-32 pb-24 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
            {/* Schema.org JSON-LD para E-E-A-T */}
            <script
                type="application/ld+json"
                dangerouslySetInnerHTML={{ __html: JSON.stringify(aboutSchema) }}
            />

            {/* Fondos radiales difuminados de marca (Dark Mode & Purple Glows) */}
            <div className="absolute top-16 right-0 w-[550px] h-[550px] bg-brand/10 blur-[150px] rounded-full pointer-events-none mix-blend-screen" />
            <div className="absolute top-[40%] left-[-100px] w-[500px] h-[500px] bg-accent/5 blur-[160px] rounded-full pointer-events-none mix-blend-screen" />
            <div className="absolute bottom-10 right-1/4 w-[450px] h-[450px] bg-brand/10 blur-[140px] rounded-full pointer-events-none mix-blend-screen" />

            <div className="max-w-5xl mx-auto z-10 relative space-y-16 sm:space-y-20">
                {/* Navegación y Encabezado */}
                <div>
                    <Link
                        href="/"
                        className="inline-flex items-center gap-2 text-sm text-text-muted hover:text-white transition-colors mb-6 group"
                    >
                        <span className="group-hover:-translate-x-1 transition-transform">←</span> Volver al inicio
                    </Link>

                    <div className="space-y-4">
                        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-brand/10 border border-brand/30 text-brand-light text-xs font-semibold uppercase tracking-wider">
                            <span className="w-2 h-2 rounded-full bg-brand animate-pulse"></span>
                            Ingeniería de Software & Algoritmos MT5
                        </div>
                        <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-extrabold tracking-tight text-white leading-tight">
                            De la Ingeniería de Software a la{" "}
                            <span className="text-transparent bg-clip-text bg-gradient-to-r from-brand via-brand-light to-white">
                                Automatización Algorítmica
                            </span>
                        </h1>
                        <p className="text-base sm:text-lg text-text-muted max-w-3xl leading-relaxed">
                            Cambiamos el agotamiento de las pantallas y los sesgos emocionales del trading manual por arquitectura de código robusta, disciplina matemática y ejecución milimétrica en MetaTrader 5.
                        </p>
                    </div>
                </div>

                {/* Manifesto Block (Mandatory Narrative Card) */}
                <section className="relative glass-card border-brand/30 bg-gradient-to-b from-brand/15 via-surface/80 to-black p-6 sm:p-8 md:p-10 rounded-3xl shadow-[0_25px_60px_rgba(0,0,0,0.85)] overflow-hidden">
                    <div className="absolute -top-24 -right-24 w-72 h-72 bg-brand/20 blur-[90px] pointer-events-none rounded-full" />
                    
                    {/* Barra de cabecera estilo Terminal de Ingeniería */}
                    <div className="flex items-center justify-between border-b border-white/10 pb-4 mb-6 text-xs text-text-muted font-mono">
                        <div className="flex items-center gap-2">
                            <span className="w-3 h-3 rounded-full bg-red-500/80 inline-block"></span>
                            <span className="w-3 h-3 rounded-full bg-amber-500/80 inline-block"></span>
                            <span className="w-3 h-3 rounded-full bg-green-500/80 inline-block"></span>
                            <span className="ml-2 text-slate-300 hidden sm:inline">~/kopytrading/philosophy/manifesto.md</span>
                        </div>
                        <div className="flex items-center gap-1.5 text-brand-light font-semibold">
                            <Terminal className="w-3.5 h-3.5" />
                            <span>DECLARACIÓN FUNDACIONAL</span>
                        </div>
                    </div>

                    {/* Cita textual exacta requerida */}
                    <blockquote className="text-lg sm:text-xl md:text-2xl font-medium text-white leading-relaxed tracking-tight border-l-4 border-brand pl-4 sm:pl-6 my-4 italic">
                        “No venimos del sector del trading, sino de la ingeniería de software y la creación de automatizaciones complejas. Vimos que el trading manual es extremadamente difícil y psicológicamente agotador (requiere años de estudio), así que decidimos aplicar nuestra verdadera especialidad: construir robots y algoritmos que automaticen el proceso sin emociones.”
                    </blockquote>

                    {/* Firma técnica & sello de confianza */}
                    <div className="mt-8 pt-5 border-t border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 rounded-xl bg-brand/20 border border-brand/40 flex items-center justify-center text-brand-light font-mono font-bold text-sm">
                                &lt;/&gt;
                            </div>
                            <div>
                                <div className="font-semibold text-white text-sm">Equipo de Ingeniería KopyTrading</div>
                                <div className="text-xs text-slate-400">Arquitectura de Software & MQL5 Cuantitativo</div>
                            </div>
                        </div>
                        <div className="inline-flex items-center gap-2 text-brand-light text-xs font-medium bg-brand/10 px-3.5 py-2 rounded-xl border border-brand/20 self-start sm:self-auto">
                            <ShieldCheck className="w-4 h-4 text-brand" />
                            <span>Transparencia Radical & Cero Humo</span>
                        </div>
                    </div>
                </section>

                {/* Nuestra Historia: Expansión y Contraste Real */}
                <section className="space-y-8">
                    <div className="border-b border-white/10 pb-4">
                        <h2 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
                            Nuestra Historia: La Realidad Frente a la Falsa Ilusión
                        </h2>
                        <p className="text-brand-light text-sm font-medium mt-1">
                            Por qué las matemáticas y el software vencen al desgaste mental del operador humano
                        </p>
                    </div>

                    <div className="grid md:grid-cols-2 gap-8 text-text-muted leading-relaxed text-sm sm:text-base">
                        <div className="space-y-4">
                            <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                                <Cpu className="w-5 h-5 text-brand" /> El Mito del Trader Manual Infalible
                            </h3>
                            <p>
                                Casi todos los que se adentran en los mercados financieros escuchan las mismas promesas vacías: "aprende patrones de velas, domina tu mentalidad con 15 minutos al día y gana dinero desde tu teléfono". Pero la cruda realidad que descubrimos al operar manualmente es demoledora.
                            </p>
                            <p>
                                El trading manual exige años de estudio ininterrumpido, jornadas de 6 a 10 horas analizando gráficos y, sobre todo, una carga psicológica destructiva. Pasar horas viendo fluctuar tu capital genera ansiedad, insomnio, miedo al error (*FOMO*) y revancha ante las pérdidas. El 90% de los operadores minoristas no pierden por falta de teoría, sino porque la mente humana está biológicamente programada para fallar cuando hay dinero y emociones en juego.
                            </p>
                        </div>

                        <div className="space-y-4">
                            <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                                <Code2 className="w-5 h-5 text-brand" /> Nuestra Especialidad: Ingeniería y Sistemas
                            </h3>
                            <p>
                                Nuestro punto de partida nunca fueron las tertulias financieras ni los cursos de vendehumos. Venimos del sector de la ingeniería de software: desarrollo de sistemas backend distribuidos, pipelines automatizados tolerantes a fallos y programación de algoritmos de alta fidelidad.
                            </p>
                            <p>
                                Al analizar el mercado con ojos de ingeniero, el dilema quedó claro: el mercado financiero es un flujo constante de datos numéricos y probabilidades. En lugar de quemar nuestra salud mental forzando a un cerebro humano a actuar como una máquina, decidimos hacer lo que mejor sabemos hacer: <strong className="text-white">construir software especializado que ejecute reglas matemáticas estrictas sin miedo, sin fatiga y sin vacilaciones</strong>.
                            </p>
                        </div>
                    </div>
                </section>

                {/* Tabla Visual Comparativa: Trading Manual vs. Algoritmos KopyTrading */}
                <section className="space-y-6">
                    <div className="text-center max-w-2xl mx-auto space-y-2">
                        <h2 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
                            Trading Manual vs. Automatización KopyTrading
                        </h2>
                        <p className="text-sm text-text-muted">
                            Una comparación honesta entre el esfuerzo humano no escalable y la ejecución algorítmica
                        </p>
                    </div>

                    <div className="grid md:grid-cols-2 gap-6">
                        {/* Trading Manual Card */}
                        <div className="glass-card p-6 sm:p-8 rounded-2xl border-red-500/20 bg-red-950/10 space-y-5">
                            <div className="flex items-center justify-between border-b border-red-500/20 pb-4">
                                <div className="space-y-1">
                                    <h3 className="text-xl font-bold text-white">Trading Manual</h3>
                                    <p className="text-xs text-red-300 font-medium">El Desgaste Psicológico Humano</p>
                                </div>
                                <span className="w-10 h-10 rounded-full bg-red-500/10 border border-red-500/30 flex items-center justify-center text-red-400 font-bold">
                                    <X className="w-5 h-5" />
                                </span>
                            </div>

                            <ul className="space-y-3.5 text-sm text-slate-300">
                                <li className="flex items-start gap-3">
                                    <span className="text-red-400 mt-0.5">✕</span>
                                    <span><strong>Desgaste psicológico brutal:</strong> Estrés crónico, ansiedad en rachas negativas y euforia desmedida en las positivas.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-red-400 mt-0.5">✕</span>
                                    <span><strong>Esclavitud de tiempo:</strong> Requiere estar 4 a 8 horas diarias encadenado a la pantalla buscando oportunidades.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-red-400 mt-0.5">✕</span>
                                    <span><strong>Sesgo de revancha:</strong> Mover o quitar el Stop Loss por miedo a perder, llevando a la quiebra de cuentas.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-red-400 mt-0.5">✕</span>
                                    <span><strong>Ejecución tardía:</strong> Latencia biológica humana de segundos a minutos frente a movimientos súbitos.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <span className="text-red-400 mt-0.5">✕</span>
                                    <span><strong>Curva de aprendizaje:</strong> Años de frustración y pérdidas de capital previas sin garantía alguna de consistencia.</span>
                                </li>
                            </ul>
                        </div>

                        {/* Algoritmos KopyTrading Card */}
                        <div className="glass-card p-6 sm:p-8 rounded-2xl border-brand/30 bg-brand/5 space-y-5 shadow-[0_10px_40px_rgba(168,85,247,0.15)] relative">
                            <div className="absolute top-0 right-0 w-32 h-32 bg-brand/10 blur-[50px] pointer-events-none rounded-full" />
                            <div className="flex items-center justify-between border-b border-white/10 pb-4">
                                <div className="space-y-1">
                                    <h3 className="text-xl font-bold text-white">Algoritmos KopyTrading</h3>
                                    <p className="text-xs text-brand-light font-medium">Ingeniería de Software Aplicada</p>
                                </div>
                                <span className="w-10 h-10 rounded-full bg-brand/20 border border-brand/40 flex items-center justify-center text-brand-light font-bold">
                                    <Check className="w-5 h-5" />
                                </span>
                            </div>

                            <ul className="space-y-3.5 text-sm text-slate-200">
                                <li className="flex items-start gap-3">
                                    <CheckCircle2 className="w-4 h-4 text-brand-light shrink-0 mt-0.5" />
                                    <span><strong>Cero sesgos emocionales:</strong> No siente miedo, codicia ni necesidad de venganza; solo ejecuta código matemático.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <CheckCircle2 className="w-4 h-4 text-brand-light shrink-0 mt-0.5" />
                                    <span><strong>Operativa 24/5 en VPS:</strong> El bot vigila el mercado sin interrupción mientras tú trabajas, descansas o duermes.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <CheckCircle2 className="w-4 h-4 text-brand-light shrink-0 mt-0.5" />
                                    <span><strong>Disciplina milimétrica:</strong> Gestión de lotaje automática, colocación estricta de Stop Loss y protección Break Even.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <CheckCircle2 className="w-4 h-4 text-brand-light shrink-0 mt-0.5" />
                                    <span><strong>Ejecución en milisegundos:</strong> Respuestas instantáneas en MetaTrader 5 ante condiciones de liquidez óptimas.</span>
                                </li>
                                <li className="flex items-start gap-3">
                                    <CheckCircle2 className="w-4 h-4 text-brand-light shrink-0 mt-0.5" />
                                    <span><strong>Pruebas cuantitativas masivas:</strong> Estrategias verificadas con millones de ticks históricos y pruebas forward en tiempo real.</span>
                                </li>
                            </ul>
                        </div>
                    </div>
                </section>

                {/* Los 4 Pilares de E-E-A-T: Confianza, Autoridad y Transparencia Radical */}
                <section className="space-y-8">
                    <div className="space-y-2">
                        <div className="inline-flex items-center gap-2 text-xs font-semibold text-brand uppercase tracking-wider">
                            <Scale className="w-4 h-4" /> Principios Inquebrantables
                        </div>
                        <h2 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
                            Nuestros 4 Pilares de Confianza y Transparencia
                        </h2>
                        <p className="text-text-muted text-sm sm:text-base max-w-2xl">
                            La reputación no se construye con promesas vacías, sino con datos reales, código probado y transparencia radical sobre los riesgos.
                        </p>
                    </div>

                    <div className="grid sm:grid-cols-2 gap-6">
                        {/* Pilar 1 */}
                        <div className="glass-card p-6 sm:p-7 rounded-2xl border-white/10 space-y-3 hover:border-brand/40 transition-colors">
                            <div className="w-12 h-12 rounded-xl bg-brand/15 border border-brand/30 flex items-center justify-center text-brand-light">
                                <Sparkles className="w-6 h-6" />
                            </div>
                            <h3 className="text-lg font-bold text-white">1. Transparencia Radical (Cero Venta de Humo)</h3>
                            <p className="text-sm text-text-muted leading-relaxed">
                                No te mostraremos capturas de pantallas falsificadas ni te prometeremos rentabilidades imposibles. Ningún bot es infalible. Hablamos abiertamente del <strong>DrawDown máximo</strong>, de los periodos de consolidación y de la volatilidad en activos como el Oro (XAUUSD) o Bitcoin. Preferimos perder una venta antes que mentir sobre la naturaleza del mercado.
                            </p>
                        </div>

                        {/* Pilar 2 */}
                        <div className="glass-card p-6 sm:p-7 rounded-2xl border-white/10 space-y-3 hover:border-brand/40 transition-colors">
                            <div className="w-12 h-12 rounded-xl bg-brand/15 border border-brand/30 flex items-center justify-center text-brand-light">
                                <Code2 className="w-6 h-6" />
                            </div>
                            <h3 className="text-lg font-bold text-white">2. Código Nativo en MQL5 y Modelado Real</h3>
                            <p className="text-sm text-text-muted leading-relaxed">
                                No revendemos plantillas de terceros ni sistemas obsoletos. Todo nuestro catálogo se programa y compila de forma nativa para <strong>MetaTrader 5</strong>, empleando filtros dinámicos de spread, control de deslizamiento (slippage) y horarios de volatilidad optimizados mediante backtesting con calidad de datos de modelado del 99.9%.
                            </p>
                        </div>

                        {/* Pilar 3 */}
                        <div className="glass-card p-6 sm:p-7 rounded-2xl border-white/10 space-y-3 hover:border-brand/40 transition-colors">
                            <div className="w-12 h-12 rounded-xl bg-brand/15 border border-brand/30 flex items-center justify-center text-brand-light">
                                <Lock className="w-6 h-6" />
                            </div>
                            <h3 className="text-lg font-bold text-white">3. Custodia 100% en Tus Manos</h3>
                            <p className="text-sm text-text-muted leading-relaxed">
                                Jamás custodiamos ni gestionamos capital de terceros. Tu dinero permanece siempre en tu cuenta personal dentro del broker regulado que elijas. Nuestro software es una herramienta informática que tú descargas, instalas y configuras, manteniendo en todo momento la potestad absoluta sobre tus fondos.
                            </p>
                        </div>

                        {/* Pilar 4 */}
                        <div className="glass-card p-6 sm:p-7 rounded-2xl border-white/10 space-y-3 hover:border-brand/40 transition-colors">
                            <div className="w-12 h-12 rounded-xl bg-brand/15 border border-brand/30 flex items-center justify-center text-brand-light">
                                <ShieldCheck className="w-6 h-6" />
                            </div>
                            <h3 className="text-lg font-bold text-white">4. Soporte Técnico y Acompañamiento Real</h3>
                            <p className="text-sm text-text-muted leading-relaxed">
                                El software de calidad requiere soporte de calidad. No te dejamos solo con un archivo descargado: ofrecemos guías paso a paso en PDF, presets configurados de bajo, medio y alto riesgo, y canal de atención directa para resolver cualquier duda sobre VPS o la terminal MT5.
                            </p>
                        </div>
                    </div>
                </section>

                {/* Metodología de Desarrollo: Ciclo de Vida del Software */}
                <section className="space-y-8 glass-card p-6 sm:p-10 rounded-3xl border-white/10 bg-surface/50">
                    <div className="space-y-2">
                        <div className="inline-flex items-center gap-2 text-xs font-semibold text-brand-light uppercase tracking-wider">
                            <Layers className="w-4 h-4" /> Proceso de Ingeniería
                        </div>
                        <h2 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
                            Cómo Diseñamos y Validamos Cada Algoritmo
                        </h2>
                        <p className="text-text-muted text-sm sm:text-base max-w-2xl">
                            Aplicamos los mismos estándares de calidad que rigen el software empresarial de misión crítica.
                        </p>
                    </div>

                    <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6 pt-4">
                        {/* Paso 1 */}
                        <div className="space-y-3 border-l-2 border-brand/40 pl-4">
                            <div className="text-xs font-mono font-bold text-brand uppercase tracking-wider">Paso 01</div>
                            <h3 className="text-base font-bold text-white">Hipótesis Cuantitativa</h3>
                            <p className="text-xs text-text-muted leading-relaxed">
                                Análisis estadístico de anomalías de liquidez, correlación entre sesiones y niveles institucionales en Oro, Cripto y Forex.
                            </p>
                        </div>

                        {/* Paso 2 */}
                        <div className="space-y-3 border-l-2 border-brand/40 pl-4">
                            <div className="text-xs font-mono font-bold text-brand uppercase tracking-wider">Paso 02</div>
                            <h3 className="text-base font-bold text-white">Codificación en MQL5</h3>
                            <p className="text-xs text-text-muted leading-relaxed">
                                Programación orientada a objetos con control de memoria optimizado, filtros de spread dinámico y preservación de margen.
                            </p>
                        </div>

                        {/* Paso 3 */}
                        <div className="space-y-3 border-l-2 border-brand/40 pl-4">
                            <div className="text-xs font-mono font-bold text-brand uppercase tracking-wider">Paso 03</div>
                            <h3 className="text-base font-bold text-white">Stress-Testing 99.9%</h3>
                            <p className="text-xs text-text-muted leading-relaxed">
                                Pruebas con datos históricos reales sometiendo el algoritmo a picos de noticias de alto impacto (NFP, IPC, tipos de interés).
                            </p>
                        </div>

                        {/* Paso 4 */}
                        <div className="space-y-3 border-l-2 border-brand/40 pl-4">
                            <div className="text-xs font-mono font-bold text-brand uppercase tracking-wider">Paso 04</div>
                            <h3 className="text-base font-bold text-white">Validación Forward</h3>
                            <p className="text-xs text-text-muted leading-relaxed">
                                Monitoreo en cuentas reales y demo durante meses antes del despliegue público, garantizando consistencia en condiciones vivas.
                            </p>
                        </div>
                    </div>
                </section>

                {/* Aviso de Riesgo y Responsabilidad Honesta (E-E-A-T Essential) */}
                <section className="glass-card p-6 sm:p-8 rounded-2xl border-amber-500/20 bg-amber-950/10 space-y-4">
                    <div className="flex items-center gap-3 text-accent font-semibold text-base">
                        <AlertTriangle className="w-5 h-5 text-accent shrink-0" />
                        <h3>Aviso Legal de Riesgo y Declaración de Transparencia</h3>
                    </div>
                    <p className="text-xs sm:text-sm text-text-muted leading-relaxed">
                        El comercio en mercados financieros con instrumentos apalancados (como Forex, CFDs sobre Oro e Índices o Criptoactivos) conlleva un nivel de riesgo elevado que puede derivar en la pérdida parcial o total de los fondos depositados.
                    </p>
                    <p className="text-xs sm:text-sm text-text-muted leading-relaxed">
                        <strong className="text-white">KopyTrading no es una entidad financiera, gestora de fondos ni entidad de asesoramiento de inversiones.</strong> Comercializamos software informático y herramientas tecnológicas de automatización para su uso privado en la plataforma MetaTrader 5. Los rendimientos históricos analizados en backtesting o cuentas de demostración no constituyen una garantía de resultados futuros. Recomendamos encarecidamente utilizar configuraciones de riesgo moderadas y probar cualquier herramienta en cuentas de demostración o con capital centavo antes de operar en entornos reales.
                    </p>
                </section>

                {/* Llamado a la Acción (CTA) */}
                <div className="text-center pt-8 border-t border-white/10 space-y-6">
                    <div className="space-y-2">
                        <h2 className="text-2xl sm:text-3xl font-bold text-white">
                            ¿Listo para delegar la operativa en software probado?
                        </h2>
                        <p className="text-sm text-text-muted max-w-xl mx-auto">
                            Descubre nuestros bots para MetaTrader 5, revisa sus métricas y comienza a operar con disciplina matemática.
                        </p>
                    </div>

                    <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                        <Link
                            href="/bots"
                            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-brand text-white font-bold hover:bg-brand-dark transition-all duration-300 shadow-[0_0_30px_rgba(168,85,247,0.3)] hover:scale-105 flex items-center justify-center gap-2"
                        >
                            <span>Ver Bots Disponibles</span>
                            <ArrowRight className="w-4 h-4" />
                        </Link>
                        <Link
                            href="/como-funciona"
                            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-white/5 text-white font-semibold hover:bg-white/10 border border-white/10 transition-all flex items-center justify-center gap-2"
                        >
                            <span>Cómo Funciona</span>
                        </Link>
                        <Link
                            href="/faq"
                            className="w-full sm:w-auto px-8 py-4 rounded-2xl bg-transparent text-text-muted hover:text-white transition-colors text-sm"
                        >
                            Preguntas Frecuentes
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}

