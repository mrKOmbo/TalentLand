import requests
import os
import sys
# --- TERMINAL COLORS ---
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
BOLD = "\033[1m"
RESET = "\033[0m"
# --- SESSION DATA (RENEW COOKIE IF EXPIRED) ---
# Note: Keep this private as it contains your PwC/Guidewire session info
SESSION_COOKIE = "_gcl_au=1.1.161863697.1774898634; cebs=1; lastLoginMethod=guidewire-partner; _gid=GA1.2.768495290.1775068744; _ga=GA1.1.1875015102.1774898627; _ce.clock_data=36%2C3.213.4.172%2C1%2C2204ee63bef2f351470a66ffe1bb020e%2CChrome%2CUS; cebsp_=2; _ga_LN5WM89V7V=GS2.1.s1775068744$o2$g1$t1775068773$j31$l0$h0; _ce.s=v~a6494c440ba69ee783765cf22889add109cf6d80~lcw~1775068771308~vir~returning~lva~1775068745120~vpv~0~as~false~v11ls~0fa10200-2dfa-11f1-8b41-39d26bdb4e6f~v11.cs~450517~v11.s~0fa10200-2dfa-11f1-8b41-39d26bdb4e6f~v11.vs~a6494c440ba69ee783765cf22889add109cf6d80~v11.fsvd~eyJub3RNb2RpZmllZFVybCI6Imh0dHBzOi8vcGFydG5lci5ndWlkZXdpcmUuY29tL3MvbG9naW4vP2VjPTMwMiZpbnN0PVBXJnN0YXJ0VVJMPSUyRmlkcCUyRmxvZ2luJTNGYXBwJTNEMHNwMlQwMDAwMDBQQjV1JTI2YmluZGluZyUzREh0dHBQb3N0JTI2aW5yZXNwb25zZXRvJTNEXzZiNzVlN2ViNzQ2MzExMGQwN2NjY2JlNTZhNThiYzliY2VlYjE3N2UiLCJ1cmwiOiJwYXJ0bmVyLmd1aWRld2lyZS5jb20vcy9sb2dpbiIsInJlZiI6Imh0dHBzOi8vcGFydG5lci5ndWlkZXdpcmUuY29tL2lkcC9sb2dpbj9hcHA9MHNwMlQwMDAwMDBQQjV1JmJpbmRpbmc9SHR0cFBvc3QmaW5yZXNwb25zZXRvPV82Yjc1ZTdlYjc0NjMxMTBkMDdjY2NiZTU2YTU4YmM5YmNlZWIxNzdlIiwidXRtIjpbXX0%3D~v11.sla~1775068745250~v11.wss~1775068745251~v11.ss~1775068745253~gtrk.la~mnge47ih~lcw~1775068773641; _ga_R7KBE1WJ4D=GS2.1.s1775068744$o2$g1$t1775068774$j30$l0$h0; session=eyJwYXNzcG9ydCI6eyJ1c2VyIjp7Imlzc3VlciI6Imh0dHBzOi8vcGFydG5lci5ndWlkZXdpcmUuY29tIiwiaW5SZXNwb25zZVRvIjoiXzZiNzVlN2ViNzQ2MzExMGQwN2NjY2JlNTZhNThiYzliY2VlYjE3N2UiLCJuYW1lSUQiOiIwMEQzMDAwMDAwMDBGSGlAZW1pbGlvLmNydXpAcHdjLmNvbSIsIm5hbWVJREZvcm1hdCI6InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjEuMTpuYW1laWQtZm9ybWF0OnVuc3BlY2lmaWVkIiwidXNlcklkIjoiMDA1UFcwMDAwMFVxOFExIiwidXNlcm5hbWUiOiJlbWlsaW8uY3J1ekBwd2MuY29tIiwiZW1haWwiOiJlbWlsaW8uY3J1ekBwd2MuY29tIiwiaXNfcG9ydGFsX3VzZXIiOiJ0cnVlIiwiYXR0cmlidXRlcyI6eyJ1c2VySWQiOiIwMDVQVzAwMDAwVXE4UTEiLCJ1c2VybmFtZSI6ImVtaWxpby5jcnV6QHB3Yy5jb20iLCJlbWFpbCI6ImVtaWxpby5jcnV6QHB3Yy5jb20iLCJpc19wb3J0YWxfdXNlciI6InRydWUifSwiaXNBZG1pbiI6ZmFsc2UsImlzUG93ZXJVc2VyIjpmYWxzZSwiaXNDaGF0Ym90VGVzdGVyIjpmYWxzZX19fQ==; session.sig=GVvKe1UBOHyreKxaflmCfYz7_2M; _ga_QRTVTBY678=GS2.1.s1775068742$o5$g1$t1775069029$j58$l0$h0"
USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36"
# Resource URL
TARGET_URL = "https://docs.guidewire.com/is/integgatewayfw/niseko/pdf/IntegrationGatewayFramework.pdf"
HEADERS = {
   "User-Agent": USER_AGENT,
   "Cookie": SESSION_COOKIE,
   "Accept": "application/pdf"
}
def download_manual():
   """Downloads the Guidewire manual and saves it to the Windows Desktop."""
   # 1. Setting up paths
   desktop_path = os.path.join(os.path.expanduser("~"), "Desktop", "Guidewire_Manuals")
   filename = "IntegrationGatewayFramework.pdf"
   full_path = os.path.join(desktop_path, filename)
   # Ensure the directory exists
   if not os.path.exists(desktop_path):
       os.makedirs(desktop_path)
   print(f"\n{BLUE}{BOLD}===> INITIALIZING DOWNLOAD <==={RESET}")
   print(f"{YELLOW}Target:{RESET} {filename}")
   print(f"{YELLOW}Destination:{RESET} {desktop_path}\n")
   try:
       # 2. Starting the request
       print(f"🚀 {BOLD}Connecting to Guidewire servers...{RESET}", end="\r")
       response = requests.get(TARGET_URL, headers=HEADERS, stream=True)
       if response.status_code == 200:
           with open(full_path, 'wb') as f:
               for chunk in response.iter_content(chunk_size=8192):
                   if chunk:
                       f.write(chunk)
           # 3. Validation
           file_size_kb = os.path.getsize(full_path) / 1024
           if file_size_kb > 100:
               print(f"{GREEN}{BOLD}✅ SUCCESS!{RESET} File saved successfully.")
               print(f"{GREEN}Final Size:{RESET} {file_size_kb:.1f} KB")
           else:
               print(f"{RED}{BOLD}⚠️ WARNING:{RESET} File is unusually small ({file_size_kb:.1f} KB).")
               print(f"{YELLOW}Hint:{RESET} Your session cookie might have expired.")
       else:
           print(f"{RED}{BOLD}❌ ERROR {response.status_code}:{RESET} Access Denied or Page Not Found.")
           print(f"{YELLOW}Action:{RESET} Please update your Session Cookie.")
   except Exception as e:
       print(f"\n{RED}{BOLD}❌ CRITICAL ERROR:{RESET} {e}")
   print(f"\n{BLUE}{BOLD}===> PROCESS FINISHED <==={RESET}\n")
if __name__ == "__main__":
   # This ensures colors work on older Windows terminals
   if sys.platform == "win32":
       os.system('color')
   download_manual()
