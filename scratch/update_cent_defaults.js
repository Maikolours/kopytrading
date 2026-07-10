const fs = require('fs');

const file = "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5";

if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Replace inputs in CENT bot
    content = content.replace(/input double\s+LoteAtaque\s*=\s*0\.02;/, 'input double   LoteAtaque                 = 0.10;        // 🚀 Volumen Entrada Inicial (Ataque)');
    content = content.replace(/input double\s+MaxLoteTotal\s*=\s*0\.06;/, 'input double   MaxLoteTotal               = 5.00;        // 🚫 Lote Máximo Acumulado Permitido');
    content = content.replace(/input double\s+MaxLoteIndividual\s*=\s*0\.04;/, 'input double   MaxLoteIndividual          = 1.00;        // 🚫 Lote Máximo por Operación SOS');
    content = content.replace(/input double\s+DistanciaRefuerzoPips\s*=\s*15\.0;/, 'input double   DistanciaRefuerzoPips      = 30.0;        // 📏 Distancia Mínima para Abrir SOS (Pips)');
    content = content.replace(/input double\s+ProfitNetoFlush\s*=\s*0\.25;/, 'input double   ProfitNetoFlush            = 50.0;        // 💵 Beneficio Cierre Total Cesta ($)');
    content = content.replace(/input double\s+ProfitCosechaIndividual\s*=\s*0\.06;/, 'input double   ProfitCosechaIndividual    = 7.50;        // 💵 Beneficio Cierre SOS Individual ($)');
    content = content.replace(/input double\s+TargetDiario\s*=\s*5\.0;/, 'input double   TargetDiario               = 150.0;       // 🎯 Meta de Beneficio Diario ($)');
    content = content.replace(/input double\s+ProfitBreakEven\s*=\s*0\.10;/, 'input double   ProfitBreakEven            = 5.00;        // 🛡️ Beneficio Mínimo Break Even Cesta ($)');
    
    fs.writeFileSync(file, content, 'utf8');
    console.log("Successfully updated default parameters in Cent bot.");
} else {
    console.error("File not found:", file);
}
