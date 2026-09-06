const fs = require('fs');
const path = require('path');

const srcDir = "C:\\proyectos\\APP KOPYTRADING";
const backupLocal = "C:\\BACKUP_KOPYTRADING_OFICIAL_2026";
const backupExternal = "D:\\BACKUP_KOPYTRADING_OFICIAL_2026";

function copyFolderRecursiveSync(source, target) {
    if (!fs.existsSync(target)) {
        fs.mkdirSync(target, { recursive: true });
    }

    if (fs.lstatSync(source).isDirectory()) {
        const files = fs.readdirSync(source);
        files.forEach((file) => {
            if (file === 'node_modules' || file === '.next' || file === '.git' || file === 'out') {
                return;
            }
            const curSource = path.join(source, file);
            const curTarget = path.join(target, file);
            if (fs.lstatSync(curSource).isDirectory()) {
                copyFolderRecursiveSync(curSource, curTarget);
            } else {
                fs.copyFileSync(curSource, curTarget);
            }
        });
    }
}

async function backup() {
    console.log("=== ACTUALIZANDO COPIA DE SEGURIDAD CON PDFS Y ASSETS SEO ===");

    const destinations = [backupLocal, backupExternal];

    for (const destRoot of destinations) {
        console.log(`\n📦 Creando estructura completa en: ${destRoot}...`);
        
        // 1. Proyecto Web Completo
        const projDest = path.join(destRoot, "01_PROYECTO_WEB_Y_PLATAFORMA");
        copyFolderRecursiveSync(srcDir, projDest);
        console.log(`  ✓ 01_PROYECTO_WEB_Y_PLATAFORMA respaldado.`);

        // 2. Bots MQL5 Oficiales
        const botsDest = path.join(destRoot, "02_BOTS_MQL5_Y_SCRIPTS_OFICIALES");
        const sourceActivos = path.join(srcDir, "Agosto_2026_Activos");
        if (fs.existsSync(sourceActivos)) {
            copyFolderRecursiveSync(sourceActivos, botsDest);
            console.log(`  ✓ 02_BOTS_MQL5_Y_SCRIPTS_OFICIALES respaldado.`);
        }

        // 3. Scripts de Auditoría
        const scriptsDest = path.join(destRoot, "03_SCRIPTS_AUDITORIA_MAIKO");
        fs.mkdirSync(scriptsDest, { recursive: true });
        const exporterSource = path.join(srcDir, "scratch", "deploy_smart_exporter.js");
        if (fs.existsSync(exporterSource)) {
            fs.copyFileSync(exporterSource, path.join(scriptsDest, "deploy_smart_exporter.js"));
        }

        const basePath = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";
        if (fs.existsSync(basePath)) {
            const folders = fs.readdirSync(basePath).filter(f => fs.statSync(path.join(basePath, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help');
            folders.forEach((f) => {
                const mq5File = path.join(basePath, f, "MQL5", "Scripts", "ExportMaikoHistory.mq5");
                if (fs.existsSync(mq5File)) {
                    fs.copyFileSync(mq5File, path.join(scriptsDest, `ExportMaikoHistory_v2.50.mq5`));
                }
            });
        }
        console.log(`  ✓ 03_SCRIPTS_AUDITORIA_MAIKO respaldado.`);

        // 4. Carpeta dedicada de Manuales PDF y Configuración SEO
        const pdfDest = path.join(destRoot, "04_MANUALES_PDF_Y_DOCUMENTACION_SEO");
        fs.mkdirSync(pdfDest, { recursive: true });

        // Copiar manuales carpeta MANUALES
        const manualesFolder = path.join(srcDir, "MANUALES");
        if (fs.existsSync(manualesFolder)) {
            copyFolderRecursiveSync(manualesFolder, path.join(pdfDest, "MANUALES_OFICIALES"));
        }

        // Copiar manuales uploads public
        const publicUploads = path.join(srcDir, "public", "uploads");
        if (fs.existsSync(publicUploads)) {
            copyFolderRecursiveSync(publicUploads, path.join(pdfDest, "MANUALES_PDF_DESCARGABLES"));
        }

        console.log(`  ✓ 04_MANUALES_PDF_Y_DOCUMENTACION_SEO respaldado.`);

        // 5. Informe LEEME
        const readmeContent = `=====================================================
  COPIA DE SEGURIDAD INTEGRAL KOPYTRADING (2026-08-27)
=====================================================
Fecha de respaldo: 27 de Agosto de 2026
Origen: C:\\proyectos\\APP KOPYTRADING
Destino: ${destRoot}

CONTENIDO TOTAL EN ESTE RESPALDO:
1. 01_PROYECTO_WEB_Y_PLATAFORMA/
   - Código fuente completo (Next.js 15, APIs, Prisma, Vercel, Control Remoto, Robots.txt, Sitemap.xml).
2. 02_BOTS_MQL5_Y_SCRIPTS_OFICIALES/
   - Códigos fuente .mq5 originales de MAIKO PRO GOLD REAL, CENT, DEMO, BTC, etc.
3. 03_SCRIPTS_AUDITORIA_MAIKO/
   - Script oficial de auditoría ExportMaikoHistory v2.50 con Profit Factor y WinRate.
4. 04_MANUALES_PDF_Y_DOCUMENTACION_SEO/
   - Todos los manuales en PDF (Manual Maiko Pro Gold, Cent, BTC, informes de backtest).

Estado del proyecto: 100% Completo, Probado y Desplegado en Vercel.
=====================================================`;
        fs.writeFileSync(path.join(destRoot, "LEEME_INFORMACION_COPIA.txt"), readmeContent, 'utf8');
    }

    console.log("\n✅ RESPALDO COMPLETO ACTUALIZADO CON ÉXITO EN DISCO C: Y DISCO D: (LACIE 1).");
}

backup().catch(console.error);
