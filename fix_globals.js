const fs = require('fs');
const path = require('path');

const botsDir = path.join(__dirname, 'public', 'uploads', 'bots');
const files = fs.readdirSync(botsDir).filter(f => f.endsWith('.mq5'));

for (const file of files) {
    const filePath = path.join(botsDir, file);
    let content = fs.readFileSync(filePath, 'utf8');

    // Comprobar si falta bool UsarProteccionEquidad
    if (!content.includes('bool UsarProteccionEquidad = false;')) {
        // Añadirlo justo antes de int OnInit
        content = content.replace(
            /int OnInit\(\)\s*\{/,
            'bool UsarProteccionEquidad = false;\ndouble MaxDrawdownPorcentaje = 20.0;\n\nint OnInit() {'
        );
        fs.writeFileSync(filePath, content);
        console.log(`Fixed globals in ${file}`);
    }
}
