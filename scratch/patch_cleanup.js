const fs = require('fs');
const path = require('path');

const terminals = [
    "D0E8209F77C8CF37AD8BF550E51FF075",
    "F762D69EEEA9B4430D7F17C82167C844",
    "BB8163656548A371304D87AABB7A68EB"
];

const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

const allFiles = [
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD.mq5",
    "Elite_MAIKO_Sniper_v11.30_EURUSD_CENT.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR.mq5",
    "Elite_Gold_MAIKO_Sniper_v11.30_HEDGED_SR_CENT.mq5"
];

const newCalcularGanadoHoy = `double CalcularGanadoHoy() { 
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    datetime startOfDay = StructToTime(dt);
    
    double total = 0; HistorySelect(startOfDay, TimeCurrent()); 
    for(int i=HistoryDealsTotal()-1; i>=0; i--) {
        ulong t = HistoryDealGetTicket(i);
        if(HistoryDealGetString(t, DEAL_SYMBOL) == _Symbol) {
            total += (HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP));
        }
    }
    return total; 
}`;

terminals.forEach(term => {
    allFiles.forEach(filename => {
        const filePath = path.join(basePath, term, "MQL5", "Experts", "BOTS MAIKO", filename);
        if (!fs.existsSync(filePath)) {
            return;
        }

        console.log(`Cleaning up comments and optimizing history for: ${filePath}`);
        let content = fs.readFileSync(filePath, 'utf8');

        // 1. Clean up MultiplicadorRefuerzo comment
        content = content.replace(
            /input\s+double\s+MultiplicadorRefuerzo\s*=\s*([\d\.]+);([\s\S]*?)\r?\n/g,
            'input double MultiplicadorRefuerzo = $1; // Multiplicador Lotes SOS (Refuerzo)\n'
        );

        // 2. Clean up ProfitNetoFlush comment
        content = content.replace(
            /input\s+double\s+ProfitNetoFlush\s*=\s*([\d\.]+);([\s\S]*?)\r?\n/g,
            'input double ProfitNetoFlush = $1; // Profit Neto Cesta (USD o cents)\n'
        );

        // 3. Clean up ProfitCosechaIndividual comment
        content = content.replace(
            /input\s+double\s+ProfitCosechaIndividual\s*=\s*([\d\.]+);([\s\S]*?)\r?\n/g,
            'input double ProfitCosechaIndividual = $1; // Profit Individual Cosecha (USD o cents)\n'
        );

        // 4. Clean up MaxLoteTotal comment
        content = content.replace(
            /input\s+double\s+MaxLoteTotal\s*=\s*([\d\.]+);([\s\S]*?)\r?\n/g,
            'input double MaxLoteTotal = $1; // Lote Maximo Total (Cesta)\n'
        );

        // 5. Optimize CalcularGanadoHoy
        const calcularGanadoHoyRegex = /double\s+CalcularGanadoHoy\(\)\s*\{[\s\S]*?\r?\n\}/;
        if (content.match(calcularGanadoHoyRegex)) {
            content = content.replace(calcularGanadoHoyRegex, newCalcularGanadoHoy);
            console.log(`  - Optimized CalcularGanadoHoy`);
        }

        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Successfully updated: ${filename}`);
    });
});
