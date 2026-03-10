const fs = require('fs');
const path = require('path');

function replaceInFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    let original = content;

    // Replace case-sensitive specific forms
    content = content.replace(/KopyTrade/g, 'KopyTrading');
    content = content.replace(/KOPYTRADE/g, 'KOPYTRADING');
    content = content.replace(/kopytrade\.com/g, 'kopytrading.com'); // keep domain
    // we should be careful with other lowercases like variable names
    // so we just replace the ones the user would see:
    content = content.replace(/Kopytrade/g, 'Kopytrading');


    if (content !== original) {
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated: ${filePath}`);
    }
}

function traverse(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            traverse(fullPath);
        } else {
            if (fullPath.endsWith('.ts') || fullPath.endsWith('.tsx') || fullPath.endsWith('.md') || fullPath.endsWith('.json')) {
                // Don't modify package-lock, package.json or public metadata if not needed but let's do it 
                if (!fullPath.includes('node_modules') && !fullPath.includes('.git') && !fullPath.includes('.next')) {
                    replaceInFile(fullPath);
                }
            }
        }
    }
}

traverse(path.join(__dirname, 'src'));
traverse(path.join(__dirname, 'public'));
