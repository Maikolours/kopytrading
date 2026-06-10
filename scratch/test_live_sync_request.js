async function test() {
  const url = "https://www.kopytrading.com/api/sync-positions";
  const payload = {
    purchaseId: "cmn9hfal4000fvhbcr34kst5x",
    account: "11649344",
    balance: 500.00,
    equity: 500.00,
    pnl_today: 0.00,
    status: "ONLINE",
    symbol: "XAUUSD",
    narrative: "Testing demo sync",
    armed: true,
    isReal: false,
    version: "11.30",
    positions: []
  };

  console.log("Sending payload to", url);
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    console.log("Status:", res.status);
    const text = await res.text();
    console.log("Response:", text);
  } catch (err) {
    console.error("Error:", err);
  }
}

test();
