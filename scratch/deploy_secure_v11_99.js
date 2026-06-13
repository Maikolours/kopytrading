// Script to fully secure experimental bots by moving them to a private folder and injecting Friday session/close filters
const fs = require('fs');
const path = require('path');

const projectRoot = "c:\\proyectos\\APP KOPYTRADING";
const publicBotsDir = path.join(projectRoot, "public", "uploads", "bots");
const privateBotsDir = path.join(projectRoot, "private_bots_backup");

console.log("=== STEP 1: Creating private bots directory ===");
if (!fs.existsSync(privateBotsDir)) {
    fs.mkdirSync(privateBotsDir, { recursive: true });
    console.log("Created private directory: private_bots_backup");
}

console.log("=== STEP 2: Moving experimental files from public directory to private directory ===");
const filesToSecure = [
    "Maiko_Sniper_PRO_GOLD_PRUEBA.mq5",
    "Maiko_Sniper_PRO_GOLD_PRUEBA.ex5",
    "Maiko_Sniper_PRO_CENT_PRUEBA.mq5",
    "Maiko_Sniper_PRO_CENT_PRUEBA.ex5",
    "Maiko_Sniper_PRO_GOLD_V11.mq5",
    "Maiko_Sniper_PRO_GOLD_V11.ex5",
    "Maiko_Sniper_PRO_CENT_V11.mq5",
    "Maiko_Sniper_PRO_CENT_V11.ex5",
    "Maiko_BTC_Weekend_PRUEBA.mq5",
    "Maiko_BTC_Weekend_PRUEBA.ex5"
];

filesToSecure.forEach(fileName => {
    const srcPath = path.join(publicBotsDir, fileName);
    const destPath = path.join(privateBotsDir, fileName);
    if (fs.existsSync(srcPath)) {
        // Overwrite in private backup
        fs.copyFileSync(srcPath, destPath);
        // Delete from public folder
        fs.unlinkSync(srcPath);
        console.log(`Secured file: ${fileName} (moved to private backup)`);
    }
});

// Helper function to restore original clean MQL5 content before patching to avoid multiple/nested replacements
function cleanMqlFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    
    // Remove injected Horario de Sesion blocks
    const sessionBlockRegex = /\/\/ --- HORARIO DE SESION ---[\s\S]*?\/\/ --- OBJETIVOS DE PROFIT ---/g;
    content = content.replace(sessionBlockRegex, `// --- OBJETIVOS DE PROFIT ---`);
    
    // Restore original OnTick start
    const patchedOnTickStartRegex = /void OnTick\(\) \{[\s\S]*?\/\/ CHEQUEO DE HORARIO Y FIN DE SEMANA[\s\S]*?if\(UsarFiltroHorario && ArraySize\(pos\) == 0\) \{[\s\S]*?\}\s*?\}/g;
    // Let's replace any previously failed injections with clean original OnTick start
    const originalOnTickStart = `void OnTick() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;`;
    
    // A broader cleaner to ensure a completely pristine OnTick is restored
    const onTickIndex = content.indexOf("void OnTick() {");
    if (onTickIndex >= 0) {
        const afterOnTick = content.substring(onTickIndex);
        const doubleRsiIndex = afterOnTick.indexOf("double rsi_buf[1]");
        if (doubleRsiIndex >= 0) {
            // Reconstruct clean file
            content = content.substring(0, onTickIndex) + `void OnTick() {
    ActualizarEstadoMaster();
    ganadoPeriodo = CalcularGanadoUltraPreciso(idxPeriodo);
    flotante = CalcularProfit();
    spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    ` + afterOnTick.substring(doubleRsiIndex);
        }
    }

    // Remove any previously injected early return blocks after ActualizarInterfazMaster
    content = content.replace(/ActualizarInterfazMaster\(\);\s*\/\/ CONGELACIÓN DE NUEVAS ENTRADAS[\s\S]*?return;\s*\}/g, "ActualizarInterfazMaster();");
    
    fs.writeFileSync(filePath, content, 'utf8');
}

console.log("=== STEP 3: Injecting refined Session & Friday Trade Freeze to Gold V11 ===");

const goldV11Mql = path.join(privateBotsDir, "Maiko_Sniper_PRO_GOLD_V11.mq5");
if (fs.existsSync(goldV11Mql)) {
    // First restore to original clean state
    cleanMqlFile(goldV11Mql);
    
    let content = fs.readFileSync(goldV11Mql, 'utf8');

    // 1. Inject inputs block
    const inputsTarget = `// --- OBJETIVOS DE PROFIT ---`;
    const inputsReplacement = `// --- HORARIO DE SESION ---
input bool UsarFiltroHorario = false; // Activar Filtro Horario de Sesion
input int HoraInicioSesion = 9;       // Hora de inicio de sesion (09:00)
input int HoraFinSesion = 22;         // Hora de fin de sesion (22:00)
input bool BloquearViernesNoche = true; // Evitar Nuevas Entradas Viernes Noche (Recomendado)
input bool CerrarViernesNoche = false; // Cierre forzado Viernes Noche (Fin de semana)
input int HoraCierreViernes = 21;     // Hora limite los viernes (21:00)

// --- OBJETIVOS DE PROFIT ---`;
    content = content.replace(inputsTarget, inputsReplacement);

    // 2. Inject Friday Forced Close check right after calculations
    const calcTarget = `spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;\n    \n    `;
    const calcTargetCr = `spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;\r\n    \r\n    `;
    const forcedCloseReplacement = `spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    // CHEQUEO CIERRE FORZADO DE VIERNES (Si está activo)
    MqlDateTime dt; TimeCurrent(dt);
    if(CerrarViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        if(ArraySize(pos) > 0) {
            txtVoz = "CIERRE FIN DE SEMANA ⚠️";
            CerrarTodo();
            return;
        }
    }
    `;

    if (content.includes(calcTarget)) {
        content = content.replace(calcTarget, forcedCloseReplacement);
    } else if (content.includes(calcTargetCr)) {
        content = content.replace(calcTargetCr, forcedCloseReplacement);
    }

    // 3. Inject Friday Night Trade Freeze right AFTER closures/harvests (ActualizarInterfazMaster)
    const closureTarget = `ActualizarInterfazMaster();`;
    const closureReplacement = `ActualizarInterfazMaster();
    
    // CONGELACIÓN DE NUEVAS ENTRADAS EL VIERNES NOCHE (PERMITIENDO CIERRES ANTES)
    if(BloquearViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        txtVeredicto = "VIERNES NOCHE: BLOQUEADO";
        if(ArraySize(pos) > 0) {
            txtVoz = StringFormat("CONGELADO FIN DE SEMANA (%d pos abiertas)", ArraySize(pos));
        } else {
            txtVoz = "MERCADO CERRADO / ESPERANDO";
        }
        ActualizarInterfazMaster();
        return;
    }`;
    content = content.replace(closureTarget, closureReplacement);

    fs.writeFileSync(goldV11Mql, content, 'utf8');
    console.log("Successfully injected refined Friday Trade Freeze in Gold V11!");
}

console.log("=== STEP 4: Injecting refined Session & Friday Trade Freeze to Cent V11 ===");

const centV11Mql = path.join(privateBotsDir, "Maiko_Sniper_PRO_CENT_V11.mq5");
if (fs.existsSync(centV11Mql)) {
    // First restore to original clean state
    cleanMqlFile(centV11Mql);
    
    let content = fs.readFileSync(centV11Mql, 'utf8');

    // 1. Inject inputs block
    const inputsTarget = `// --- OBJETIVOS DE PROFIT ---`;
    const inputsReplacement = `// --- HORARIO DE SESION ---
input bool UsarFiltroHorario = false; // Activar Filtro Horario de Sesion
input int HoraInicioSesion = 9;       // Hora de inicio de sesion (09:00)
input int HoraFinSesion = 22;         // Hora de fin de sesion (22:00)
input bool BloquearViernesNoche = true; // Evitar Nuevas Entradas Viernes Noche (Recomendado)
input bool CerrarViernesNoche = false; // Cierre forzado Viernes Noche (Fin de semana)
input int HoraCierreViernes = 21;     // Hora limite los viernes (21:00)

// --- OBJETIVOS DE PROFIT ---`;
    content = content.replace(inputsTarget, inputsReplacement);

    // 2. Inject Friday Forced Close check right after calculations
    const calcTarget = `spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;\n    \n    `;
    const calcTargetCr = `spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;\r\n    \r\n    `;
    const forcedCloseReplacement = `spreadActual = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point / 10;
    
    // CHEQUEO CIERRE FORZADO DE VIERNES (Si está activo)
    MqlDateTime dt; TimeCurrent(dt);
    if(CerrarViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        if(ArraySize(pos) > 0) {
            txtVoz = "CIERRE FIN DE SEMANA ⚠️";
            CerrarTodo();
            return;
        }
    }
    `;

    if (content.includes(calcTarget)) {
        content = content.replace(calcTarget, forcedCloseReplacement);
    } else if (content.includes(calcTargetCr)) {
        content = content.replace(calcTargetCr, forcedCloseReplacement);
    }

    // 3. Inject Friday Night Trade Freeze right AFTER closures/harvests (ActualizarInterfazMaster)
    const closureTarget = `ActualizarInterfazMaster();`;
    const closureReplacement = `ActualizarInterfazMaster();
    
    // CONGELACIÓN DE NUEVAS ENTRADAS EL VIERNES NOCHE (PERMITIENDO CIERRES ANTES)
    if(BloquearViernesNoche && dt.day_of_week == 5 && dt.hour >= HoraCierreViernes) {
        txtVeredicto = "VIERNES NOCHE: BLOQUEADO";
        if(ArraySize(pos) > 0) {
            txtVoz = StringFormat("CONGELADO FIN DE SEMANA (%d pos abiertas)", ArraySize(pos));
        } else {
            txtVoz = "MERCADO CERRADO / ESPERANDO";
        }
        ActualizarInterfazMaster();
        return;
    }`;
    content = content.replace(closureTarget, closureReplacement);

    fs.writeFileSync(centV11Mql, content, 'utf8');
    console.log("Successfully injected refined Friday Trade Freeze in Cent V11!");
}

console.log("=== Security & Session Deployment Refinement Done ===");
