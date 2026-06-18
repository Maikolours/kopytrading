const fs = require('fs');
const path = require('path');
const { mdToPdf } = require('md-to-pdf');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

// Helper to convert local images to base64 data URLs for Puppeteer to render without path issues
function getBase64Image(filePath) {
    try {
        const fullPath = path.resolve(__dirname, '..', filePath);
        if (fs.existsSync(fullPath)) {
            const ext = path.extname(fullPath).toLowerCase().replace('.', '');
            const content = fs.readFileSync(fullPath, 'base64');
            return `data:image/${ext === 'svg' ? 'svg+xml' : ext};base64,${content}`;
        }
    } catch (e) {
        console.error("Error reading image:", filePath, e);
    }
    return '';
}

async function generateManuals() {
    const outDir = path.join(__dirname, '..', 'public', 'uploads');
    
    // Load style and templates
    const styleCss = fs.readFileSync(path.join(__dirname, 'manual_style.css'), 'utf8');
    const cssBlock = `<style>\n${styleCss}\n</style>\n\n`;

    let goldMd = fs.readFileSync(path.join(__dirname, 'gold.md'), 'utf8');
    let centMd = fs.readFileSync(path.join(__dirname, 'cent.md'), 'utf8');
    let btcMd = fs.readFileSync(path.join(__dirname, 'btc.md'), 'utf8');

    // Load logo base64 strings
    const logoKopyTrading = getBase64Image('public/logo-kopytrading.png');
    const logoMaikoGold = getBase64Image('public/images/maiko-gold.png');
    const logoMaikoGoldDemo = getBase64Image('public/images/maiko-gold-demo.png');
    const logoMaikoCent = getBase64Image('public/images/maiko-cent.png');
    const logoMaikoBtc = getBase64Image('public/images/maiko-btc.png');

    // Replace placeholders
    const replaceAll = (str, mapObj) => {
        const re = new RegExp(Object.keys(mapObj).map(k => k.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')).join('|'), 'gi');
        return str.replace(re, matched => mapObj[matched.toLowerCase() || matched]);
    };

    const replacements = {
        '{{logokopytrading}}': logoKopyTrading,
        '{{logomaikogold}}': logoMaikoGold,
        '{{logomaikogolddemo}}': logoMaikoGoldDemo,
        '{{logomaikocent}}': logoMaikoCent,
        '{{logomaiko}': logoMaikoBtc, // fallback just in case
        '{{logomaikobtc}}': logoMaikoBtc
    };

    goldMd = cssBlock + replaceAll(goldMd, replacements);
    centMd = cssBlock + replaceAll(centMd, replacements);
    btcMd = cssBlock + replaceAll(btcMd, replacements);

    // Write markdown files to public uploads
    fs.writeFileSync(path.join(outDir, 'Manual_Maiko_Pro_Gold.md'), goldMd);
    fs.writeFileSync(path.join(outDir, 'Manual_Maiko_Pro_Cent.md'), centMd);
    fs.writeFileSync(path.join(outDir, 'Manual_Maiko_Pro_BTC.md'), btcMd);

    // Convert to PDF
    console.log("Converting to PDF...");
    try {
        await mdToPdf({ content: goldMd }, { 
            dest: path.join(outDir, 'Manual_Maiko_Pro_Gold.pdf'),
            pdf_options: {
                format: 'A4',
                margin: { top: '15mm', bottom: '15mm', left: '15mm', right: '15mm' }
            }
        });
        await mdToPdf({ content: centMd }, { 
            dest: path.join(outDir, 'Manual_Maiko_Pro_Cent.pdf'),
            pdf_options: {
                format: 'A4',
                margin: { top: '15mm', bottom: '15mm', left: '15mm', right: '15mm' }
            }
        });
        await mdToPdf({ content: btcMd }, { 
            dest: path.join(outDir, 'Manual_Maiko_Pro_BTC.pdf'),
            pdf_options: {
                format: 'A4',
                margin: { top: '15mm', bottom: '15mm', left: '15mm', right: '15mm' }
            }
        });
        console.log("PDFs generated.");
    } catch (e) {
        console.error("Error generating PDFs:", e);
        process.exit(1);
    }
}

generateManuals().catch(err => {
    console.error(err);
    process.exit(1);
});
