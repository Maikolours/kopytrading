import os, subprocess, shutil

code = '''double CalcularGanadoHoy() { 
    double total = 0;

    if(!HistorySelect(0, TimeCurrent() + 86400)) return 0; 
    int totalDeals = HistoryDealsTotal();

    MqlDateTime currStruct;
    TimeToStruct(TimeTradeServer(), currStruct);

    string currentSym = _Symbol;
    StringToUpper(currentSym);
    
    ulong posIds[];
    ArrayResize(posIds, 0);

    for(int i = 0; i < totalDeals; i++) {
        ulong t = HistoryDealGetTicket(i);
        if(t <= 0) continue;

        datetime dealTime = (datetime)HistoryDealGetInteger(t, DEAL_TIME);
        MqlDateTime dealStruct;
        TimeToStruct(dealTime, dealStruct);

        if(dealStruct.year != currStruct.year || dealStruct.mon != currStruct.mon || dealStruct.day != currStruct.day) continue;

        long entryType = HistoryDealGetInteger(t, DEAL_ENTRY);
        if(entryType != DEAL_ENTRY_OUT && entryType != DEAL_ENTRY_INOUT) continue;

        string dealSym = HistoryDealGetString(t, DEAL_SYMBOL);
        StringToUpper(dealSym);

        if(dealSym != currentSym && StringFind(currentSym, dealSym) < 0 && StringFind(dealSym, currentSym) < 0) continue;

        long magic = HistoryDealGetInteger(t, DEAL_MAGIC);
        double prof = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP);
        
        string comment = HistoryDealGetString(t, DEAL_COMMENT);
        bool isV1132 = (magic == ExpertMagic || magic == 888888 || StringFind(comment, "11.32") >= 0 || StringFind(comment, "SHIELD") >= 0);
        
        if(isV1132) {
            total += prof;
        } else if (magic == 0) {
            long posId = HistoryDealGetInteger(t, DEAL_POSITION_ID);
            if(posId > 0) {
                int size = ArraySize(posIds);
                ArrayResize(posIds, size + 1);
                posIds[size] = posId;
                total += prof;
            }
        }
    }
    
    for(int i = 0; i < ArraySize(posIds); i++) {
        long pId = posIds[i];
        if(HistorySelectByPosition(pId)) {
            int posDeals = HistoryDealsTotal();
            bool wasOurs = false;
            for(int j = 0; j < posDeals; j++) {
                ulong t_in = HistoryDealGetTicket(j);
                if(HistoryDealGetInteger(t_in, DEAL_ENTRY) == DEAL_ENTRY_IN) {
                    long in_magic = HistoryDealGetInteger(t_in, DEAL_MAGIC);
                    string in_comment = HistoryDealGetString(t_in, DEAL_COMMENT);
                    if(in_magic == ExpertMagic || in_magic == 888888 || StringFind(in_comment, "11.32") >= 0 || StringFind(in_comment, "SHIELD") >= 0) {
                        wasOurs = true;
                    }
                    break;
                }
            }
            if(!wasOurs) {
                for(int j = 0; j < posDeals; j++) {
                    ulong t_out = HistoryDealGetTicket(j);
                    if(HistoryDealGetInteger(t_out, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(t_out, DEAL_ENTRY) == DEAL_ENTRY_INOUT) {
                        double p = HistoryDealGetDouble(t_out, DEAL_PROFIT) + HistoryDealGetDouble(t_out, DEAL_COMMISSION) + HistoryDealGetDouble(t_out, DEAL_SWAP);
                        total -= p;
                    }
                }
            }
        }
    }
    HistorySelect(0, TimeCurrent() + 86400);
    return NormalizeDouble(total, 2); 
}'''

def update_file(path):
    with open(path, 'r', encoding='utf-8') as f: orig = f.read()
    start_idx = orig.find('double CalcularGanadoHoy()')
    end_idx = orig.find('}', orig.find('return NormalizeDouble(total, 2);', start_idx)) + 1
    with open(path, 'w', encoding='utf-8') as f:
        f.write(orig[:start_idx] + code.strip() + orig[end_idx:])

demo_mq5 = r'C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO.mq5'
real_mq5 = r'C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_REAL.mq5'
v1133_js = r'C:\proyectos\APP KOPYTRADING\scratch\build_v1133_demo.js'

update_file(demo_mq5)
update_file(real_mq5)
update_file(v1133_js)

editor = r'C:\Program Files\MetaTrader 5\metaeditor64.exe'
subprocess.run([editor, f'/compile:{demo_mq5}'], capture_output=True)
subprocess.run([editor, f'/compile:{real_mq5}'], capture_output=True)

term_dir = r'C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE'
shutil.copy2(demo_mq5, os.path.join(term_dir, 'MAIKO_PRO_GOLD_DEMO.mq5'))
shutil.copy2(demo_mq5.replace('.mq5', '.ex5'), os.path.join(term_dir, 'MAIKO_PRO_GOLD_DEMO.ex5'))
shutil.copy2(real_mq5, os.path.join(term_dir, 'MAIKO_PRO_GOLD_REAL.mq5'))
shutil.copy2(real_mq5.replace('.mq5', '.ex5'), os.path.join(term_dir, 'MAIKO_PRO_GOLD_REAL.ex5'))

print('DONE!')
