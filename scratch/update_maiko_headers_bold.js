const fs = require('fs');
const path = require('path');

const files = [
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5"
];

// Helper to convert standard letters/digits to mathematical bold sans-serif
function convertChar(c) {
    // Map accents first
    const accents = {
        'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ñ': 'N',
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n'
    };
    const mapped = accents[c] || c;

    const code = mapped.charCodeAt(0);
    // Uppercase A-Z -> Mathematical Sans-Serif Bold A-Z
    if (code >= 65 && code <= 90) {
        return String.fromCodePoint(0x1D5D4 + (code - 65));
    }
    // Lowercase a-z -> Mathematical Sans-Serif Bold a-z
    if (code >= 97 && code <= 122) {
        return String.fromCodePoint(0x1D5EE + (code - 97));
    }
    // Digits 0-9 -> Mathematical Sans-Serif Bold Digits 0-9
    if (code >= 48 && code <= 57) {
        return String.fromCodePoint(0x1D7EC + (code - 48));
    }
    return c;
}

function stylizeString(str) {
    return str.split('').map(convertChar).join('');
}

files.forEach(file => {
    console.log("Formatting parameter headers in:", file);
    if (!fs.existsSync(file)) {
        console.error("File not found:", file);
        return;
    }
    
    let content = fs.readFileSync(file, 'utf8');
    
    // Find all input group declarations: input group "..."
    const inputGroupRegex = /input\s+group\s+"([^"]+)"/g;
    
    let modified = false;
    content = content.replace(inputGroupRegex, (fullMatch, headerText) => {
        const stylized = stylizeString(headerText);
        console.log(`  Converting: "${headerText}" -> "${stylized}"`);
        modified = true;
        return `input group "${stylized}"`;
    });
    
    if (modified) {
        fs.writeFileSync(file, content, 'utf8');
        console.log("Successfully updated:", file);
    } else {
        console.log("No input groups found in:", file);
    }
});
