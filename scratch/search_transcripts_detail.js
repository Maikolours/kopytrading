const fs = require('fs');
const path = require('path');

const brainDir = 'C:\\Users\\Usuario\\.gemini\\antigravity\\brain';
const dir = 'ecfcc189-37d9-4b74-8fc9-5280bb6d8aa3';
const transcriptPath = path.join(brainDir, dir, '.system_generated', 'logs', 'transcript.jsonl');

console.log(`--- DETAIL SEARCH IN ${dir} ---`);

if (fs.existsSync(transcriptPath)) {
    const content = fs.readFileSync(transcriptPath, 'utf8');
    const lines = content.split('\n');
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (!line.trim()) continue;
        try {
            const parsed = JSON.parse(line);
            
            // We want to inspect:
            // 1. All USER messages
            // 2. Any MODEL messages that talk about CASCADA or SOS
            if (parsed.type === 'USER_INPUT') {
                const userText = parsed.content || '';
                console.log(`\n[Line ${i+1}] USER INPUT:`);
                console.log(userText);
            }
            
            if (parsed.type === 'PLANNER_RESPONSE') {
                const modelText = parsed.content || '';
                if (modelText.includes("CASCADA") || modelText.includes("SOS")) {
                    console.log(`\n[Line ${i+1}] MODEL PLANNER RESPONSE (truncated):`);
                    console.log(modelText.substring(0, 500) + "...");
                }
            }
        } catch (e) {
            // Ignore JSON parse error
        }
    }
} else {
    console.log("Transcript not found.");
}
