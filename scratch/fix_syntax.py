import os

file_path = r"C:\proyectos\APP KOPYTRADING\Agosto_2026_Activos\00_OFICIALES_SEPTIEMBRE\MAIKO_PRO_GOLD_DEMO_V11.33.mq5"

with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('"{\\"purchaseId\\":\\"%s\\",\\"account\\":\\"%s\\",\\"balance\\":%.2f,\\"equity\\":%.2f,\\"', r'"{\"purchaseId\":\"%s\",\"account\":\"%s\",\"balance\":%.2f,\"equity\":%.2f,\"')
code = code.replace('""pnl_today":%.2f,"status":"%s","symbol":"%s","narrative":"%s","', r'"\"pnl_today\":%.2f,\"status\":\"%s\",\"symbol\":\"%s\",\"narrative\":\"%s\",\"')
code = code.replace('""armed":%s,"isReal":%s,"version":"11.32","positions":%s,"', r'"\"armed\":%s,\"isReal\":%s,\"version\":\"11.33\",\"positions\":%s,\"')
code = code.replace('""trialExpirado":%s,"diasRestantes":%d}"', r'"\"trialExpirado\":%s,\"diasRestantes\":%d}"')

# Also fix the quotes inside quotes that were causing errors
code = code.replace('StringReplace(narrative, """, "\'");', 'StringReplace(narrative, "\\"", "\\'");')

code = code.replace('"{\\"ticket\\":\\"%I64u\\",\\"type\\":\\"%s\\",\\"symbol\\":\\"%s\\",\\"lots\\":%.2f,\\"openPrice\\":%.5f,\\"tp\\":%.5f,\\"sl\\":%.5f,\\"profit\\":%.2f}"', r'"{\"ticket\":\"%I64u\",\"type\":\"%s\",\"symbol\":\"%s\",\"lots\":%.2f,\"openPrice\":%.5f,\"tp\":%.5f,\"sl\":%.5f,\"profit\":%.2f}"')

code = code.replace('StringFind(response, ""cmd":"CLOSE_ALL"")', r'StringFind(response, "\"cmd\":\"CLOSE_ALL\"")')
code = code.replace('StringFind(response, ""armed":false")', r'StringFind(response, "\"armed\":false")')

code = code.replace('string gvName = "MAIKO_TRIAL_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));', 'string gvName = "MAIKO_TRIAL_V1133_FIX_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));')

with open(file_path, 'w', encoding='utf-8', newline='') as f:
    f.write(code)
