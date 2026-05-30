const fs = require('fs');
const path = require('path');

const botsDir = path.join(__dirname, 'public', 'uploads', 'bots');
const files = fs.readdirSync(botsDir).filter(f => f.endsWith('.mq5'));

for (const file of files) {
    const filePath = path.join(botsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');

    // Mover los inputs arriba
    const inputBlock = `
// --- PROTECCION DE EQUIDAD (STOP LOSS) ---
input bool InpUsarProteccionEquidad = false; // Activar Stop Loss por Equidad (Drawdown)
input double InpMaxDrawdownPorcentaje = 20.0; // % Maximo de Drawdown permitido
`;

    // Quitar el bloque viejo
    content = content.replace(/\/\/ --- PROTECCION DE EQUIDAD \(STOP LOSS\) ---\r?\ninput bool InpUsarProteccionEquidad = false; \/\/ Activar Stop Loss por Equidad \(Drawdown\)\r?\ninput double InpMaxDrawdownPorcentaje = 20\.0; \/\/ % M.ximo de Drawdown permitido\r?\n/, '');

    // Inyectarlo justo despues de configuracion
    if (!content.includes('// --- PROTECCION DE EQUIDAD (STOP LOSS) ---')) {
        content = content.replace(/\/\/ --- CONFIGURACION ---\r?\n/, `// --- CONFIGURACION ---${inputBlock}`);
    }

    fs.writeFileSync(filePath, content);
    console.log(`Moved inputs in ${file}`);
}
