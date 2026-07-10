const fs = require('fs');
const path = require('path');

const baseDir = "C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal";

async function main() {
  console.log("=== Finding MT5 Terminal Accounts ===");

  if (!fs.existsSync(baseDir)) {
    console.error("Base directory does not exist:", baseDir);
    return;
  }

  const dirs = fs.readdirSync(baseDir).filter(f => {
    return fs.statSync(path.join(baseDir, f)).isDirectory() && f !== 'Common' && f !== 'Community' && f !== 'Help';
  });

  for (const dir of dirs) {
    const logDir = path.join(baseDir, dir, 'logs');
    if (!fs.existsSync(logDir)) continue;

    console.log(`\nTerminal Folder: ${dir}`);
    
    // Find all .log files in logDir
    const logFiles = fs.readdirSync(logDir)
      .filter(f => f.endsWith('.log') && f !== 'metaeditor.log')
      .sort()
      .reverse(); // Latest first

    let found = false;
    for (const logFile of logFiles.slice(0, 50)) { // Scan up to 50 files
      const logPath = path.join(logDir, logFile);
      const stats = fs.statSync(logPath);
      if (stats.size === 0) continue;

      const content = fs.readFileSync(logPath, 'utf8');
      
      const lines = content.split('\n');
      for (const line of lines) {
        if (line.includes('login on') || line.includes('login datacenter') || line.includes('authorized on')) {
          console.log(`  Log (${logFile}): ${line.trim().substring(0, 150)}`);
          found = true;
          break; // Stop scanning lines in this file if found
        }
      }
      if (found) break; // Stop checking other files if found
    }
    
    if (!found) {
      console.log("  No authorization logs found in recent log files.");
    }
  }
}

main().catch(console.error);
