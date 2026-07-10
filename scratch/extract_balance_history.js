const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  console.log("=== Extracting Latest Account Statuses from RequestLog ===");

  // Let's fetch the last 15,000 logs of /api/sync-positions
  const logs = await prisma.requestLog.findMany({
    where: {
      path: "/api/sync-positions",
      method: "POST"
    },
    orderBy: {
      createdAt: "desc"
    },
    take: 15000
  });

  console.log(`Fetched ${logs.length} logs for analysis.`);

  const latestAccounts = {};

  for (const log of logs) {
    if (!log.body) continue;
    try {
      // Clean null chars if any
      const cleanBody = log.body.replace(/\0/g, '').trim();
      const data = JSON.parse(cleanBody);
      
      const acc = data.account || data.acc || "unknown";
      if (acc === "unknown" || acc === "") continue;

      if (!latestAccounts[acc]) {
        latestAccounts[acc] = {
          account: acc,
          balance: data.balance || data.acc_balance || 0,
          equity: data.equity || data.acc_equity || 0,
          pnl_today: data.pnl_today || data.profit || data.pnl || 0,
          status: data.status || "UNKNOWN",
          symbol: data.symbol || "UNKNOWN",
          isReal: data.isReal !== undefined ? data.isReal : null,
          version: data.version || "unknown",
          lastSeen: log.createdAt,
          history: []
        };
      }
      
      // Store history for plotting/tallying daily progression (limit to 100 points for memory)
      if (latestAccounts[acc].history.length < 100) {
        latestAccounts[acc].history.push({
          date: log.createdAt,
          balance: data.balance || data.acc_balance || 0,
          equity: data.equity || data.acc_equity || 0,
          pnl_today: data.pnl_today || data.profit || data.pnl || 0
        });
      }
    } catch (e) {
      // Ignore parse errors for corrupt packets
    }
  }

  console.log("\n=== LATEST STATE PER ACCOUNT ===");
  for (const acc in latestAccounts) {
    const info = latestAccounts[acc];
    console.log(`\nAccount: ${info.account} (${info.isReal ? "REAL" : "DEMO/TRIAL"})`);
    console.log(`  Symbol: ${info.symbol} | Version: ${info.version}`);
    console.log(`  Balance: $${info.balance.toFixed(2)}`);
    console.log(`  Equity: $${info.equity.toFixed(2)}`);
    console.log(`  PnL Today: $${info.pnl_today.toFixed(2)}`);
    console.log(`  Status: ${info.status}`);
    console.log(`  Last Updated: ${info.lastSeen.toISOString()}`);
    
    // Show some progression points
    const hist = info.history;
    if (hist.length > 1) {
      console.log(`  Recent progression (last 5 reports):`);
      const sample = hist.slice(0, 5);
      sample.forEach(h => {
        console.log(`    - [${h.date.toISOString()}] Bal: $${h.balance.toFixed(2)} | Equ: $${h.equity.toFixed(2)} | Today PnL: $${h.pnl_today.toFixed(2)}`);
      });
    }
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
