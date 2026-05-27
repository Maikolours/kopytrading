<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>BTCUSD Fibonacci Bot</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{background:#0d1117;color:#e6edf3;font-family:'Segoe UI',system-ui,sans-serif;overflow:hidden;height:100vh;width:100vw}
#wrap{position:relative;width:100vw;height:100vh}
#cv{display:block;width:100%;height:100%}
#hud{position:absolute;top:12px;right:12px;width:285px;background:rgba(10,14,20,.95);border:1px solid rgba(255,255,255,.13);border-radius:13px;backdrop-filter:blur(16px);z-index:200;cursor:move;user-select:none;box-shadow:0 8px 40px rgba(0,0,0,.6)}
.hdr{display:flex;align-items:center;justify-content:space-between;padding:8px 11px;border-bottom:1px solid rgba(255,255,255,.07);background:rgba(255,255,255,.03);border-radius:13px 13px 0 0}
.logo{display:flex;align-items:center;gap:7px}
#ldot{width:8px;height:8px;border-radius:50%;background:#f85149}
.htitle{font-size:12px;font-weight:700;color:#58a6ff;letter-spacing:.6px}
.hver{font-size:9px;color:rgba(255,255,255,.3);margin-left:2px}
.hbtns{display:flex;gap:5px}
.hb{width:20px;height:20px;border-radius:50%;border:none;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:700;transition:transform .1s}
.hb:hover{transform:scale(1.15)}
.hb-min{background:#f0c040;color:#000}.hb-snd{background:#3fb950;color:#000}.hb-pwr{background:#f85149;color:#fff}
.body{padding:10px 12px;display:flex;flex-direction:column;gap:8px;max-height:600px;overflow-y:auto;overflow-x:hidden;transition:max-height .25s ease,padding .25s ease}
.body.mini{max-height:0;padding:0 12px}
.body::-webkit-scrollbar{width:3px}
.body::-webkit-scrollbar-thumb{background:rgba(255,255,255,.15);border-radius:2px}
.st{font-size:9px;font-weight:700;letter-spacing:1px;color:rgba(255,255,255,.3);text-transform:uppercase;margin-bottom:1px}
.dvd{height:1px;background:rgba(255,255,255,.06)}
.inp{width:100%;background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.11);border-radius:6px;color:#e6edf3;font-size:11.5px;padding:5px 9px;outline:none;transition:border-color .2s}
.inp:focus{border-color:#58a6ff;background:rgba(88,166,255,.06)}
.inp::placeholder{color:rgba(255,255,255,.25)}
.badge{display:inline-flex;align-items:center;gap:6px;padding:4px 11px;border-radius:20px;font-size:11px;font-weight:700;letter-spacing:.4px;border:1px solid;width:fit-content}
.sdot{width:7px;height:7px;border-radius:50%}
.s-off{background:rgba(248,81,73,.12);color:#f85149;border-color:rgba(248,81,73,.5)}
.s-off .sdot{background:#f85149}
.s-wait{background:rgba(240,192,64,.12);color:#f0c040;border-color:rgba(240,192,64,.5)}
.s-wait .sdot{background:#f0c040;animation:pulse 1.2s infinite}
.s-enter{background:rgba(63,185,80,.12);color:#3fb950;border-color:rgba(63,185,80,.5)}
.s-enter .sdot{background:#3fb950;animation:pulse .7s infinite}
.s-trade{background:rgba(88,166,255,.12);color:#58a6ff;border-color:rgba(88,166,255,.5)}
.s-trade .sdot{background:#58a6ff;animation:pulse 1.5s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.2}}
.row{display:flex;align-items:center;justify-content:space-between}
.tb{display:flex;align-items:center;gap:4px;font-size:11px;font-weight:700;padding:3px 8px;border-radius:5px}
.tb-bull{background:rgba(63,185,80,.13);color:#3fb950}.tb-bear{background:rgba(248,81,73,.13);color:#f85149}.tb-neut{background:rgba(255,255,255,.07);color:rgba(255,255,255,.4)}
.pricebig{font-size:17px;font-weight:700;color:#e6edf3;font-variant-numeric:tabular-nums}
.fibt{width:100%;border-collapse:collapse}
.fibt td{padding:2.5px 5px;font-size:11px}
.fibt tr:hover td{background:rgba(255,255,255,.03)}
.fdot{width:9px;height:9px;border-radius:2px;display:inline-block;vertical-align:middle;margin-right:4px}
.fn{color:rgba(255,255,255,.55)}.fp{color:#e6edf3;text-align:right;font-variant-numeric:tabular-nums;font-weight:500}
.prow{display:flex;align-items:center;justify-content:space-between;gap:8px}
.pl{font-size:11px;color:rgba(255,255,255,.5);flex:1;white-space:nowrap}
.pi{width:60px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.11);border-radius:4px;color:#e6edf3;font-size:11px;padding:3px 6px;text-align:right;outline:none}
.pi:focus{border-color:#58a6ff}
.pb{padding:3px 9px;border-radius:5px;border:1px solid;font-size:10.5px;font-weight:700;cursor:pointer;transition:opacity .15s,transform .1s;background:transparent;white-space:nowrap}
.pb:hover{opacity:.75}.pb:active{transform:scale(.96)}
.pg{color:#3fb950;border-color:rgba(63,185,80,.5)}.py{color:#f0c040;border-color:rgba(240,192,64,.5)}.pr{color:#f85149;border-color:rgba(248,81,73,.5)}.pb2{color:#58a6ff;border-color:rgba(88,166,255,.5)}
.bfull{width:100%;padding:7px 12px;border-radius:8px;border:1px solid;font-size:11.5px;font-weight:700;cursor:pointer;text-align:center;background:transparent;transition:opacity .15s,transform .1s}
.bfull:hover{opacity:.8}.bfull:active{transform:scale(.98)}
.ni{display:flex;align-items:center;justify-content:space-between;padding:4px 8px;border-radius:5px;background:rgba(255,255,255,.03);border-left:3px solid}
.ni-h{border-color:#f85149}.ni-m{border-color:#f0c040}.ni-l{border-color:#3fb950}
.nin{font-size:10.5px;color:rgba(255,255,255,.65)}.nit{font-size:9.5px;color:rgba(255,255,255,.35)}.ni-blk{background:rgba(248,81,73,.07)!important}
#tov{position:absolute;top:12px;left:12px;background:rgba(10,14,20,.9);border:1px solid rgba(255,255,255,.1);border-radius:9px;padding:8px 13px;pointer-events:none;display:flex;flex-direction:column;gap:4px;z-index:100}
.trow{display:flex;align-items:center;gap:8px;font-size:11px}
.tl{color:rgba(255,255,255,.35);min-width:28px}.tv{font-weight:600}
.tv-bull{color:#3fb950}.tv-bear{color:#f85149}.tv-neut{color:rgba(255,255,255,.4)}
#cinfo{position:absolute;bottom:16px;left:12px;background:rgba(10,14,20,.9);border:1px solid rgba(255,255,255,.1);border-radius:8px;padding:7px 12px;font-size:10.5px;color:rgba(255,255,255,.45);pointer-events:none;z-index:100;line-height:1.9}
#cinfo b{color:#e6edf3}
#nwarn{position:absolute;top:12px;left:50%;transform:translateX(-50%);background:rgba(248,81,73,.15);border:1px solid rgba(248,81,73,.5);border-radius:20px;padding:5px 16px;font-size:11.5px;color:#f85149;font-weight:700;display:none;z-index:100;letter-spacing:.3px}
#toast{position:absolute;bottom:60px;left:50%;transform:translateX(-50%);background:#3fb950;color:#000;font-weight:700;font-size:12px;padding:7px 20px;border-radius:20px;display:none;white-space:nowrap;z-index:300;box-shadow:0 0 20px rgba(63,185,80,.4)}
</style>
</head>
<body>
<div id="wrap">
  <canvas id="cv"></canvas>

  <div id="tov">
    <div class="trow"><span class="tl">4H</span><span class="tv" id="ov4">—</span></div>
    <div class="trow"><span class="tl">1H</span><span class="tv" id="ov1">—</span></div>
    <div class="trow"><span class="tl">RSI</span><span class="tv" id="ovr" style="color:#e6edf3">—</span></div>
    <div class="trow"><span class="tl">ATR</span><span class="tv" id="ova" style="color:#e6edf3">—</span></div>
  </div>

  <div id="cinfo">
    Símbolo: <b>BTC/USDT</b> &nbsp;|&nbsp; TF Operación: <b>1H</b> &nbsp;|&nbsp; TF Filtro: <b>4H</b><br>
    Swing lookback: <b id="ci-sw">50</b> velas &nbsp;|&nbsp; Velas necesarias: <b>200</b><br>
    Fibonacci entrada: <b>0.618</b> &nbsp;|&nbsp; Zona peligro: <b>0.786</b>
  </div>

  <div id="nwarn">&#9888; BLOQUEO POR NOTICIAS — No se opera durante 30 min</div>
  <div id="toast">Señal detectada</div>

  <div id="hud">
    <div class="hdr">
      <div class="logo"><div id="ldot"></div><span class="htitle">FIB BOT</span><span class="hver">v1.0</span></div>
      <div class="hbtns">
        <button class="hb hb-snd" id="bsnd" title="Audio">&#128276;</button>
        <button class="hb hb-min" id="bmin" title="Minimizar">&#8722;</button>
        <button class="hb hb-pwr" id="bpwr" title="Encender/Apagar">&#9632;</button>
      </div>
    </div>

    <div class="body" id="hbody">

      <div>
        <div class="st">Licencia &amp; Cuenta MT5</div>
        <div style="display:flex;flex-direction:column;gap:5px;margin-top:4px">
          <input class="inp" id="ilic" placeholder="ID de Licencia" maxlength="32">
          <input class="inp" id="imt5" placeholder="Numero de cuenta MT5" maxlength="20">
          <button class="bfull pb2" id="bact">Activar Licencia</button>
        </div>
      </div>

      <div class="dvd"></div>

      <div>
        <div class="st">Estado del Bot</div>
        <div class="row" style="margin-top:5px">
          <div id="sbadge" class="badge s-off"><div class="sdot"></div><span id="stxt">APAGADO</span></div>
          <button class="pb pg" id="bstart">&#9654; Iniciar</button>
        </div>
      </div>

      <div class="dvd"></div>

      <div>
        <div class="st">Mercado</div>
        <div class="row" style="margin-top:5px">
          <span class="pricebig" id="hprice">$—</span>
          <div id="htrend" class="tb tb-neut">— NEUTRAL</div>
        </div>
        <div style="font-size:10px;color:rgba(255,255,255,.3);margin-top:3px" id="hswing">Swing: —</div>
      </div>

      <div class="dvd"></div>

      <div>
        <div class="st">Niveles Fibonacci (1H)</div>
        <table class="fibt" style="margin-top:4px">
          <tr><td><span class="fdot" style="background:#666"></span><span class="fn">1.000 High</span></td><td class="fp" id="f10">—</td></tr>
          <tr><td><span class="fdot" style="background:#c678dd"></span><span class="fn">0.786 Peligro</span></td><td class="fp" id="f78">—</td></tr>
          <tr><td><span class="fdot" style="background:#e06c75"></span><span class="fn">0.618 Entrada</span></td><td class="fp" id="f61">—</td></tr>
          <tr><td><span class="fdot" style="background:#e5c07b"></span><span class="fn">0.500 TP Rescate</span></td><td class="fp" id="f50">—</td></tr>
          <tr><td><span class="fdot" style="background:#98c379"></span><span class="fn">0.382</span></td><td class="fp" id="f38">—</td></tr>
          <tr><td><span class="fdot" style="background:#56b6c2"></span><span class="fn">0.236</span></td><td class="fp" id="f23">—</td></tr>
          <tr><td><span class="fdot" style="background:#666"></span><span class="fn">0.000 Low</span></td><td class="fp" id="f00">—</td></tr>
        </table>
      </div>

      <div class="dvd"></div>

      <div>
        <div class="st">Operacion Activa</div>
        <div id="tinfo" style="margin-top:5px">
          <div style="font-size:11px;color:rgba(255,255,255,.3)">Sin operacion abierta</div>
        </div>
        <button class="bfull pr" id="bclose" style="display:none;margin-top:6px">&#10005; Cerrar Operacion</button>
      </div>

      <div class="dvd"></div>

      <div>
        <div class="st">Parametros</div>
        <div style="display:flex;flex-direction:column;gap:5px;margin-top:5px">
          <div class="prow"><span class="pl">Riesgo por op (%)</span><input class="pi" id="prisk" type="number" value="1.0" min="0.1" max="5" step="0.1"></div>
          <div class="prow"><span class="pl">ATR Multiplicador</span><input class="pi" id="patr" type="number" value="1.5" min="0.5" max="4" step="0.1"></div>
          <div class="prow"><span class="pl">Ratio R:R minimo</span><input class="pi" id="prr" type="number" value="2.0" min="1" max="5" step="0.1"></div>
          <div class="prow"><span class="pl">Swing lookback</span><input class="pi" id="pswing" type="number" value="50" min="20" max="100" step="5"></div>
          <div class="prow"><span class="pl">RSI Sobrecompra</span><input class="pi" id="prsib" type="number" value="65" min="55" max="80" step="1"></div>
          <div class="prow"><span class="pl">RSI Sobreventa</span><input class="pi" id="prsis" type="number" value="35" min="20" max="45" step="1"></div>
          <div class="prow"><span class="pl">EMA Rapida</span><input class="pi" id="pemaf" type="number" value="21" min="5" max="50" step="1"></div>
          <div class="prow"><span class="pl">EMA Lenta</span><input class="pi" id="pemas" type="number" value="55" min="20" max="100" step="1"></div>
          <div class="prow"><span class="pl">EMA Tendencia</span><input class="pi" id="pemat" type="number" value="200" min="50" max="400" step="10"></div>
          <div style="display:flex;gap:5px;margin-top:2px">
            <button class="pb pg" style="flex:1" onclick="applyP()">Aplicar</button>
            <button class="pb py" style="flex:1" onclick="resetP()">Reset</button>
          </div>
        </div>
      </div>

      <div class="dvd"></div>

      <div>
        <div class="st">Filtro de Noticias</div>
        <div class="row" style="margin:5px 0 6px">
          <span style="font-size:11px;color:rgba(255,255,255,.5)">Bloquear +/- 30 min</span>
          <button class="pb py" id="bntog" onclick="togNews()">Activo</button>
        </div>
        <div id="nlist" style="display:flex;flex-direction:column;gap:4px"></div>
      </div>

    </div>
  </div>
</div>

<script>
var P={risk:1,atrM:1.5,rr:2,swing:50,rsib:65,rsis:35,emaf:21,emas:55,emat:200};
var botOn=false,sndOn=true,newsOn=true,minimized=false,loopId=null,tickId=null;

function genCandles(n,base,vol){
  var now=Math.floor(Date.now()/1000),out=[],p=base;
  for(var i=n;i>=0;i--){
    var t=now-i*3600,mv=(Math.random()-.487)*vol,op=p;
    p+=mv;
    var hi=Math.max(op,p)+Math.random()*vol*.5,lo=Math.min(op,p)-Math.random()*vol*.5;
    out.push({t:t,o:+op.toFixed(2),h:+hi.toFixed(2),l:+lo.toFixed(2),c:+p.toFixed(2),v:Math.floor(Math.random()*800+200)});
  }
  return out;
}
var candles=genCandles(150,70500,320);
for(var i=70;i<100;i++) candles[i].c=71400-(i-70)*220;
for(var i=100;i<130;i++) candles[i].c=candles[99].c+(i-100)*110;
candles[candles.length-1].c=67420;
candles.forEach(function(c,i){
  var prev=i>0?candles[i-1].c:c.o;
  c.o=+prev.toFixed(2);
  c.h=+(Math.max(c.o,c.c)+Math.random()*200).toFixed(2);
  c.l=+(Math.min(c.o,c.c)-Math.random()*200).toFixed(2);
});

function calcEMA(arr,p){
  var k=2/(p+1),r=[],s=0;
  for(var i=0;i<arr.length;i++){
    s+=arr[i];
    if(i<p-1){r.push(null);continue}
    if(i===p-1){r.push(s/p);continue}
    r.push(arr[i]*k+r[i-1]*(1-k));
  }
  return r;
}
function calcRSI(arr,p){
  var g=0,l=0;
  for(var i=1;i<=p;i++){var d=arr[i]-arr[i-1];d>0?g+=d:l-=d}
  var ag=g/p,al=l/p;
  for(var i=p+1;i<arr.length;i++){var d=arr[i]-arr[i-1];ag=(ag*(p-1)+Math.max(d,0))/p;al=(al*(p-1)+Math.max(-d,0))/p}
  return al===0?100:100-100/(1+ag/al);
}
function calcATR(cs,p){
  var trs=[];
  for(var i=1;i<cs.length;i++) trs.push(Math.max(cs[i].h-cs[i].l,Math.abs(cs[i].h-cs[i-1].c),Math.abs(cs[i].l-cs[i-1].c)));
  return trs.slice(-p).reduce(function(a,b){return a+b},0)/p;
}
function detectSwing(cs,lb){
  var sl=cs.slice(-lb),sh=-Infinity,sv=Infinity,si=0,li=0;
  sl.forEach(function(c,i){if(c.h>sh){sh=c.h;si=i}if(c.l<sv){sv=c.l;li=i}});
  return{sh:sh,sv:sv,dir:li<si?'bullish':'bearish'};
}
function fibLevels(sh,sv,dir){
  var d=sh-sv,rs=[0,.236,.382,.5,.618,.786,1],o={};
  rs.forEach(function(r){o[r]=dir==='bullish'?sh-d*r:sv+d*r});
  return o;
}

var cv=document.getElementById('cv'),ctx=cv.getContext('2d');
var PAD={top:40,right:95,bottom:28,left:8};
var W,H,cW,cH;
function resize(){W=cv.width=window.innerWidth;H=cv.height=window.innerHeight;cW=W-PAD.left-PAD.right;cH=H-PAD.top-PAD.bottom}
resize();
window.addEventListener('resize',function(){resize();drawAll()});

function py(price,lo,hi){return PAD.top+cH-(price-lo)/(hi-lo)*cH}
function cx(i,n){return PAD.left+((i+.5)/n)*cW}

function drawAll(){
  ctx.clearRect(0,0,W,H);
  var n=candles.length;
  if(!n)return;
  var lo=Infinity,hi=-Infinity;
  candles.forEach(function(c){if(c.h>hi)hi=c.h;if(c.l<lo)lo=c.l});
  var pad=(hi-lo)*.07;lo-=pad;hi+=pad;

  // grid
  ctx.strokeStyle='rgba(255,255,255,.04)';ctx.lineWidth=1;
  for(var i=0;i<6;i++){
    var y=PAD.top+cH*i/5;
    ctx.beginPath();ctx.moveTo(PAD.left,y);ctx.lineTo(W-PAD.right,y);ctx.stroke();
    var price=hi-(hi-lo)*i/5;
    ctx.fillStyle='rgba(255,255,255,.3)';ctx.font='10px Segoe UI';ctx.textAlign='left';
    ctx.fillText('$'+price.toFixed(0),W-PAD.right+6,y+4);
  }

  // volume
  var maxV=Math.max.apply(null,candles.map(function(c){return c.v}));
  var vH=cH*.14;
  candles.forEach(function(c,i){
    var x=cx(i,n),bw=Math.max((cW/n)*.65,1.2),bh=(c.v/maxV)*vH;
    ctx.fillStyle=c.c>=c.o?'rgba(63,185,80,.18)':'rgba(248,81,73,.18)';
    ctx.fillRect(x-bw/2,PAD.top+cH-bh,bw,bh);
  });

  // EMAs
  var closes=candles.map(function(c){return c.c});
  var e21=calcEMA(closes,P.emaf),e55=calcEMA(closes,P.emas),e200=calcEMA(closes,P.emat);
  [[e21,'rgba(240,192,64,.75)'],[e55,'rgba(88,166,255,.75)'],[e200,'rgba(255,255,255,.22)']].forEach(function(pair){
    var arr=pair[0],col=pair[1];
    ctx.strokeStyle=col;ctx.lineWidth=1.2;ctx.beginPath();var s=false;
    arr.forEach(function(v,i){if(v===null)return;var x=cx(i,n),y=py(v,lo,hi);if(!s){ctx.moveTo(x,y);s=true}else ctx.lineTo(x,y)});
    ctx.stroke();
  });

  // Fibonacci
  if(botOn){
    var sw=detectSwing(candles,P.swing),fibs=fibLevels(sw.sh,sw.sv,sw.dir);
    var fibCfg={'0':{col:'#888',w:1,dash:[4,4]},'.236':{col:'#56b6c2',w:1,dash:[4,4]},
      '.382':{col:'#98c379',w:1,dash:[4,4]},'.5':{col:'#e5c07b',w:1.5,dash:[4,4]},
      '.618':{col:'#e06c75',w:2.2,dash:[]},'.786':{col:'#c678dd',w:1.5,dash:[6,3]},'1':{col:'#888',w:1,dash:[4,4]}};
    var fibLbl={'0':'0.000','.236':'0.236','.382':'0.382','.5':'0.500 TP',
      '.618':'0.618 ENTRADA','.786':'0.786 PELIGRO','1':'1.000'};

    var y618=py(fibs[.618],lo,hi),y786=py(fibs[.786],lo,hi);
    var yTop=Math.min(y618,y786),yBot=Math.max(y618,y786);
    var sx=cx(Math.max(0,n-45),n);
    ctx.fillStyle='rgba(224,108,117,.09)';
    ctx.fillRect(sx,yTop,W-PAD.right-sx,yBot-yTop);

    Object.keys(fibCfg).forEach(function(key){
      var r=parseFloat(key),price=fibs[r],cfg=fibCfg[key];
      if(price===undefined)return;
      var y=py(price,lo,hi);
      ctx.strokeStyle=cfg.col;ctx.lineWidth=cfg.w;ctx.setLineDash(cfg.dash);
      ctx.beginPath();ctx.moveTo(PAD.left,y);ctx.lineTo(W-PAD.right,y);ctx.stroke();
      ctx.setLineDash([]);
      ctx.fillStyle=cfg.col;ctx.font=(cfg.w>1.5?'bold ':'')+' 9.5px Segoe UI';ctx.textAlign='left';
      ctx.fillText(fibLbl[key]+' $'+price.toFixed(0),W-PAD.right+4,y-3);
    });
  }

  // candles
  candles.forEach(function(c,i){
    var x=cx(i,n),bw=Math.max((cW/n)*.68,1.5),col=c.c>=c.o?'#3fb950':'#f85149';
    ctx.strokeStyle=col;ctx.lineWidth=1;
    ctx.beginPath();ctx.moveTo(x,py(c.h,lo,hi));ctx.lineTo(x,py(c.l,lo,hi));ctx.stroke();
    var yo=py(c.o,lo,hi),yc=py(c.c,lo,hi),bh=Math.max(Math.abs(yc-yo),1.5);
    ctx.fillStyle=col;ctx.fillRect(x-bw/2,Math.min(yo,yc),bw,bh);
  });

  // current price tag
  var last=candles[candles.length-1],yp=py(last.c,lo,hi);
  ctx.strokeStyle='rgba(255,255,255,.4)';ctx.lineWidth=1;ctx.setLineDash([3,4]);
  ctx.beginPath();ctx.moveTo(PAD.left,yp);ctx.lineTo(W-PAD.right,yp);ctx.stroke();
  ctx.setLineDash([]);
  ctx.fillStyle='rgba(255,255,255,.13)';ctx.fillRect(W-PAD.right+2,yp-9,88,18);
  ctx.fillStyle='#e6edf3';ctx.font='bold 10px Segoe UI';ctx.textAlign='left';
  ctx.fillText('$'+last.c.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2}),W-PAD.right+5,yp+4);

  // time axis
  ctx.fillStyle='rgba(255,255,255,.28)';ctx.font='9px Segoe UI';ctx.textAlign='center';
  var step=Math.ceil(n/8);
  candles.forEach(function(c,i){
    if(i%step!==0)return;
    var d=new Date(c.t*1000);
    ctx.fillText((d.getMonth()+1)+'/'+d.getDate()+' '+d.getHours()+':00',cx(i,n),H-8);
  });
}

var now0=Date.now();
var NEWS=[
  {name:'Fed Interest Rate',t:now0+22*60000,imp:'high'},
  {name:'CPI Core YoY',t:now0+95*60000,imp:'high'},
  {name:'US Jobless Claims',t:now0+185*60000,imp:'medium'},
  {name:'PMI Manufacturing',t:now0-12*60000,imp:'medium'},
  {name:'GDP Quarterly',t:now0+310*60000,imp:'high'}
];
function isBlocked(){if(!newsOn)return false;return NEWS.some(function(n){return Math.abs(n.t-Date.now())<30*60000})}
function renderNews(){
  var el=document.getElementById('nlist');el.innerHTML='';
  NEWS.slice().sort(function(a,b){return Math.abs(a.t-Date.now())-Math.abs(b.t-Date.now())}).slice(0,4).forEach(function(n){
    var mins=Math.round((n.t-Date.now())/60000),lab=mins>0?'en '+mins+' min':'hace '+(-mins)+' min';
    var blk=Math.abs(n.t-Date.now())<30*60000,cls=n.imp==='high'?'ni-h':n.imp==='medium'?'ni-m':'ni-l';
    var d=document.createElement('div');
    d.className='ni '+cls+(blk?' ni-blk':'');
    d.innerHTML='<span class="nin">'+(blk?'&#128683; ':'')+n.name+'</span><span class="nit">'+lab+'</span>';
    el.appendChild(d);
  });
}

function fmt(v){return '$'+v.toLocaleString('en-US',{minimumFractionDigits:2,maximumFractionDigits:2})}

function updateHUD(){
  if(!botOn)return;
  var n=candles.length,closes=candles.map(function(c){return c.c});
  var e21=calcEMA(closes,P.emaf),e55=calcEMA(closes,P.emas),e200=calcEMA(closes,P.emat);
  var last=candles[n-1],atv=calcATR(candles,14),rv=calcRSI(closes,14);
  var t1=e21[n-1]>e55[n-1]&&last.c>e200[n-1]?'bullish':e21[n-1]<e55[n-1]&&last.c<e200[n-1]?'bearish':'neutral';
  var c4=candles.filter(function(_,i){return i%4===0}),cl4=c4.map(function(c){return c.c});
  var e4f=calcEMA(cl4,21),e4s=calcEMA(cl4,55),e4t=calcEMA(cl4,200),l4=c4[c4.length-1];
  var t4=e4f[e4f.length-1]>e4s[e4s.length-1]&&l4.c>e4t[e4t.length-1]?'bullish':e4f[e4f.length-1]<e4s[e4s.length-1]&&l4.c<e4t[e4t.length-1]?'bearish':'neutral';
  var sw=detectSwing(candles,P.swing),fibs=fibLevels(sw.sh,sw.sv,sw.dir);

  function tc(c){return'tv-'+(c==='bullish'?'bull':c==='bearish'?'bear':'neut')}
  document.getElementById('ov4').className='tv '+tc(t4);document.getElementById('ov4').textContent=t4.toUpperCase();
  document.getElementById('ov1').className='tv '+tc(t1);document.getElementById('ov1').textContent=t1.toUpperCase();
  document.getElementById('ovr').textContent=rv.toFixed(1);
  document.getElementById('ovr').style.color=rv>P.rsib?'#f85149':rv<P.rsis?'#3fb950':'#e6edf3';
  document.getElementById('ova').textContent='$'+atv.toFixed(0);
  document.getElementById('hprice').textContent=fmt(last.c);
  var tb=document.getElementById('htrend');
  if(t4==='bullish'){tb.className='tb tb-bull';tb.textContent='ALCISTA 4H'}
  else if(t4==='bearish'){tb.className='tb tb-bear';tb.textContent='BAJISTA 4H'}
  else{tb.className='tb tb-neut';tb.textContent='NEUTRAL'}
  document.getElementById('hswing').textContent='Swing H: '+fmt(sw.sh)+'  |  Swing L: '+fmt(sw.sv)+'  |  Dir: '+sw.dir;
  document.getElementById('f10').textContent=fmt(fibs[1]);
  document.getElementById('f78').textContent=fmt(fibs[.786]);
  document.getElementById('f61').textContent=fmt(fibs[.618]);
  document.getElementById('f50').textContent=fmt(fibs[.5]);
  document.getElementById('f38').textContent=fmt(fibs[.382]);
  document.getElementById('f23').textContent=fmt(fibs[.236]);
  document.getElementById('f00').textContent=fmt(fibs[0]);
  var inZone=Math.abs(last.c-fibs[.618])<atv*.5,trendOk=t4===t1&&t4!=='neutral';
  var rsiOk=t4==='bullish'?rv<P.rsib:rv>P.rsis,blocked=isBlocked();
  document.getElementById('nwarn').style.display=blocked?'block':'none';
  if(blocked||!trendOk){setStatus('waiting')}
  else if(inZone&&rsiOk){setStatus('entering');playAlert();showToast('SEÑAL — Fib 0.618 + Tendencia alineada')}
  else{setStatus('waiting')}
  renderNews();drawAll();
}

function setStatus(s){
  var b=document.getElementById('sbadge'),t=document.getElementById('stxt');
  b.className='badge';
  var map={off:['s-off','APAGADO'],waiting:['s-wait','ESPERANDO SEÑAL'],entering:['s-enter','ENTRANDO'],intrade:['s-trade','EN OPERACION']};
  b.classList.add(map[s][0]);t.textContent=map[s][1];
  var d=document.getElementById('ldot');
  d.style.background=s==='entering'?'#3fb950':s==='intrade'?'#58a6ff':s==='waiting'?'#f0c040':'#f85149';
  d.style.animation=s==='off'?'none':'pulse 2s infinite';
}
function showToast(m){var el=document.getElementById('toast');el.textContent=m;el.style.display='block';setTimeout(function(){el.style.display='none'},4500)}
function playAlert(){
  if(!sndOn)return;
  try{var ac=new(window.AudioContext||window.webkitAudioContext)();
    [880,1100,1320].forEach(function(f,i){
      var o=ac.createOscillator(),g=ac.createGain();o.connect(g);g.connect(ac.destination);
      o.frequency.value=f;o.type='sine';
      g.gain.setValueAtTime(.3,ac.currentTime+i*.15);g.gain.exponentialRampToValueAtTime(.001,ac.currentTime+i*.15+.3);
      o.start(ac.currentTime+i*.15);o.stop(ac.currentTime+i*.15+.3);
    })
  }catch(e){}
}

document.getElementById('bstart').onclick=function(){
  if(!botOn){
    var lic=document.getElementById('ilic').value.trim(),mt5=document.getElementById('imt5').value.trim();
    if(!lic||!mt5){showToast('Introduce licencia y cuenta MT5');return}
    botOn=true;setStatus('waiting');this.textContent='Detener';this.className='pb pr';
    updateHUD();
    loopId=setInterval(updateHUD,5000);
    tickId=setInterval(function(){
      var l=candles[candles.length-1],mv=(Math.random()-.499)*80;
      l.c=+(l.c+mv).toFixed(2);l.h=Math.max(l.h,l.c);l.l=Math.min(l.l,l.c);
      if(botOn)document.getElementById('hprice').textContent=fmt(l.c);
      drawAll();
    },1500);
  }else{
    botOn=false;clearInterval(loopId);clearInterval(tickId);
    setStatus('off');this.textContent='Iniciar';this.className='pb pg';
    document.getElementById('nwarn').style.display='none';drawAll();
  }
};
document.getElementById('bpwr').onclick=function(){document.getElementById('bstart').click()};
document.getElementById('bmin').onclick=function(){
  minimized=!minimized;document.getElementById('hbody').classList.toggle('mini',minimized);
  this.textContent=minimized?'+':'−';
};
document.getElementById('bsnd').onclick=function(){
  sndOn=!sndOn;this.textContent=sndOn?'&#128276;':'&#128277;';this.style.background=sndOn?'#3fb950':'#555';
};
document.getElementById('bact').onclick=function(){
  var lic=document.getElementById('ilic').value.trim(),mt5=document.getElementById('imt5').value.trim();
  if(lic.length<6){showToast('Licencia invalida');return}
  if(!/^\d+$/.test(mt5)){showToast('Cuenta MT5 invalida (solo numeros)');return}
  this.textContent='Licencia Activa';this.className='bfull pg';
  showToast('Licencia activada — cuenta MT5: '+mt5);
};
document.getElementById('bclose').onclick=function(){
  setStatus('waiting');
  document.getElementById('tinfo').innerHTML='<div style="font-size:11px;color:rgba(255,255,255,.3)">Sin operacion abierta</div>';
  this.style.display='none';showToast('Operacion cerrada manualmente');
};
function applyP(){
  P.risk=+document.getElementById('prisk').value||1;P.atrM=+document.getElementById('patr').value||1.5;
  P.rr=+document.getElementById('prr').value||2;P.swing=+document.getElementById('pswing').value||50;
  P.rsib=+document.getElementById('prsib').value||65;P.rsis=+document.getElementById('prsis').value||35;
  P.emaf=+document.getElementById('pemaf').value||21;P.emas=+document.getElementById('pemas').value||55;
  P.emat=+document.getElementById('pemat').value||200;
  document.getElementById('ci-sw').textContent=P.swing;
  showToast('Parametros aplicados');if(botOn)updateHUD();else drawAll();
}
function resetP(){
  var ids=['prisk','patr','prr','pswing','prsib','prsis','pemaf','pemas','pemat'];
  var vals=[1,1.5,2,50,65,35,21,55,200];
  ids.forEach(function(id,i){document.getElementById(id).value=vals[i]});applyP();
}
function togNews(){
  newsOn=!newsOn;var b=document.getElementById('bntog');
  b.textContent=newsOn?'Activo':'Inactivo';b.className=newsOn?'pb py':'pb pr';
}

var hud=document.getElementById('hud'),dx=0,dy=0,drag=false;
hud.addEventListener('mousedown',function(e){if(['INPUT','BUTTON','SELECT'].includes(e.target.tagName))return;drag=true;var r=hud.getBoundingClientRect();dx=e.clientX-r.left;dy=e.clientY-r.top});
document.addEventListener('mousemove',function(e){if(!drag)return;hud.style.right='auto';hud.style.left=(e.clientX-dx)+'px';hud.style.top=(e.clientY-dy)+'px'});
document.addEventListener('mouseup',function(){drag=false});

renderNews();drawAll();
</script>
</body>
</html>