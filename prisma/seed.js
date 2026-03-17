const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
    // Limpiar base de datos para evitar duplicados
    await prisma.purchase.deleteMany({});
    await prisma.botProduct.deleteMany({});

    const bots = [
        {
            name: 'La Ametralladora Evolution 🔥 (v5.54)',
            description: '🚀 **¡EL PRÓXIMO LANZAMIENTO MÁS ESPERADO!**\n\n🛡️ **El bot más agresivo del mercado del Oro.** Rediseñado con meta inteligente y stop de seguridad. No te pierdas el lanzamiento oficial. Permanece atento a esta página para el cronómetro final.\n\n⚡ **Ficha Técnica:** Gestión de Hedge avanzada y meta de profit inteligente.',
            instrument: 'XAUUSD',
            strategyType: 'Scalping Inteligente',
            riskLevel: 'Medium',
            price: 249.00,
            version: '5.54',
            timeframes: 'M15 (Recomendado), M5',
            minCapital: 1000,
            ex5FilePath: '/uploads/KOPYTRADE_XAUUSD_Ametralladora_Evolution.mq5',
            pdfFilePath: '/uploads/Manual_Ametralladora.pdf',
            isActive: true,
            status: 'UPCOMING',
        },
        {
            name: 'Euro Precision Flow 🎯 (EURUSD)',
            description: '🛠️ **EN MANTENIMIENTO TÉCNICO**\n\n📈 Estamos optimizando el Scalper Europeo para adaptarlo a las nuevas condiciones del mercado. Volverá a estar disponible muy pronto con mayor precisión y filtrado de noticias.',
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
            status: 'MAINTENANCE',
        },
        {
            name: 'Yen Ninja Ghost 🥷 (USDJPY)',
            description: '🛠️ **EN MANTENIMIENTO TÉCNICO**\n\n🌙 Optimizando la operativa para la sesión asiática. El Ninja Ghost está siendo recalibrado para mejorar el ratio de acierto en rangos de volatilidad baja.',
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
            status: 'MAINTENANCE',
        },
        {
            name: 'BTC Storm Rider ⚡ (BTCUSD)',
            description: '🔥 **¡YA QUEDA MENOS! EL REY DEL BITCOIN VUELVE.**\n\n₿ Detecta rupturas de rango tras acumulaciones de energía. La versión 6.6 está a punto de ver la luz con una gestión monetaria aún más sagrada.\n\n⚡ **No te pierdas el lanzamiento.** Unidades de licencia limitadas para el primer lote.',
            instrument: 'BTCUSD',
            strategyType: 'Breakout Confirmado',
            riskLevel: 'Medium',
            price: 299.00,
            version: '6.6',
            timeframes: 'H1 (Recomendado), M30',
            minCapital: 2000,
            ex5FilePath: '/uploads/KOPYTRADE_BTCUSD_BTCStormRider_v6.6.mq5',
            pdfFilePath: '/uploads/Manual_BTCStormRider.pdf',
            isActive: true,
            status: 'UPCOMING',
        },
        {
            name: 'GoldSentinel Pro 🛡️ (XAUUSD)',
            description: '🛠️ **EN MANTENIMIENTO TÉCNICO**\n\n🧠 El sistema de Multi-Confirmación trend-following está siendo actualizado con nuevos filtros ATR dinámicos para el 2026.',
            instrument: 'XAUUSD',
            strategyType: 'Multi-Confirmación Trend',
            riskLevel: 'Medium',
            price: 69.00,
            version: '1.0',
            timeframes: 'M30 (Recomendado), H1',
            minCapital: 500,
            ex5FilePath: '/uploads/KOPYTRADE_XAUUSD_GoldSentinelPro.mq5',
            pdfFilePath: '/uploads/Manual_GoldSentinelPro.pdf',
            isActive: true,
            status: 'MAINTENANCE',
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
