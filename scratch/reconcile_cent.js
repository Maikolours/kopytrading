const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

const orderToDeal = {}; // orderId -> { dealId, type, lot, symbol, price }
const closeToOpen = {}; // closeOrderId -> openOrderId

// Phase 1: Parse all lines
lines.forEach(line => {
    // 1. Link orders to deals
    // Trades   '23449251': deal #853660271 sell 0.01 XAUUSD-STDc at 4560.50 done (based on order #907597127)
    const dealMatch = line.match(/deal #(\d+)\s+(buy|sell)\s+([\d.]+)\s+(\S+)\s+at\s+([\d.]+)\s+done\s+\(based\s+on\s+order\s+#(\d+)\)/);
    if (dealMatch) {
        const dealId = dealMatch[1];
        const type = dealMatch[2];
        const lot = parseFloat(dealMatch[3]);
        const symbol = dealMatch[4];
        const price = parseFloat(dealMatch[5]);
        const orderId = dealMatch[6];
        orderToDeal[orderId] = { dealId, type, lot, symbol, price };
    }

    // 2. Link close orders to open orders
    // Trades   '23449251': market sell 0.01 XAUUSD-STDc, close #907587433 buy 0.01 XAUUSD-STDc 4558.19 placed for execution
    // Or: Trades   '23449251': market sell 0.01 XAUUSD-STDc, close #907587433 buy 0.01 XAUUSD-STDc 4558.19
    const closeMatch = line.match(/close\s+#(\d+)/);
    if (closeMatch) {
        const openOrderId = closeMatch[1];
        // The line also contains order #... that placed it
        const placingOrderMatch = line.match(/order\s+#(\d+)/);
        if (placingOrderMatch) {
            const closeOrderId = placingOrderMatch[1];
            closeToOpen[closeOrderId] = openOrderId;
        } else {
            // Let's find the closing order by context or keep looking
            // Usually, a line like: accepted market sell 0.02 XAUUSD-STDc, close #907193428 buy 0.02 XAUUSD-STDc 4593.17
            // is followed by placing order #...
        }
    }
});

// Let's look for system lines that link close order to open order more reliably:
// e.g. "accepted market sell 0.01 XAUUSD-STDc, close #907587433 buy 0.01 XAUUSD-STDc 4558.19"
// followed by "order #907597127 sell 0.01 / 0.01 XAUUSD-STDc at market done"
// Let's do a sliding window search or check all close and order lines.
for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.includes('close #')) {
        const openMatch = line.match(/close\s+#(\d+)/);
        if (openMatch) {
            const openOrderId = openMatch[1];
            // Look ahead up to 10 lines for "order #<closeOrderId> ... done"
            for (let j = i; j < Math.min(i + 15, lines.length); j++) {
                const aheadLine = lines[j];
                const closeOrderMatch = aheadLine.match(/order\s+#(\d+)\s+(buy|sell)/);
                if (closeOrderMatch) {
                    const closeOrderId = closeOrderMatch[1];
                    closeToOpen[closeOrderId] = openOrderId;
                    break;
                }
            }
        }
    }
}

console.log(`Parsed ${Object.keys(orderToDeal).length} deals and linked ${Object.keys(closeToOpen).length} close-to-open relationships.`);

console.log("\n=== COMPLETED RECONCILIATION ===");
let totalEstimatedProfit = 0;
const reconciledDeals = [];

Object.keys(closeToOpen).forEach(closeOrderId => {
    const openOrderId = closeToOpen[closeOrderId];
    const openDeal = orderToDeal[openOrderId];
    const closeDeal = orderToDeal[closeOrderId];
    
    if (openDeal && closeDeal) {
        // We have both open and close deals!
        const lot = openDeal.lot;
        const symbol = openDeal.symbol;
        const openPrice = openDeal.price;
        const closePrice = closeDeal.price;
        const type = openDeal.type;
        
        // Gold/XAUUSD pip value calculation:
        // 1 point in gold = 0.01 (e.g. 4558.19 to 4560.50 is 2.31 dollars in gold price per oz)
        // Profit in cents (USC) = (ClosePrice - OpenPrice) * Lot * 100 (for buy) or (OpenPrice - ClosePrice) * Lot * 100 (for sell)
        // Since XAUUSD contract size is 100 oz per 1 lot:
        // Profit = Diff * Lot * 100
        const diff = (type === 'buy') ? (closePrice - openPrice) : (openPrice - closePrice);
        const profit = diff * lot * 100;
        
        reconciledDeals.push({
            openOrderId,
            closeOrderId,
            type,
            lot,
            symbol,
            openPrice,
            closePrice,
            profit
        });
        totalEstimatedProfit += profit;
    }
});

reconciledDeals.forEach(d => {
    console.log(`Position: #${d.openOrderId} | Type: ${d.type} | Lot: ${d.lot} | Open: ${d.openPrice} | Close: ${d.closePrice} | Profit: ${d.profit.toFixed(2)} USC`);
});

console.log(`\nEstimated Total Closed Profit Today: ${totalEstimatedProfit.toFixed(2)} USC (${(totalEstimatedProfit / 100).toFixed(2)} USD)`);
