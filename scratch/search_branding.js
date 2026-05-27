const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
    fs.readdirSync(dir).forEach(f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        if (isDirectory) {
            walkDir(dirPath, callback);
        } else {
            callback(dirPath);
        }
    });
}

console.log("=== BUSCANDO CARACTERÍSTICAS EN EL CÓDIGO ===");
walkDir('./src', (filePath) => {
    if (filePath.endsWith('.ts') || filePath.endsWith('.tsx') || filePath.endsWith('.js') || filePath.endsWith('.jsx')) {
        const content = fs.readFileSync(filePath, 'utf8');
        const hasSoporte = content.includes('24/7') || content.includes('Soporte') || content.includes('binding') || content.includes('Multicuentas');
        if (hasSoporte) {
            console.log(`Match en: ${filePath}`);
            const lines = content.split('\n');
            lines.forEach((line, idx) => {
                if (line.includes('24/7') || line.includes('Soporte') || line.includes('binding') || line.includes('Multicuentas') || line.includes('por vida')) {
                    console.log(`  Línea ${idx + 1}: ${line.trim()}`);
                }
            });
        }
    }
});
