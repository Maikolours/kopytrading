
const axios = require('axios');

async function test() {
    const data = {
        purchaseId: "cmmv3xvgp000uvhmcraiay5l4",
        account: "123456",
        positions: [],
        history: []
    };

    try {
        const response = await axios.post('https://www.kopytrading.com/api/sync-positions', data);
        console.log('Response:', response.status, response.data);
    } catch (error) {
        if (error.response) {
            console.log('Error Response:', error.response.status, error.response.data);
        } else {
            console.log('Error:', error.message);
        }
    }
}

test();
