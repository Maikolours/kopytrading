const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("=== INSPECCIÓN DETALLADA DE LICENCIAS SAKURA ===");
  
  const purchases = await prisma.purchase.findMany({
    where: {
      userId: { in: ['cmmb2z6ml000dvhhoj1s9zmnf', 'cmn9hfb10000mvhbc3zqbp1lq'] }
    },
    include: {
      user: true,
      botProduct: true,
      activePositions: true,
      botSettings: true
    }
  });

  purchases.forEach(p => {
    console.log(`\nCompra ID: ${p.id}`);
    console.log(`  Usuario: ${p.user.email} (ID: ${p.userId})`);
    console.log(`  Bot: ${p.botProduct.name} (ID: ${p.botProductId})`);
    console.log(`  Último Sinc: ${p.lastSync ? new Date(p.lastSync).toLocaleString('es-ES') : 'NUNCA'}`);
    console.log(`  Balance / Equidad: $${p.balance} / $${p.equity}`);
    console.log(`  Último Estado: ${p.lastStatus}`);
    console.log(`  Posiciones Activas en DB: ${p.activePositions.length}`);
    if (p.activePositions.length > 0) {
      p.activePositions.forEach(pos => {
        console.log(`    - Ticket: ${pos.ticket} | Lote: ${pos.lots} | Simb: ${pos.symbol} | Tipo: ${pos.type} | Profit: ${pos.profit} | Cuenta: ${pos.account}`);
      });
    }
    console.log(`  Ajustes (BotSettings) en DB: ${p.botSettings.length}`);
    if (p.botSettings.length > 0) {
      p.botSettings.forEach(s => {
        try {
          const parsed = JSON.parse(s.settings);
          console.log(`    - Cuenta: ${s.account} | Versión Bot: ${parsed.version} | PnL Hoy: ${parsed.pnl_today}`);
        } catch (e) {
          console.log(`    - Cuenta: ${s.account} | Error parsing settings`);
        }
      });
    }
  });
}

main().catch(console.error).finally(() => prisma.$disconnect());
