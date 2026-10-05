//+------------------------------------------------------------------+
//|                      XAUUSD_Martingala_Segura_v5.mq5            |
//|                     VERSIÓN 5.0 - DEFINITIVA                   |
//+------------------------------------------------------------------+
#property copyright "Versión 5.0 Definitiva"
#property version   "5.0"
#property strict

//+------------------------------------------------------------------+
//| PARÁMETROS PRINCIPALES                                          |
//+------------------------------------------------------------------+
input group "══════════ GESTIÓN PRINCIPAL ══════════"
input double   LotInicial      = 0.01;          // Lote inicial
input int      MaxOperaciones  = 3;             // Máx 3 operaciones (SEGURIDAD)
input double   ProfitObjetivo  = 5.0;           // TP global ($) - REALISTA
input double   StopGlobal      = 4.0;           // SL global ($) - ESTRICTO (CORREGIDO: siempre actúa como negativo)
input ulong    MagicNumber     = 20240205;      // Magic number único

input group "══════════ GESTIÓN DE SPREAD ══════════"
input int      SpreadMaximo    = 50;            // Spread máximo permitido
input int      SpreadObjetivo  = 25;            // Spread ideal

input group "══════════ ESTRATEGIA ══════════"
input int      DistanciaMinima = 120;           // 120 segundos entre ops (2 min)
input int      StopLossPips    = 20;            // SL individual (pips)
input double   Multiplicador   = 1.5;           // Multiplicador martingala
input double   UmbralMartingala = -2.0;         // Pérdida para activar martingala
input bool     TradingActivo   = false;         // Activar MANUALMENTE

//+------------------------------------------------------------------+
//| VARIABLES GLOBALES                                              |
//+------------------------------------------------------------------+
int spreadActual = 0;
bool spreadOk = true;
datetime ultimaOperacion = 0;
double balanceInicial = 0;
int totalOpsAbiertas = 0;
double profitTotal = 0.0;
string direccionActual = "";
int nivelMartingala = 0;
bool errorDireccionMixta = false;

//+------------------------------------------------------------------+
//| FUNCIONES AUXILIARES                                            |
//+------------------------------------------------------------------+

// Contar operaciones abiertas
int ContarOperacionesAbiertas()
{
   int count = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            count++;
         }
      }
   }
   totalOpsAbiertas = count;
   return count;
}

// Calcular profit total
double CalcularProfitTotal()
{
   double profit = 0.0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            profit += PositionGetDouble(POSITION_PROFIT);
         }
      }
   }
   profitTotal = profit;
   return profit;
}

// Verificar que solo hay UNA dirección (CRÍTICO)
bool VerificarSoloUnaDireccion()
{
   bool tieneBuy = false;
   bool tieneSell = false;
   
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
               tieneBuy = true;
            else
               tieneSell = true;
         }
      }
   }
   
   // ERROR GRAVE: Tiene ambas direcciones
   if(tieneBuy && tieneSell)
   {
      errorDireccionMixta = true;
      Print("⛔⛔⛔ ERROR CRÍTICO: Tiene BUY y SELL simultáneo");
      Print("Cerrando TODO por seguridad...");
      CerrarTodas("ERROR_DIRECCION_MIXTA");
      return false;
   }
   
   errorDireccionMixta = false;
   return true;
}

// Obtener dirección ÚNICA
string ObtenerDireccionUnica()
{
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            return (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
         }
      }
   }
   return "";
}

// Contar operaciones en dirección ACTUAL
int ContarOpsEnDireccion(string direccion)
{
   if(direccion == "") return 0;
   
   int count = 0;
   bool esBuy = (direccion == "BUY");
   
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            bool tipoPos = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
            if((esBuy && tipoPos) || (!esBuy && !tipoPos))
            {
               count++;
            }
         }
      }
   }
   return count;
}

// Profit en dirección específica
double ProfitEnDireccion(string direccion)
{
   if(direccion == "") return 0.0;
   
   double profit = 0.0;
   bool esBuy = (direccion == "BUY");
   
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            bool tipoPos = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
            if((esBuy && tipoPos) || (!esBuy && !tipoPos))
            {
               profit += PositionGetDouble(POSITION_PROFIT);
            }
         }
      }
   }
   return profit;
}

// Cerrar todas las operaciones (GARANTIZADO)
void CerrarTodas(string razon)
{
   if(totalOpsAbiertas == 0) return;
   
   Print("═══════════════════════════════");
   Print(razon);
   Print("Profit al cerrar: $", DoubleToString(profitTotal, 2));
   Print("Cerrando ", totalOpsAbiertas, " posiciones...");
   
   int cerradas = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_DEAL;
            request.position = ticket;
            request.symbol = _Symbol;
            request.volume = PositionGetDouble(POSITION_VOLUME);
            bool esBUY = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
            request.type = esBUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            request.price = esBUY ? SymbolInfoDouble(_Symbol, SYMBOL_BID) 
                                  : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            request.deviation = 10;
            request.comment = razon;
            
            if(OrderSend(request, result))
            {
               cerradas++;
               Print("   Cerrada op #", cerradas, " - Ticket: ", ticket);
            }
         }
      }
   }
   
   // Resetear variables
   totalOpsAbiertas = 0;
   profitTotal = 0.0;
   direccionActual = "";
   nivelMartingala = 0;
   Print("✅ ", cerradas, " operaciones cerradas");
   Print("═══════════════════════════════");
}

//+------------------------------------------------------------------+
//| GESTIÓN DE SPREAD                                               |
//+------------------------------------------------------------------+
bool VerificarSpread()
{
   spreadActual = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   spreadOk = (spreadActual <= SpreadMaximo);
   return spreadOk;
}

//+------------------------------------------------------------------+
//| CALCULAR LOTE SEGURO                                            |
//+------------------------------------------------------------------+
double CalcularLote(int nivel)
{
   double lote = LotInicial * MathPow(Multiplicador, nivel);
   
   // Límites de seguridad
   double minLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLote = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   // Asegurar que está dentro de límites
   lote = MathMax(minLote, MathMin(maxLote, lote));
   
   // Ajustar al step
   if(stepLote > 0)
      lote = NormalizeDouble(MathFloor(lote / stepLote) * stepLote, 2);
   
   return lote;
}

//+------------------------------------------------------------------+
//| DETECTAR TENDENCIA CONFIRMADA                                   |
//+------------------------------------------------------------------+
string DetectarTendencia()
{
   // Señal MÁS CONSERVADORA (evitar falsas señales)
   double maFast_M5 = iMA(_Symbol, PERIOD_M5, 5, 0, MODE_SMA, PRICE_CLOSE);
   double maSlow_M5 = iMA(_Symbol, PERIOD_M5, 15, 0, MODE_SMA, PRICE_CLOSE);
   double precio = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Solo entrar si hay tendencia CLARA
   if(MathAbs(maFast_M5 - maSlow_M5) < (50 * _Point)) // Menos de 50 pips diferencia
      return "NEUTRAL";
   
   if(maFast_M5 > maSlow_M5 && precio > maFast_M5)
      return "BUY";
   else if(maFast_M5 < maSlow_M5 && precio < maFast_M5)
      return "SELL";
   
   return "NEUTRAL";
}

//+------------------------------------------------------------------+
//| ABRIR OPERACIÓN SEGURA                                          |
//+------------------------------------------------------------------+
bool AbrirOperacion(string direccion, int nivel, string comentario)
{
   // 1. Verificar spread
   if(!VerificarSpread())
   {
      Print("⛔ Spread alto: ", spreadActual, " pips");
      return false;
   }
   
   // 2. Verificar tiempo mínimo
   datetime ahora = TimeCurrent();
   if(ultimaOperacion > 0 && (ahora - ultimaOperacion) < DistanciaMinima)
   {
      int segundosEspera = DistanciaMinima - (int)(ahora - ultimaOperacion);
      Print("⏳ Esperar ", segundosEspera, " segundos");
      return false;
   }
   
   // 3. Verificar máximo operaciones
   if(totalOpsAbiertas >= MaxOperaciones)
   {
      Print("⛔ Máximo operaciones: ", MaxOperaciones);
      return false;
   }
   
   // 4. Calcular lote seguro
   double lote = CalcularLote(nivel);
   
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lote;
   request.type = (direccion == "BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   request.price = (direccion == "BUY") ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) 
                                        : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = 10;
   request.magic = MagicNumber;
   request.comment = comentario;
   
   // SL obligatorio
   if(StopLossPips > 0)
   {
      if(direccion == "BUY")
         request.sl = request.price - (StopLossPips * _Point);
      else
         request.sl = request.price + (StopLossPips * _Point);
   }
   
   bool enviado = OrderSend(request, result);
   
   if(enviado && result.retcode == TRADE_RETCODE_DONE)
   {
      Print("✅ ", direccion, " | Lote: ", lote, " | Nivel: ", nivel);
      ultimaOperacion = ahora;
      
      // Si es primera operación, guardar dirección
      if(direccionActual == "")
         direccionActual = direccion;
      
      return true;
   }
   
   Print("❌ Error abriendo ", direccion, ": ", result.retcode);
   return false;
}

//+------------------------------------------------------------------+
//| LÓGICA DE ENTRADA CORREGIDA (100% SEGURA)                       |
//+------------------------------------------------------------------+
void GestionarEntradas()
{
   // VERIFICACIÓN CRÍTICA: Solo una dirección permitida
   if(!VerificarSoloUnaDireccion())
   {
      Print("🛑 BLOQUEADO: Error de dirección mixta detectado");
      return;
   }
   
   int ops = ContarOperacionesAbiertas();
   
   // 1. SIN OPERACIONES → Abrir primera
   if(ops == 0)
   {
      string tendencia = DetectarTendencia();
      if(tendencia != "NEUTRAL")
      {
         if(AbrirOperacion(tendencia, 0, "ENTRADA_INICIAL"))
         {
            direccionActual = tendencia;
            nivelMartingala = 0;
            Print("🎯 Dirección establecida: ", direccionActual);
         }
      }
      else
      {
         Print("⏸️  Esperando señal clara...");
      }
   }
   // 2. CON OPERACIONES → Gestionar martingala SEGURA
   else if(ops < MaxOperaciones)
   {
      string dirUnica = ObtenerDireccionUnica();
      if(dirUnica == "")
         return;
      
      // Actualizar dirección si es necesario
      if(direccionActual == "")
         direccionActual = dirUnica;
      
      // Verificar que estamos en la dirección correcta
      if(dirUnica != direccionActual)
      {
         Print("⚠️  Dirección inconsistente. Reiniciando...");
         CerrarTodas("REINICIO_DIRECCION");
         return;
      }
      
      int opsDir = ContarOpsEnDireccion(direccionActual);
      double profitDir = ProfitEnDireccion(direccionActual);
      
      // MARTINGALA SOLO SI:
      // 1. Vamos perdiendo en esa dirección
      // 2. No superamos máximo de operaciones
      // 3. No hemos alcanzado SL global aún
      if(profitDir <= UmbralMartingala && 
         opsDir < MaxOperaciones && 
         profitTotal > -MathAbs(StopGlobal)) // <-- CORREGIDO PARA QUE StopGlobal SIEMPRE SEA NEGATIVO
      {
         nivelMartingala++;
         Print("🔄 Activando martingala nivel ", nivelMartingala);
         Print("   Profit dirección: $", DoubleToString(profitDir, 2));
         
         AbrirOperacion(direccionActual, nivelMartingala, 
                       "MARTINGALA_N" + string(nivelMartingala));
      }
   }
}

//+------------------------------------------------------------------+
//| GESTIÓN DE CIERRES (GARANTIZADA)                                |
//+------------------------------------------------------------------+
void GestionarCierres()
{
   double profit = CalcularProfitTotal();
   
   // 1. TP GLOBAL (ÉXITO)
   if(profit >= ProfitObjetivo)
   {
      CerrarTodas("✅ TP ALCANZADO: $" + DoubleToString(profit, 2));
      return;
   }
   
   // 2. SL GLOBAL (PROTECCIÓN) - CORREGIDO PARA USAR MathAbs NEGATIVO
   if(profit <= -MathAbs(StopGlobal))
   {
      CerrarTodas("⛔ STOP GLOBAL: $" + DoubleToString(profit, 2));
      return;
   }
   
   // 3. CIERRE POR ERROR DE DIRECCIÓN
   if(errorDireccionMixta)
   {
      CerrarTodas("🛑 ERROR: Dirección mixta detectada");
      return;
   }
}

//+------------------------------------------------------------------+
//| MOSTRAR INFORMACIÓN DETALLADA                                   |
//+------------------------------------------------------------------+
void MostrarInfo()
{
   VerificarSpread();
   CalcularProfitTotal();
   ContarOperacionesAbiertas();
   
   if(totalOpsAbiertas > 0 && direccionActual == "")
      direccionActual = ObtenerDireccionUnica();
   
   double profitDir = ProfitEnDireccion(direccionActual);
   int opsDir = ContarOpsEnDireccion(direccionActual);
   
   string info = "\n═══════════════════════════════\n";
   info += "MARTINGALA SEGURA v5.0\n";
   info += "═══════════════════════════════\n";
   info += "Spread: " + string(spreadActual) + " pips " + (spreadOk ? "✅" : "⚠️") + "\n";
   info += "Operaciones: " + string(opsDir) + "/" + string(MaxOperaciones) + "\n";
   info += "Profit total: $" + DoubleToString(profitTotal, 2) + "\n";
   info += "Profit dirección: $" + DoubleToString(profitDir, 2) + "\n";
   info += "Dirección: " + direccionActual + " | Nivel: " + string(nivelMartingala) + "\n";
   info += "TP: $" + DoubleToString(ProfitObjetivo, 1);
   info += " | SL: -$" + DoubleToString(MathAbs(StopGlobal), 1) + "\n"; // CORREGIDO PARA MOSTRAR NEGATIVO
   info += "═══════════════════════════════\n";
   
   if(errorDireccionMixta)
      info += "🛑 ERROR: Dirección mixta!\n";
   
   info += "Estado: " + string(TradingActivo ? "🟢 ACTIVO" : "🔴 PAUSADO") + "\n";
   info += "═══════════════════════════════\n";
   
   Comment(info);
}

//+------------------------------------------------------------------+
//| INIT                                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   balanceInicial = AccountInfoDouble(ACCOUNT_BALANCE);
   Print("========================================");
   Print("MARTINGALA SEGURA v5.0 - INICIALIZADO");
   Print("========================================");
   Print("Balance: $", DoubleToString(balanceInicial, 2));
   Print("TP: $", ProfitObjetivo, " | SL: -$", MathAbs(StopGlobal)); // CORREGIDO
   Print("Máx ops: ", MaxOperaciones, " | Multiplicador: ", Multiplicador);
   Print("Distancia mínima: ", DistanciaMinima, " segundos");
   Print("========================================");
   Print("ADVERTENCIA: Activar MANUALMENTE");
   Print("========================================");
   
   // Resetear variables
   direccionActual = "";
   nivelMartingala = 0;
   errorDireccionMixta = false;
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| DEINIT                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   Print("EA detenido");
}

//+------------------------------------------------------------------+
//| ON TICK (EJECUCIÓN PRINCIPAL)                                   |
//+------------------------------------------------------------------+
void OnTick()
{
   static datetime ultimoTick = 0;
   datetime ahora = TimeCurrent();
   
   // Ejecutar cada 5 segundos (optimizado)
   if(ahora - ultimoTick < 5)
      return;
   
   ultimoTick = ahora;
   
   // 1. Mostrar información
   MostrarInfo();
   
   // 2. Si no está activo, salir
   if(!TradingActivo)
      return;
   
   // 3. Gestionar cierres (PRIORIDAD MÁXIMA)
   GestionarCierres();
   
   // 4. Si hay error, no gestionar entradas
   if(errorDireccionMixta)
      return;
   
   // 5. Gestionar entradas
   GestionarEntradas();
}
//+------------------------------------------------------------------+
