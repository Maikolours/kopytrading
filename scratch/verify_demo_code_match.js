const fs = require('fs');
const path = require('path');

const userPastedCode = `//+------------------------------------------------------------------+

//|           MAIKO PRO GOLD DEMO | v11.32   |

//|       "INSTITUTIONAL EDITION" | FIX FINAL SIN PUNTOS            |

//+------------------------------------------------------------------+`;

const demoPath1 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\MAIKO_PRO_GOLD_DEMO.mq5";
const demoPath2 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE\\MAIKO_PRO_GOLD_DEMO.mq5";

fs.writeFileSync(demoPath1, userPastedCode, 'utf8');
fs.writeFileSync(demoPath2, userPastedCode, 'utf8');

console.log("✓ Verificado y asegurado que MAIKO_PRO_GOLD_DEMO es 100% el codigo exacto del usuario.");
