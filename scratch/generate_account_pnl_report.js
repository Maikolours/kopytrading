const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

async function main() {
  console.log("=== Generating PnL and Balance History Report from Logs ===");

  // Fetch all sync logs. Since there are 300k+ logs, let's query in batches or select only body and createdAt
  // to avoid loading too much data into memory.
  const batchSize = 50000;
  let skip = 0;
  let hasMore = true;
  
  const accountsData = {};

  console.log("Fetching logs from database (this may take a few seconds)...");
  
  while (hasMore) {
    const logs = await prisma.requestLog.findMany({
      where: {
        path: "/api/sync-positions",
        method: "POST"
      },
      select: {
        body: true,
        createdAt: true
      },
      orderBy: {
        createdAt: "asc" // Process from oldest to newest
      },
      take: batchSize,
      skip: skip
    });

    console.log(`Processed logs ${skip} to ${skip + logs.length}...`);
    
    if (logs.length === 0) {
      hasMore = false;
      break;
    }

    for (const log of logs) {
      if (!log.body) continue;
      try {
        const cleanBody = log.body.replace(/\0/g, '').trim();
        const data = JSON.parse(cleanBody);
        
        const acc = data.account || data.acc || "unknown";
        if (acc === "unknown" || acc === "") continue;

        const balance = parseFloat(data.balance || data.acc_balance || 0);
        const equity = parseFloat(data.equity || data.acc_equity || 0);
        const pnlToday = parseFloat(data.pnl_today || data.profit || data.pnl || 0);
        const isReal = data.isReal !== undefined ? (data.isReal === true || data.isReal === "true") : null;
        const symbol = data.symbol || "unknown";
        const dateStr = log.createdAt.toISOString().split('T')[0]; // YYYY-MM-DD

        if (!accountsData[acc]) {
          accountsData[acc] = {
            account: acc,
            isReal: isReal,
            symbol: symbol,
            firstDate: log.createdAt,
            firstBalance: balance,
            lastDate: log.createdAt,
            lastBalance: balance,
            maxBalance: balance,
            minBalance: balance,
            dailyBalance: {} // Map dateStr -> balance
          };
        }

        // Update latest state
        accountsData[acc].lastDate = log.createdAt;
        accountsData[acc].lastBalance = balance;
        if (isReal !== null) accountsData[acc].isReal = isReal;
        if (symbol !== "unknown") accountsData[acc].symbol = symbol;

        // Max/Min tracking
        if (balance > accountsData[acc].maxBalance) accountsData[acc].maxBalance = balance;
        if (balance < accountsData[acc].minBalance && balance > 0) accountsData[acc].minBalance = balance;

        // Daily tracking (keep the latest balance of each day)
        accountsData[acc].dailyBalance[dateStr] = balance;

      } catch (e) {
        // Parse error, ignore corrupt packets
      }
    }

    if (logs.length < batchSize) {
      hasMore = false;
    } else {
      skip += batchSize;
    }
  }

  console.log("\n=================== FINAL REPORT ===================");

  for (const acc in accountsData) {
    const accInfo = accountsData[acc];
    const netProfit = accInfo.lastBalance - accInfo.firstBalance;
    const pctProfit = accInfo.firstBalance > 0 ? (netProfit / accInfo.firstBalance) * 100 : 0;
    
    console.log(`\nAccount: ${acc} (${accInfo.isReal ? "REAL" : "DEMO/TRIAL"})`);
    console.log(`  Symbol/Instrument: ${accInfo.symbol}`);
    console.log(`  First Record: ${accInfo.firstDate.toISOString()} | Initial Balance: $${accInfo.firstBalance.toFixed(2)}`);
    console.log(`  Last Record: ${accInfo.lastDate.toISOString()} | Current Balance: $${accInfo.lastBalance.toFixed(2)}`);
    console.log(`  Min Balance Reached: $${accInfo.minBalance.toFixed(2)}`);
    console.log(`  Max Balance Reached: $${accInfo.maxBalance.toFixed(2)}`);
    console.log(`  Net Gain/Loss: $${netProfit.toFixed(2)} (${pctProfit.toFixed(2)}%)`);

    // Show daily progress
    const dates = Object.keys(accInfo.dailyBalance).sort();
    console.log(`  Daily balance progression (Total days recorded: ${dates.length}):`);
    
    if (dates.length > 0) {
      // Show first day, last day, and up to 10 spaced-out intermediate days
      const step = Math.max(1, Math.floor(dates.length / 8));
      const displayDates = [];
      displayDates.push(dates[0]); // first
      for (let i = step; i < dates.length - 1; i += step) {
        displayDates.push(dates[i]);
      }
      if (dates.length > 1 && !displayDates.includes(dates[dates.length - 1])) {
        displayDates.push(dates[dates.length - 1]); // last
      }
      
      // Remove duplicates and sort
      const uniqueDisplay = [...new Set(displayDates)].sort();
      for (const d of uniqueDisplay) {
        console.log(`    - ${d}: $${accInfo.dailyBalance[d].toFixed(2)}`);
      }
    }
  }
}

main()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
