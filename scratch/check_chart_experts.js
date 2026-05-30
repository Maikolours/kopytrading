const fs = require('fs');
const path = require('path');

const goldChartsDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Profiles\\Charts\\Default';

if (fs.existsSync(goldChartsDir)) {
    console.log("=== SCANNING ACTIVE EA INPUTS FOR GOLD TERMINAL ===");
    fs.readdirSync(goldChartsDir).forEach(file => {
        if (file.endsWith('.chr')) {
            const filePath = path.join(goldChartsDir, file);
            const buffer = fs.readFileSync(filePath);
            const content = buffer.toString('utf16le');
            
            const lines = content.split('\r\n');
            let inExpert = false;
            let expertName = "";
            let expertInputs = "";
            
            lines.forEach(line => {
                if (line.includes('<expert>')) inExpert = true;
                if (line.includes('</expert>')) inExpert = false;
                
                if (inExpert) {
                    if (line.includes('name=')) {
                        expertName = line.split('=')[1].trim();
                    }
                    if (line.includes('inputs=')) {
                        expertInputs = line.split('=')[1].trim();
                    }
                }
            });
            
            if (expertName) {
                console.log(`\nChart Profile: ${file}`);
                console.log(`  Expert Name: ${expertName}`);
                console.log(`  Inputs String: ${expertInputs}`);
                
                // Let's parse the inputs string. It's comma-separated like: "inputName=value,inputName=value"
                // Or let's look for specific inputs like ExpertMagic, TradeComment, or Magic
                const parts = expertInputs.split(',');
                parts.forEach(p => {
                    if (p.includes('ExpertMagic') || p.includes('Magic') || p.includes('Comment') || p.includes('TradeComment')) {
                        console.log(`    Input Param: ${p}`);
                    }
                });
            }
        }
    });
} else {
    console.log("GOLD charts directory not found!");
}
