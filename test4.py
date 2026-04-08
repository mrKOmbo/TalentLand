import requests
import os
import time
from lxml import etree
# --- TU CONFIGURACIÓN ---
COOKIE = "_gcl_au=1.1.161863697.1774898634; cebs=1; lastLoginMethod=guidewire-partner; _gid=GA1.2.768495290.1775068744; _ga=GA1.1.1875015102.1774898627; _ce.clock_data=36%2C3.213.4.172%2C1%2C2204ee63bef2f351470a66ffe1bb020e%2CChrome%2CUS; cebsp_=2; _ga_LN5WM89V7V=GS2.1.s1775068744$o2$g1$t1775068773$j31$l0$h0; _ce.s=v~a6494c440ba69ee783765cf22889add109cf6d80~lcw~1775068771308~vir~returning~lva~1775068745120~vpv~0~as~false~v11ls~0fa10200-2dfa-11f1-8b41-39d26bdb4e6f~v11.cs~450517~v11.s~0fa10200-2dfa-11f1-8b41-39d26bdb4e6f~v11.vs~a6494c440ba69ee783765cf22889add109cf6d80~v11.fsvd~eyJub3RNb2RpZmllZFVybCI6Imh0dHBzOi8vcGFydG5lci5ndWlkZXdpcmUuY29tL3MvbG9naW4vP2VjPTMwMiZpbnN0PVBXJnN0YXJ0VVJMPSUyRmlkcCUyRmxvZ2luJTNGYXBwJTNEMHNwMlQwMDAwMDBQQjV1JTI2YmluZGluZyUzREh0dHBQb3N0JTI2aW5yZXNwb25zZXRvJTNEXzZiNzVlN2ViNzQ2MzExMGQwN2NjY2JlNTZhNThiYzliY2VlYjE3N2UiLCJ1cmwiOiJwYXJ0bmVyLmd1aWRld2lyZS5jb20vcy9sb2dpbiIsInJlZiI6Imh0dHBzOi8vcGFydG5lci5ndWlkZXdpcmUuY29tL2lkcC9sb2dpbj9hcHA9MHNwMlQwMDAwMDBQQjV1JmJpbmRpbmc9SHR0cFBvc3QmaW5yZXNwb25zZXRvPV82Yjc1ZTdlYjc0NjMxMTBkMDdjY2NiZTU2YTU4YmM5YmNlZWIxNzdlIiwidXRtIjpbXX0%3D~v11.sla~1775068745250~v11.wss~1775068745251~v11.ss~1775068745253~gtrk.la~mnge47ih~lcw~1775068773641; _ga_R7KBE1WJ4D=GS2.1.s1775068744$o2$g1$t1775068774$j30$l0$h0; session=eyJwYXNzcG9ydCI6eyJ1c2VyIjp7Imlzc3VlciI6Imh0dHBzOi8vcGFydG5lci5ndWlkZXdpcmUuY29tIiwiaW5SZXNwb25zZVRvIjoiXzZiNzVlN2ViNzQ2MzExMGQwN2NjY2JlNTZhNThiYzliY2VlYjE3N2UiLCJuYW1lSUQiOiIwMEQzMDAwMDAwMDBGSGlAZW1pbGlvLmNydXpAcHdjLmNvbSIsIm5hbWVJREZvcm1hdCI6InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjEuMTpuYW1laWQtZm9ybWF0OnVuc3BlY2lmaWVkIiwidXNlcklkIjoiMDA1UFcwMDAwMFVxOFExIiwidXNlcm5hbWUiOiJlbWlsaW8uY3J1ekBwd2MuY29tIiwiZW1haWwiOiJlbWlsaW8uY3J1ekBwd2MuY29tIiwiaXNfcG9ydGFsX3VzZXIiOiJ0cnVlIiwiYXR0cmlidXRlcyI6eyJ1c2VySWQiOiIwMDVQVzAwMDAwVXE4UTEiLCJ1c2VybmFtZSI6ImVtaWxpby5jcnV6QHB3Yy5jb20iLCJlbWFpbCI6ImVtaWxpby5jcnV6QHB3Yy5jb20iLCJpc19wb3J0YWxfdXNlciI6InRydWUifSwiaXNBZG1pbiI6ZmFsc2UsImlzUG93ZXJVc2VyIjpmYWxzZSwiaXNDaGF0Ym90VGVzdGVyIjpmYWxzZX19fQ==; session.sig=GVvKe1UBOHyreKxaflmCfYz7_2M; _ga_QRTVTBY678=GS2.1.s1775072707$o6$g1$t1775072802$j59$l0$h0"
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
SITEMAP_INDEX = "https://docs.guidewire.com/sitemap.xml"
# Filtro para enfocarnos solo en lo que te sirve para Capital One
KEYWORDS = ["palisades", "integration"]
HEADERS = {"User-Agent": USER_AGENT, "Cookie": COOKIE}
def super_scraper():
   escritorio = os.path.join(os.path.expanduser("~"), "Desktop", "BIBLIOTECA_GUIDEWIRE")
   if not os.path.exists(escritorio): os.makedirs(escritorio)
   session = requests.Session()
   session.headers.update(HEADERS)
   print("🛰️  Accediendo al índice maestro...")
   r = session.get(SITEMAP_INDEX)
   root = etree.fromstring(r.content)
   # Extraer todos los sitemaps secundarios
   sitemaps = [loc.text for loc in root.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc")]
   # TRUCO DE INGENIERÍA: Empezar por los últimos sitemaps (los más nuevos)
   sitemaps.reverse()
   print(f"✅ {len(sitemaps)} sitemaps detectados. Iniciando cosecha...")
   for s_url in sitemaps:
       print(f"🔍 Escaneando: {s_url.split('/')[-1]}", end="\r")
       try:
           res = session.get(s_url, timeout=10)
           child_root = etree.fromstring(res.content)
           urls = [loc.text for loc in child_root.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc")]
           for url in urls:
               # Si la página web es de Palisades y de Integración...
               if "palisades" in url.lower() and "integration" in url.lower():
                   # Intentamos deducir el nombre del libro desde la URL
                   # Ejemplo: .../integration-gateway-books/ig-framework/... -> IntegrationGatewayFramework.pdf
                   book_name = url.split('/')[-3] # Suele ser el nombre del manual
                   # Limpiamos el nombre para que sea un PDF válido
                   pdf_name = book_name.replace("-", "").title() + ".pdf"
                   # Construimos la URL de descarga que ya sabemos que funciona
                   pdf_download_url = f"https://docs.guidewire.com/cloudProducts/palisades/integration/pdf/{pdf_name}"
                   path_destino = os.path.join(escritorio, pdf_name)
                   if not os.path.exists(path_destino):
                       print(f"\n✨ Posible manual encontrado: {pdf_name}")
                       r_pdf = session.get(pdf_download_url, stream=True)
                       if r_pdf.status_code == 200:
                           with open(path_destino, 'wb') as f:
                               for chunk in r_pdf.iter_content(chunk_size=8192):
                                   f.write(chunk)
                           # Si pesa poco, es un error 404 disfrazado, lo borramos
                           if os.path.getsize(path_destino) < 5000:
                               os.remove(path_destino)
                               print("   ❌ No era un PDF real.")
                           else:
                               print(f"   📥 ¡DESCARGADO! ({os.path.getsize(path_destino)//1024} KB)")
                       time.sleep(0.5)
       except:
           continue
if __name__ == "__main__":
   super_scraper()
