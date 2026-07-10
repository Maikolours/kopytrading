def make_bold(text):
    bold_map = str.maketrans(
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
        '𝗔𝗕𝗖𝗗𝗘𝗙𝗚𝗛𝗜𝗝𝗞𝗟𝗠𝗡𝗢𝗣𝗤𝗥𝗦𝗧𝗨𝗩𝗪𝗫𝗬𝗭𝗮𝗯𝗰𝗱𝗲𝗳𝗴𝗵𝗶𝗷𝗸𝗹𝗺𝗻𝗼𝗽𝗾𝗿𝘀𝘁𝘂𝘃𝘄𝘅𝘆𝘇𝟬𝟭𝟮𝟯𝟰𝟱𝟲𝟳𝟴𝟵'
    )
    return text.translate(bold_map)

post = f'''
{make_bold('FLOTANTE NEGATIVO: ¿AGUANTAR O CORTAR RÁPIDO?')} ⏱️📉

Hoy os traigo un vídeo súper interesante sobre la realidad del Copy Trading y la {make_bold('importancia vital de tomar decisiones')}. 

Ayer se nos quedaron dos operaciones abiertas en el sistema y he querido hacer un pequeño experimento en dos cuentas demo distintas para que veáis la diferencia:

👉 {make_bold('CUENTA 1:')} He cerrado las operaciones manualmente hoy.
👉 {make_bold('CUENTA 2:')} Las he dejado correr para ver cuánto aguanta la cuenta el flotante.

{make_bold('¿EL RESULTADO?')} 📊
Ayer llegamos a tener casi {make_bold('+30 USD')} de beneficio, pero al no tomar la decisión de cerrar a tiempo (ya sea manualmente o con un stop loss dinámico), hoy he tenido que asumir una pérdida de {make_bold('-30 USD')} en la cuenta donde cerré manualmente. A pesar de este retroceso, ¡nuestro profit global desde el día 6 sigue siendo de aproximadamente {make_bold('+120 dólares')}! 💸🔥

{make_bold('LA GRAN LECCIÓN DE HOY:')} 🧠
La diferencia entre cerrar o no cerrar una operación te puede llevar a quedarte con un flotante negativo muy elevado. Todo depende de tu cuenta y tu psicología:

✅ ¿Tienes un {make_bold('balance lo suficientemente grande')} capaz de aguantar la caída o subida sin problemas hasta que el mercado se recupere?
✅ ¿O prefieres tomar la decisión conservadora: {make_bold('ganar poquito hoy')}, salir en break even o incluso asumir una pequeña pérdida a tiempo para evitar quedarte atrapado un día entero esperando a que se recupere?

Cada trader es un mundo y cada uno debe sopesar su riesgo. A veces, {make_bold('cortar una pequeña pérdida hoy es tu mayor ganancia mañana.')} 💼🛡️

{make_bold('¿TÚ QUÉ EQUIPO ERES?')} ¿De los que aguantan el flotante pase lo que pase o de los que cortan rápido? ¡Te leo en los comentarios! 👇

🔗 Descubre nuestros algoritmos y herramientas institucionales en www.kopytrading.com

⚠️ {make_bold('Descargo de responsabilidad:')}
El trading en mercados financieros conlleva un alto nivel de riesgo y puede no ser adecuado para todos los inversores. El rendimiento pasado no garantiza resultados futuros. La información de esta publicación es puramente educativa y no constituye asesoramiento financiero. Invierte solo capital que estés dispuesto a perder.

#KopyTrading #TradingAutomatizado #Forex #GestionDeRiesgo #Psicotrading #ExpertAdvisor #Inversiones #TradingReal #ResultadosTrading #FlotanteNegativo #StopLoss
'''

with open('scratch/post_bold.txt', 'w', encoding='utf-8') as f:
    f.write(post)
