const fs = require('fs');
const path = require('path');

const centDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\F762D69EEEA9B4430D7F17C82167C844';
const goldDir = 'C:\\Users\\Usuario\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075';

function findTodayFiles(dir, label) {
    console.log(`\n=== TODAY'S FILES FOR ${label} ===`);
    const today = new Date().toISOString().substring(0, 10).replace(/-/g, '');
    
    function traverse(currentDir) {
        let files = [];
        try {
            files = fs.readdirSync(currentDir);
        } catch (e) {
            return;
        }
        
        files.forEach(file => {
            const fullPath = path.join(currentDir, file);
            let stat;
            try {
                stat = fs.statSync(fullPath);
            } catch (e) {
                return;
            }
            
            if (stat.isDirectory()) {
                traverse(fullPath);
            } else {
                const mtime = stat.mtime;
                const fileDate = mtime.toISOString().substring(0, 10);
                const todayDateStr = new Date().toISOString().substring(0, 10);
                if (fileDate === todayDateStr) {
                    console.log(`Path: ${fullPath} | Size: ${stat.size} | Modified: ${mtime}`);
                }
            }
        });
    }
    
    traverse(dir);
}

findTodayFiles(centDir, 'CENT');
findTodayFiles(goldDir, 'GOLD');
