const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
    // Limpiar base de datos para evitar duplicados
    await prisma.purchase.deleteMany({});
    await prisma.botProduct.deleteMany({});

    const bots = [
        {
            name: 'La Ametralladora 🔥 (XAUUSD)',
            description: '🛡️ **El bot más agresivo del mercado del Oro (v2.1).** Diseñado exclusivamente para XAUUSD, dispara entradas en M15 aprovechando la volatilidad del Oro con una velocidad de scalping inigualable. Su motor de "Escudo Inteligente" coloca automáticamente la protección en la dirección correcta, y el "Cycle Cleaner" limpia el terreno para volver a disparar.\n\n⚡ **Ficha Técnica TURBO:** Ahora con parámetros estandarizados y guía técnica integrada.',
            instrument: 'XAUUSD',
            strategyType: 'Scalping Inteligente con Hedge',
            riskLevel: 'Medium',
            price: 249.00,
            version: '2.1',
            timeframes: 'M15 (Recomendado), M5 (Agresivo)',
            minCapital: 1000,
            ex5FilePath: '/uploads/KOPYTRADE_XAUUSD_Ametralladora.mq5',
            pdfFilePath: '/uploads/Manual_Ametralladora.pdf',
            isActive: true,
        },
        {
            name: 'Euro Precision Flow 🎯 (EURUSD)',
            description: '📈 **El Scalper Europeo más preciso (v2.0 Turbo).** Captura cruces de tendencia milimétricos con EMA 5/13 + Filtro RSI para una actividad extrema de hasta 8-10 operaciones diarias.\n\n🛡️ **Seguridad interior:** Break Even y Trailing Stop configurables desde la pestaña de Inputs.',
            instrument: 'EURUSD',
            strategyType: 'EMA Cross Tendencial',
            riskLevel: 'Low',
            price: 179.00,
            version: '2.0',
            timeframes: 'H1 (Recomendado), H4',
            minCapital: 500,
            ex5FilePath: '/uploads/KOPYTRADE_EURUSD_EuroPrecisionFlow.mq5',
            pdfFilePath: '/uploads/Manual_EuroPrecisionFlow.pdf',
            isActive: true,
        },
        {
            name: 'Yen Ninja Ghost 🥷 (USDJPY)',
            description: '🌙 **Trabaja mientras el mundo duerme (v2.0).** Especializado en la sesión asiática (Tokio). Usa Bandas de Bollinger + RSI para detectar rebotes técnicos con una precisión quirúrgica.\n\n⏰ **Horario de operación:** 00:00 - 08:00 (Hora Broker).',
            instrument: 'USDJPY',
            strategyType: 'Bollinger Bands Rebote',
            riskLevel: 'Medium',
            price: 149.00,
            version: '2.0',
            timeframes: 'M30 (Recomendado), H1',
            minCapital: 500,
            ex5FilePath: '/uploads/KOPYTRADE_USDJPY_YenNinjaGhost.mq5',
            pdfFilePath: '/uploads/Manual_YenNinjaGhost.pdf',
            isActive: true,
        },
        {
            name: 'BTC Storm Rider ⚡ (BTCUSD)',
            description: '₿ **Cabalga la tormenta de Bitcoin (v2.0).** Detecta rupturas de rango tras acumulaciones de energía. Bitcoin requiere gestión monetaria sagrada; este bot la tiene integrada.\n\n🔥 **Breakout Pro:** Rango optimizado de 24 velas en temporalidad M30.',
            instrument: 'BTCUSD',
            strategyType: 'Breakout Confirmado Multi-Filtro',
            riskLevel: 'Medium',
            price: 299.00,
            version: '3.0',
            timeframes: 'H1 (Recomendado), M30',
            minCapital: 2000,
            ex5FilePath: '/uploads/KOPYTRADE_BTCUSD_BTCStormRider.mq5',
            pdfFilePath: '/uploads/Manual_BTCStormRider.pdf',
            isActive: true,
        },
        {
            name: 'GoldSentinel Pro 🛡️ (XAUUSD)',
            description: '🧠 **Inteligencia Adaptativa para el Oro (v1.0).** El bot más inteligente de KOPYTRADE. Utiliza un sistema de Multi-Confirmación con 4 indicadores simultáneos (EMA200, EMA21/55, RSI, ATR) para encontrar solo las entradas de máxima probabilidad.\\n\\n📊 **Gestión ATR Dinámica:** Stop Loss y Take Profit se adaptan automáticamente a la volatilidad real del mercado. Sin grid, sin martingala. 1 operación limpia con ratio Riesgo:Beneficio 1:2.\\n\\n⏰ **Sesiones Inteligentes:** Solo opera durante Londres y Nueva York, las horas más rentables para el Oro.',
            instrument: 'XAUUSD',
            strategyType: 'Multi-Confirmación Trend Following',
            riskLevel: 'Medium',
            price: 69.00,
            version: '1.0',
            timeframes: 'M30 (Recomendado), H1',
            minCapital: 500,
            ex5FilePath: '/uploads/KOPYTRADE_XAUUSD_GoldSentinelPro.mq5',
            pdfFilePath: '/uploads/Manual_GoldSentinelPro.pdf',
            isActive: true,
        }
    ];

    for (const bot of bots) {
        await prisma.botProduct.create({ data: bot });
    }

    // Listado de correos que tendrán acceso de desarrollador (eterno)
    const devEmails = ["user@example.com", "viajaconsakura@gmail.com", "viajaconsakura"];
    const hashedPassword = await require('bcryptjs').hash("123456", 10);
    const createdBots = await prisma.botProduct.findMany();

    for (const email of devEmails) {
        // Upsert para no fallar si ya existe el usuario
        const user = await prisma.user.upsert({
            where: { email },
            update: {},
            create: {
                email,
                name: email.split("@")[0],
                password: hashedPassword,
            },
        });

        // Darle acceso eterno a todos los bots
        for (const bot of createdBots) {
            await prisma.purchase.create({
                data: {
                    userId: user.id,
                    botProductId: bot.id,
                    amount: 0,
                    status: "TRIAL",
                    expiresAt: new Date(Date.now() + 100 * 365 * 24 * 60 * 60 * 1000) // 100 años
                }
            });
        }
    }

    console.log(`✅ Seed exitoso: Bots generados y ${devEmails.length} cuentas de DEV activadas con acceso eterno!`);
}

main()
    .catch((e) => { console.error(e); process.exit(1); })
    .finally(async () => { await prisma.$disconnect(); });
