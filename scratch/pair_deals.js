const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

const positions = {}; // map of ticket -> open deal info
const closedTrades = [];

lines.forEach(line => {
    // Look for deals: deal #<id> <type> <lot> <symbol> at <price> done (based on order #<orderId>)
    if (line.includes('deal #')) {
        const dealMatch = line.match(/deal #(\d+)\s+(buy|sell)\s+([\d.]+)\s+(\S+)\s+at\s+([\d.]+)/);
        if (dealMatch) {
            const dealId = dealMatch[1];
            const type = dealMatch[2];
            const lot = parseFloat(dealMatch[3]);
            const symbol = dealMatch[4];
            const price = parseFloat(dealMatch[5]);
            
            // Check if this is a close deal by checking if the line contains 'close #<ticket>'
            const closeMatch = line.match(/close #(\d+)/);
            if (closeMatch) {
                const openTicket = closeMatch[1];
                const openDeal = positions[openTicket];
                if (openDeal) {
                    // We found the matching open deal!
                    const pips = (type === 'sell') ? (price - openDeal.price) : (openDeal.price - price);
                    // In XAUUSD, 1 point = 0.01. So pips = diff * 10
                    const profit = pips * lot * 100; // rough estimation in cents (1 lot = 100 oz, so profit = diff * lot * 100)
                    closedTrades.push({
                        openTicket,
                        openPrice: openDeal.price,
                        closePrice: price,
                        lot,
                        symbol,
                        type: openDeal.type,
                        time: line.substring(0, 12).trim(),
                        estimatedProfit: profit
                    });
                    delete positions[openTicket];
                } else {
                    console.log(`Close deal found but open position not tracked: ticket ${openTicket}`);
                }
            } else {
                // This is an open deal (or a non-closing deal). Let's track it by its order ID!
                const orderMatch = line.match(/order #(\d+)/);
                if (orderMatch) {
                    const orderId = orderMatch[1];
                    positions[orderId] = { dealId, type, lot, symbol, price };
                }
            }
        }
    }
});

console.log("\n=== ESTIMATED CLOSED TRADES TODAY ===");
closedTrades.forEach(t => {
    console.log(`Time: ${t.time} | Ticket: ${t.openTicket} | Type: ${t.type} | Lot: ${t.lot} | Open: ${t.openPrice} | Close: ${t.closePrice} | Profit: ${t.estimatedProfit.toFixed(2)} USC`);
});
