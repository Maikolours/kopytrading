const fs = require('fs');
const path = require('path');
const { mdToPdf } = require('md-to-pdf');

async function compile(file) {
    const mdPath = path.join(__dirname, '../public/uploads', `${file}.md`);
    const pdfPath = path.join(__dirname, '../public/uploads', `${file}.pdf`);
    
    console.log(`Compilando ${mdPath} -> ${pdfPath}...`);
    
    try {
        const pdf = await mdToPdf({ path: mdPath }, {
            launch_options: {
                executablePath: 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
                args: ['--no-sandbox', '--disable-setuid-sandbox']
            }
        });
        
        if (pdf) {
            fs.writeFileSync(pdfPath, pdf.content);
            console.log(`¡Compilado con éxito! Escritos ${pdf.content.length} bytes.`);
        }
    } catch (e) {
        console.error(`Error compilando ${file}:`, e);
    }
}

async function main() {
    await compile('Manual_Maiko_Pro_Gold');
    await compile('Manual_Maiko_Pro_Cent');
    await compile('Manual_Maiko_Pro_BTC');
}

main();
