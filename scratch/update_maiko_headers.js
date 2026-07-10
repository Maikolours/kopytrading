const fs = require('fs');

const files = [
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_REAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_CLIENT_TRIAL.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO.mq5",
    "private_bots_backup/Elite_Gold_MAIKO_Sniper_v11.30_NORMAL_HISTORICO_CENT.mq5"
];

// Map of header replacements to make them highly visible and premium
const headerMap = {
    "🔑 LICENCIA DE CONEXION": "━━━━━━ 🔑 L I C E N C I A   D E   C O N E X I Ó N ━━━━━━",
    "🛡️ FILTROS DE RUIDO Y MERCADO": "━━━━━━ 🛡️ F I L T R O S   D E   R U I D O   Y   M E R C A D O ━━━━━━",
    "🏛️ FILTRO DE TECHOS Y SUELOS": "━━━━━━ 🏛️ F I L T R O   D E   T E C H O S   Y   S U E L O S ━━━━━━",
    "📉 TENDENCIA Y DIRECCION": "━━━━━━ 📉 T E N D E N C I A   Y   D I R E C C I Ó N ━━━━━━",
    "📈 CONFIGURACION OPERATIVA Y LOTES": "━━━━━━ 📈 C O N F I G U R A C I Ó N   Y   L O T E S ━━━━━━",
    "📈 CONFIGURACIÓN Y LOTES": "━━━━━━ 📈 C O N F I G U R A C I Ó N   Y   L O T E S ━━━━━━",
    "📏 DISTANCIAS Y CASCADA": "━━━━━━ 📏 D I S T A N C I A S   Y   C A S C A D A ━━━━━━",
    "💰 COBRAR BENEFICIOS (TAKE PROFIT)": "━━━━━━ 💰 C O B R A R   B E N E F I C I O S   ( T P ) ━━━━━━",
    "💰 COBRAR BENEFICIOS (TP)": "━━━━━━ 💰 C O B R A R   B E N E F I C I O S   ( T P ) ━━━━━━",
    "⏰ HORARIOS OPERATIVOS": "━━━━━━ ⏰ H O R A R I O S   O P E R A T I V O S ━━━━━━",
    "🛡️ PROTECCIONES Y SEGURIDAD": "━━━━━━ 🛡️ P R O T E C C I O N E S   Y   S E G U R I D A D ━━━━━━",
    "🎨 INTERFAZ GRAFICA (HUD)": "━━━━━━ 🎨 I N T E R F A Z   G R Á F I C A   ( H U D ) ━━━━━━",
    "📝 COMENTARIOS DE TRADING": "━━━━━━ 📝 C O M E N T A R I O S   D E   T R A D I N G ━━━━━━"
};

files.forEach(file => {
    console.log("Modifying headers in file:", file);
    if (!fs.existsSync(file)) {
        console.error("File not found:", file);
        return;
    }
    let content = fs.readFileSync(file, 'utf8');
    
    // Find all input groups
    const inputGroupRegex = /input group\s+"===\s*(.*?)\s*==*"/g;
    
    let match;
    let modified = false;
    
    // We will do a generic replacement for any input group matching the old pattern
    content = content.replace(/input group\s+"===\s*\[?\s*(.*?)\s*\]?\s*==*"/g, (fullMatch, headerText) => {
        const cleanHeader = headerText.trim().replace(/^\[\s*/, '').replace(/\s*\]$/, '').trim();
        if (headerMap[cleanHeader]) {
            modified = true;
            return `input group "${headerMap[cleanHeader]}"`;
        } else {
            // Generically format it if it's not in the map
            // e.g. "━━━━━━ E M O J I   T E X T ━━━━━━"
            const emojiMatch = cleanHeader.match(/^([\uD800-\uDBFF][\uDC00-\uDFFF]|\S)\s*(.*)$/);
            let formatted = cleanHeader;
            if (emojiMatch) {
                const emoji = emojiMatch[1];
                const rest = emojiMatch[2].trim();
                const spaced = rest.split('').join(' ').replace(/\s+/g, '   ');
                formatted = `━━━━━━ ${emoji} ${spaced} ━━━━━━`;
            } else {
                const spaced = cleanHeader.split('').join(' ').replace(/\s+/g, '   ');
                formatted = `━━━━━━ ${spaced} ━━━━━━`;
            }
            modified = true;
            return `input group "${formatted}"`;
        }
    });

    if (modified) {
        fs.writeFileSync(file, content, 'utf8');
        console.log("Successfully formatted headers in:", file);
    } else {
        console.log("No headers matched old pattern in:", file);
    }
});
