const fs = require('fs');
const path = require('path');

const botsDir = path.join(__dirname, 'public', 'uploads', 'bots');
const files = fs.readdirSync(botsDir).filter(f => f.endsWith('.mq5'));

for (const file of files) {
    const filePath = path.join(botsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');

    // 1. Reemplazar inputs
    content = content.replace(
        /input bool UsarProteccionEquidad = false;\s*\/\/\s*Activar Stop Loss por Equidad \(Drawdown\)/,
        'input bool InpUsarProteccionEquidad = false; // Activar Stop Loss por Equidad (Drawdown)'
    );
    
    content = content.replace(
        /input double MaxDrawdownPorcentaje = 20\.0;\s*\/\/\s*% M.ximo de Drawdown permitido/,
        'input double InpMaxDrawdownPorcentaje = 20.0; // % Máximo de Drawdown permitido\nbool UsarProteccionEquidad = false;\ndouble MaxDrawdownPorcentaje = 20.0;'
    );

    // 2. Inyectar inicializacion en OnInit
    if (!content.includes('UsarProteccionEquidad = InpUsarProteccionEquidad;')) {
        content = content.replace(
            /int OnInit\(\)\s*\{/,
            'int OnInit() {\n      UsarProteccionEquidad = InpUsarProteccionEquidad;\n      MaxDrawdownPorcentaje = InpMaxDrawdownPorcentaje;'
        );
    }

    fs.writeFileSync(filePath, content);
    console.log(`Patched ${file}`);
}
