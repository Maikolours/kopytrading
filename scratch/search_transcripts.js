const fs = require('fs');
const path = require('path');

const brainDir = 'C:\\Users\\Usuario\\.gemini\\antigravity\\brain';
const directories = fs.readdirSync(brainDir);

console.log("--- SEARCHING TRANSCRIPTS ---");

for (const dir of directories) {
    const transcriptPath = path.join(brainDir, dir, '.system_generated', 'logs', 'transcript.jsonl');
    if (fs.existsSync(transcriptPath)) {
        console.log(`Searching in conversation: ${dir}...`);
        const content = fs.readFileSync(transcriptPath, 'utf8');
        const lines = content.split('\n');
        
        let matchCount = 0;
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.includes("CASCADA") || line.includes("SOS")) {
                matchCount++;
                if (matchCount <= 5) {
                    console.log(`  Line ${i+1}:`);
                    // Try to parse JSON and get user/agent text
                    try {
                        const parsed = JSON.parse(line);
                        console.log(`    Source: ${parsed.source} | Type: ${parsed.type}`);
                        console.log(`    Content snippet: ${parsed.content ? parsed.content.substring(0, 300) : ''}`);
                    } catch (e) {
                        console.log(`    Raw (truncated): ${line.substring(0, 300)}`);
                    }
                }
            }
        }
        console.log(`  Total matches in ${dir}: ${matchCount}\n`);
    }
}
