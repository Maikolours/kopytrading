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

console.log("=== BUSCANDO 'CLOSE_ALL' EN EL CÓDIGO ===");
walkDir('./src', (filePath) => {
    if (filePath.endsWith('.ts') || filePath.endsWith('.tsx') || filePath.endsWith('.js') || filePath.endsWith('.jsx')) {
        const content = fs.readFileSync(filePath, 'utf8');
        if (content.includes('CLOSE_ALL')) {
            console.log(`Match en: ${filePath}`);
            // Mostrar líneas que coinciden
            const lines = content.split('\n');
            lines.forEach((line, idx) => {
                if (line.includes('CLOSE_ALL')) {
                    console.log(`  Línea ${idx + 1}: ${line.trim()}`);
                }
            });
        }
    }
});
