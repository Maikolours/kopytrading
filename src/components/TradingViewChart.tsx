"use client";

import React, { useEffect, useRef, memo } from 'react';

interface TradingViewChartProps {
  symbol?: string;
}

function TradingViewChart({ symbol = "BINANCE:BTCUSDT" }: TradingViewChartProps) {
  const container = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!container.current) return;

    const script = document.createElement("script");
    script.src = "https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js";
    script.type = "text/javascript";
    script.async = true;
    script.innerHTML = JSON.stringify({
      "autosize": true,
      "symbol": symbol, // AHORA ES DINÁMICO
      "interval": "60",
      "timezone": "Etc/UTC",
      "theme": "dark",
      "style": "1",
      "locale": "en",
      "enable_publishing": false,
      "allow_symbol_change": true,
      "calendar": false,
      "support_host": "https://www.tradingview.com",
      "container_id": "tradingview_chart_container"
    });
    
    container.current.appendChild(script);

    return () => {
      if (container.current) {
        container.current.innerHTML = "";
      }
    };
  }, [symbol]); // Recargar si cambia el símbolo

  return (
    <div className="tradingview-widget-container rounded-3xl overflow-hidden border border-white/5 bg-black/20" style={{ height: "400px", width: "100%" }}>
      <div id="tradingview_chart_container" ref={container} style={{ height: "100%", width: "100%" }} />
    </div>
  );
}

export default memo(TradingViewChart);
