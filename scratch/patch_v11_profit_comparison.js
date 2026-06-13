// Script to fix profit comparisons for V11 bots so that cent accounts use inputs directly as cents without scaling up
const fs = require('fs');
const path = require('path');

const uploadsDir = "c:\\proyectos\\APP KOPYTRADING\\public\\uploads\\bots";
const goldV11Path = path.join(uploadsDir, "Maiko_Sniper_PRO_GOLD_V11.mq5");
const centV11Path = path.join(uploadsDir, "Maiko_Sniper_PRO_CENT_V11.mq5");

console.log("=== STEP 1: Adjusting comparison logic in V11 files ===");

[goldV11Path, centV11Path].forEach(filePath => {
    if (!fs.existsSync(filePath)) {
        console.warn(`File not found: ${filePath}`);
        return;
    }

    let content = fs.readFileSync(filePath, 'utf8');
    
    // Replace daily target and flush target calculations in OnTick() to use directly the inputs
    content = content.replace(
        'double targetActual = (ArraySize(pos) >= LimitePosicionesSOS) ? (ProfitBreakEven * multCent) : (ProfitNetoFlush * multCent);',
        'double targetActual = (ArraySize(pos) >= LimitePosicionesSOS) ? ProfitBreakEven : ProfitNetoFlush;'
    );
    
    content = content.replace(
        'if(ganadoHoy >= (TargetDiario * multCent)) {',
        'if(ganadoHoy >= TargetDiario) {'
    );

    content = content.replace(
        'if(ProteccionBeneficioDiario > 0.0 && ganadoHoy > (ProteccionBeneficioDiario * multCent)) {',
        'if(ProteccionBeneficioDiario > 0.0 && ganadoHoy > ProteccionBeneficioDiario) {'
    );

    content = content.replace(
        'if((ganadoHoy + flotante) <= (ProteccionBeneficioDiario * multCent) && ArraySize(pos) > 0) {',
        'if((ganadoHoy + flotante) <= ProteccionBeneficioDiario && ArraySize(pos) > 0) {'
    );

    // Replace individual position harvest comparison in GestionarCosechaSniper()
    content = content.replace(
        'for(int i=ArraySize(pos)-1; i>=0; i--) if((pos[i].p + pos[i].c + pos[i].s) >= (ProfitCosechaIndividual * multCent)) trade.PositionClose(pos[i].ticket);',
        'for(int i=ArraySize(pos)-1; i>=0; i--) if((pos[i].p + pos[i].c + pos[i].s) >= ProfitCosechaIndividual) trade.PositionClose(pos[i].ticket);'
    );

    fs.writeFileSync(filePath, content, 'utf8');
    console.log(`Patched profit comparisons in: ${path.basename(filePath)}`);
});

console.log("=== V11 Profit Comparison Patch Completed Successfully ===");
