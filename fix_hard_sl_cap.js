
const fs = require("fs");
const path = require("path");

const files = [
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_V11_34_1_RISK.mq5",
    "Agosto_2026_Activos/00_OFICIALES_SEPTIEMBRE/MAIKO_PRO_GOLD_DEMO.mq5"
];

for (const f of files) {
    let p = path.join("C:/proyectos/APP KOPYTRADING", f);
    if (!fs.existsSync(p)) continue;
    
    let content = fs.readFileSync(p, "utf8");
    
    // 1. Set EvitarNoticias to true by default (14:00 - 16:00 US news block)
    content = content.replace(/input bool\s+UsarHorarioBloqueo\s*=\s*(false|true);/, "input bool     UsarHorarioBloqueo         = true;        // 🛑 Evitar Noticias EEUU (14:00-16:00)");
    
    // 2. Add individual trade hard loss cap inside GestionarCosechaSniper
    let hardCapCode = `
            // Cierre de seguridad de emergencia por operacion individual (-$6.00 maximo)
            if(prof <= -6.00) {
                trade.PositionClose(ticket);
                Print("KOPYTRADING SAFETY: Operacion cortada por limite duro de -$6.00 (Ticket ", ticket, ")");
            }
`;
    content = content.replace("void GestionarCosechaSniper() {", "void GestionarCosechaSniper() {" + hardCapCode);
    
    fs.writeFileSync(p, content, "utf8");
    console.log("Applied hard -$6.00 loss cap and news block for " + f);
}

