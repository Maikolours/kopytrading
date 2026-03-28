const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const newBots = [
    {
      productKey: 'XAU-MG',
      name: 'AMETRALLADORA 🔥 (XAUUSD)',
      description: 'Algoritmo de alta frecuencia especializado en Oro. Agresivo y optimizado para máxima rentabilidad en sesiones volátiles.',
      instrument: 'XAUUSD',
      strategyType: 'HFT / Scalping',
      riskLevel: 'HIGH',
      price: 149.00,
      originalPrice: 299.00,
      version: 'v1.0',
      isActive: true,
      timeframes: 'M5, M15',
      minCapital: 250.0
    },
    {
      productKey: 'BTC-SR',
      name: 'STORM RIDER ⚡ (BTCUSD)',
      description: 'Bot conservador para Bitcoin. Captura tendencias institucionales con un control de Drawdown estricto.',
      instrument: 'BTCUSD',
      strategyType: 'Trend Following',
      riskLevel: 'LOW',
      price: 99.00,
      originalPrice: 199.00,
      version: 'v1.0',
      isActive: true,
      timeframes: 'H1, H4',
      minCapital: 500.0
    },
    {
      productKey: 'JPY-NG',
      name: 'NINJA GHOST 🥷 (USDJPY)',
      description: 'Especialista en el par Yen. Movimientos furtivos y precisión quirúrgica para capitalizar la volatilidad del BoJ.',
      instrument: 'USDJPY',
      strategyType: 'Precision Scalping',
      riskLevel: 'MEDIUM',
      price: 99.00,
      originalPrice: 149.00,
      version: 'v1.0',
      isActive: true,
      timeframes: 'M15, M30',
      minCapital: 200.0
    },
    {
      productKey: 'EUR-EPF',
      name: 'EURO PRECISION FLOW 🎯 (EURUSD)',
      description: 'Bot estable para el par Euro/Dólar. Basado en liquidez institucional y flujos de capital constantes.',
      instrument: 'EURUSD',
      strategyType: 'Institutional Flow',
      riskLevel: 'LOW',
      price: 99.00,
      originalPrice: 149.00,
      version: 'v1.0',
      isActive: true,
      timeframes: 'M30, H1',
      minCapital: 100.0
    }
  ];

  console.log('--- Iniciando Seed de Nuevos Productos DeepSeek ---');

  for (const bot of newBots) {
    const existing = await prisma.botProduct.findUnique({
      where: { productKey: bot.productKey }
    });

    if (existing) {
      console.log(`Bot ${bot.productKey} ya existe. Saltando...`);
    } else {
      await prisma.botProduct.create({ data: bot });
      console.log(`✅ Bot ${bot.productKey} (${bot.name}) creado con éxito.`);
    }
  }

  console.log('--- Proceso Finalizado ---');
}

main()
  .catch(e => {
    console.error('Error en el seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
