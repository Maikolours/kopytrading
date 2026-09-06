const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const file1 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\MAIKO_PRO_GOLD_DEMO_V11.33.mq5";
const file2 = "C:\\proyectos\\APP KOPYTRADING\\Agosto_2026_Activos\\00_OFICIALES_SEPTIEMBRE\\MAIKO_PRO_GOLD_DEMO_V11.33.mq5";

let content = fs.readFileSync(file2, 'utf8');

// Remove from above AgregarIndicadoresVisuales
content = content.replace('int hATR_v = INVALID_HANDLE;\nint hBands_v = INVALID_HANDLE;\n\nvoid AgregarIndicadoresVisuales()', 'void AgregarIndicadoresVisuales()');
content = content.replace('int hATR_v = INVALID_HANDLE;\r\nint hBands_v = INVALID_HANDLE;\r\n\r\nvoid AgregarIndicadoresVisuales()', 'void AgregarIndicadoresVisuales()');
content = content.replace('int hATR_v = INVALID_HANDLE;\nint hBands_v = INVALID_HANDLE;\nvoid AgregarIndicadoresVisuales()', 'void AgregarIndicadoresVisuales()');
content = content.replace('int hATR_v = INVALID_HANDLE;\r\nint hBands_v = INVALID_HANDLE;\r\nvoid AgregarIndicadoresVisuales()', 'void AgregarIndicadoresVisuales()');

// Add to the proper global section below hEMA_v
content = content.replace('int hEMA_v = INVALID_HANDLE;\nint hRSI_v = INVALID_HANDLE;', 'int hEMA_v = INVALID_HANDLE;\nint hRSI_v = INVALID_HANDLE;\nint hATR_v = INVALID_HANDLE;\nint hBands_v = INVALID_HANDLE;');
content = content.replace('int hEMA_v = INVALID_HANDLE;\r\nint hRSI_v = INVALID_HANDLE;', 'int hEMA_v = INVALID_HANDLE;\r\nint hRSI_v = INVALID_HANDLE;\r\nint hATR_v = INVALID_HANDLE;\r\nint hBands_v = INVALID_HANDLE;');

fs.writeFileSync(file1, content, 'utf8');
fs.writeFileSync(file2, content, 'utf8');

let editorPath = "C:\\Program Files\\MetaTrader 5\\metaeditor64.exe";
execSync(`"${editorPath}" /compile:"${file1}" /log`);
execSync(`"${editorPath}" /compile:"${file2}" /log`);
