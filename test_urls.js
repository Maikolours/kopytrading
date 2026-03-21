
async function test() {
    const urls = [
        'https://kopytrading.com/api/sync-positions',
        'https://www.kopytrading.com/api/sync-positions'
    ];

    for (const url of urls) {
        console.log(`Testing: ${url}`);
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ purchaseId: "test", account: "123" })
            });
            console.log(`Response: ${response.status} ${response.statusText}`);
            const text = await response.text();
            console.log(`Body: ${text}`);
        } catch (error) {
            console.log(`Error: ${error.message}`);
        }
    }
}

test();
