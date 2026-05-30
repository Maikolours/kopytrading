const fs = require('fs');
const path = require('path');

const logPath = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844\\logs\\20260529.log';

if (!fs.existsSync(logPath)) {
    console.log("Log file not found!");
    process.exit(1);
}

const text = fs.readFileSync(logPath, 'utf16le');
const lines = text.split('\n');

const orderToDeal = {};
const closeToOpen = [];

lines.forEach(line => {
    // Trades   '23449251': deal #853660271 sell 0.01 XAUUSD-STDc at 4560.50 done (based on order #907597127)
    const dealMatch = line.match(/deal #(\d+)\s+(buy|sell)\s+([\d.]+)\s+(\S+)\s+at\s+([\d.]+)\s+done\s+\(based\s+on\s+order\s+#(\d+)\)/);
    if (dealMatch) {
        const dealId = dealMatch[1];
        const type = dealMatch[2];
        const lot = parseFloat(dealMatch[3]);
        const symbol = dealMatch[4];
        const price = parseFloat(dealMatch[5]);
        const orderId = dealMatch[6];
        orderToDeal[orderId] = { dealId, type, lot, symbol, price, line: line.trim() };
    }
});

// Let's print all deals and find their matches manually or by listing all close transactions
lines.forEach(line => {
    if (line.includes('close #')) {
        const match = line.match(/close #(\d+)/);
        if (match) {
            const openOrderId = match[1];
            const closeOrderMatch = line.match(/order #(\d+)/);
            if (closeOrderMatch) {
                const closeOrderId = closeOrderMatch[1];
                closeToOpen.push({ openOrderId, closeOrderId, line: line.trim() });
            }
        }
    }
});

console.log(`=== DETAILED DEALS LIST ===`);
console.log(`Deals: ${Object.keys(orderToDeal).length}`);
console.log(`Close to Open mappings: ${closeToOpen.length}`);

let totalProfit = 0;
closeToOpen.forEach(mapping => {
    const openDeal = orderToDeal[mapping.openOrderId];
    const closeDeal = orderToDeal[mapping.closeOrderId];
    
    if (openDeal && closeDeal) {
        const diff = (openDeal.type === 'buy') ? (closeDeal.price - openDeal.price) : (openDeal.price - closeDeal.price);
        const profit = diff * openDeal.lot * 100;
        totalProfit += profit;
        console.log(`Pair: OpenOrder #${mapping.openOrderId} (${openDeal.price}) -> CloseOrder #${mapping.closeOrderId} (${closeDeal.price}) | Lot: ${openDeal.lot} | Profit: ${profit.toFixed(2)} USC`);
    } else {
        console.log(`Missing deal for pair: Open #${mapping.openOrderId} (${openDeal ? 'found' : 'missing'}) -> Close #${mapping.closeOrderId} (${closeDeal ? 'found' : 'missing'})`);
    }
});

console.log(`\nEstimated Total Closed Profit Today: ${totalProfit.toFixed(2)} USC (${(totalProfit / 100).toFixed(2)} USD)`);
