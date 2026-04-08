from __future__ import annotations
import json
import re
import sys
import os
import time
import urllib.parse
from datetime import datetime
from pathlib import Path
from typing import Optional
# --- Optional Dependencies ---
try:
   import requests
   HAS_REQUESTS = True
except ImportError:
   HAS_REQUESTS = False
try:
   from pypdf import PdfReader
   HAS_PYPDF = True
except ImportError:
   HAS_PYPDF = False
try:
   from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout
   HAS_PLAYWRIGHT = True
except ImportError:
   HAS_PLAYWRIGHT = False
 
# ------------------------------------------------------------------------------
# CONFIGURATION — Adjust these variables
# ------------------------------------------------------------------------------
PC_BASE_URL = "http://localhost:8180/pc/rest/apis/"
PC_AUTH     = ("su", "gw")   # (username, password) — None if no auth required
# Change this to your local path or use a relative path
PDF_SOURCE  = Path("./source_pdfs")
# Entry points for the web scraper
GW_DOCS_ENTRY_POINTS = [
   "https://docs.guidewire.com/is/integgatewayfw/olos/Integration/integration-gateway-books/ig-framewor…,
]
GW_DOCS_EMAIL    = ""   # Your Guidewire Portal email (leave empty for manual login)
GW_DOCS_PASSWORD = ""   # Your password
# Output Root
OUT_ROOT = Path("guidewire_docs")
DIRS = {
   "core"    : OUT_ROOT / "01_core_apis",
   "farmers" : OUT_ROOT / "02_farmers_apis",
   "system"  : OUT_ROOT / "03_system_apis",
   "custom"  : OUT_ROOT / "04_custom_apis",
   "pdf"     : OUT_ROOT / "05_pdf_docs",
   "web"     : OUT_ROOT / "06_web_docs",
   "logs"    : OUT_ROOT / "_logs",
}
CATEGORY_MAP = {
   "farmers"     : "farmers",
   "system"      : "system",
   "systemtools" : "system",
   "metlife"     : "custom",
}
_GUIDEWIRE_FOOTER_PREFIX = "Guidewire InsuranceSuite"
PRODUCT_MAP = {
   "integgatewayfw"   : "integration_gateway",
   "policycenterflex" : "policycenter",
   "claimcenterflex"  : "claimcenter",
   "billingcenterflex": "billingcenter",
   "contactmgmt"      : "contact_management",
   "dataaccessflex"   : "data_access",
   "insuredge"        : "insuredge",
}
 
# ------------------------------------------------------------------------------
# CONSOLE UI UTILS
# ------------------------------------------------------------------------------
def _ansi(code: str) -> str:
   return f"\033[{code}m" if sys.stdout.isatty() else ""
RESET   = _ansi("0");  BOLD    = _ansi("1")
GREEN   = _ansi("32"); YELLOW  = _ansi("33")
CYAN    = _ansi("36"); RED     = _ansi("31")
DIM     = _ansi("2");  MAGENTA = _ansi("35")
 
def header(text: str) -> None:
   w = 68
   print(f"\n{CYAN}{BOLD}{'=' * w}{RESET}")
   print(f"{CYAN}{BOLD}  {text.upper()}{RESET}")
   print(f"{CYAN}{'=' * w}{RESET}")
def ok(msg: str)   -> None: print(f"  {GREEN}✓{RESET} {msg}")
def warn(msg: str) -> None: print(f"  {YELLOW}⚠{RESET} {msg}")
def err(msg: str)  -> None: print(f"  {RED}✗{RESET} {msg}")
def info(msg: str) -> None: print(f"  {DIM}·{RESET} {msg}")
def step(msg: str) -> None: print(f"\n{BOLD}{msg}{RESET}")
 
# ------------------------------------------------------------------------------
# MODULE 1 — SWAGGER
# ------------------------------------------------------------------------------
def categorize_api(base_path: str) -> str:
   clean = base_path.strip("/").lower()
   for prefix, category in CATEGORY_MAP.items():
       if clean.startswith(prefix):
           return category
   return "core"
 
def safe_filename(base_path: str) -> str:
   return base_path.strip("/").replace("/", "_") + ".json"
 
def download_swagger_docs() -> dict:
   header("MODULE 1 — Download Swagger APIs")
   if not HAS_REQUESTS:
       err("Missing 'requests' library: pip install requests")
       return {}
   step("Connecting to PolicyCenter...")
   info(f"URL: {PC_BASE_URL}")
   try:
       r = requests.get(PC_BASE_URL, auth=PC_AUTH, timeout=15)
       r.raise_for_status()
       apis: dict = r.json()
   except requests.exceptions.ConnectionError:
       err(f"Could not connect to {PC_BASE_URL}")
       err("Verify PolicyCenter is running on localhost:8180")
       return {}
   except Exception as e:
       err(f"Error: {e}")
       return {}
   print(f"\n  {GREEN}APIs found: {len(apis)}{RESET}")
   for d in DIRS.values():
       d.mkdir(parents=True, exist_ok=True)
   step("Downloading swagger.json per API...")
   summary: dict[str, list[str]] = {cat: [] for cat in ["core", "farmers", "system", "custom"]}
   log_lines: list[str] = []
   for base_path, meta in sorted(apis.items()):
       title    = meta.get("title", base_path)
       docs_url = meta.get("docs", "")
       category = categorize_api(base_path)
       filename = safe_filename(base_path)
       out_file = DIRS[category] / filename
       if not docs_url:
           continue
       try:
           resp = requests.get(docs_url, auth=PC_AUTH, timeout=15)
           resp.raise_for_status()
           swagger = resp.json()
           swagger["_extraction_meta"] = {
               "title"       : title,
               "base_path"   : base_path,
               "source_url"  : docs_url,
               "extracted_at": datetime.now().isoformat(),
               "category"    : category,
           }
           out_file.write_text(
               json.dumps(swagger, indent=2, ensure_ascii=False),
               encoding="utf-8"
           )
           endpoint_count = len(swagger.get("paths", {}))
           ok(f"[{category.upper():8}] {title}  ({endpoint_count} endpoints)")
           summary[category].append(filename)
           log_lines.append(f"OK  | {category:8} | {title:45} | {filename}")
       except Exception as e:
           warn(f"{title}: {e}")
           log_lines.append(f"ERR | {category:8} | {title:45} | {e}")
       time.sleep(0.1)
   _write_log("swagger_download", log_lines)
   step("Category Summary:")
   total = 0
   for cat, files in summary.items():
       if files:
           print(f"  {CYAN}{cat.upper():10}{RESET} {len(files):3} files  →  {DIRS[cat]}")
           total += len(files)
   print(f"\n  {GREEN}{BOLD}Total: {total} APIs{RESET}")
   return summary
 
# ------------------------------------------------------------------------------
# MODULE 2 — PDFs
# ------------------------------------------------------------------------------
def _parse_page_footer(text: str, fallback: int) -> tuple[str, str]:
   lines = [ln.strip() for ln in text.split("\n") if ln.strip()]
   if not lines:
       return (str(fallback), "")
   last = lines[-1]
   if _GUIDEWIRE_FOOTER_PREFIX in last and len(lines) >= 2:
       last = lines[-2]
   m = re.match(r"^(.+?)\s+(\d+)\s*$", last)
   if m:
       return (f"{m.group(1).strip()} {m.group(2)}", m.group(1).strip())
   m = re.match(r"^(\d+)\s+(.+)$", last)
   if m:
       return (f"{m.group(2).strip()} {m.group(1)}", m.group(2).strip())
   return (last, last)
 
def _extract_pages(path: Path) -> list[tuple[int, str]]:
   reader = PdfReader(str(path))
   pages  = []
   for i, page in enumerate(reader.pages, start=1):
       try:
           text = page.extract_text() or ""
       except Exception:
           text = ""
       if text.strip():
           pages.append((i, text.strip()))
   return pages
 
def convert_pdfs() -> list[str]:
   header("MODULE 2 — Convert PDFs to JSON")
   if not HAS_PYPDF:
       err("Missing 'pypdf': pip install pypdf")
       return []
   if not PDF_SOURCE.exists():
       err(f"Folder not found: {PDF_SOURCE}")
       return []
   pdf_paths = sorted(PDF_SOURCE.glob("*.pdf"))
   if not pdf_paths:
       err(f"No .pdf files found in: {PDF_SOURCE}")
       return []
   DIRS["pdf"].mkdir(parents=True, exist_ok=True)
   DIRS["logs"].mkdir(parents=True, exist_ok=True)
   step(f"PDFs found: {len(pdf_paths)}")
   generated, log_lines = [], []
   for pdf in pdf_paths:
       try:
           pages = _extract_pages(pdf)
           docs  = []
           for page_num, text in pages:
               _, chapter = _parse_page_footer(text, page_num)
               meta = {"file_name": pdf.name, "page": page_num}
               if chapter:
                   meta["chapter"] = chapter
               docs.append({
                   "id"      : f"{pdf.stem}-p{page_num}",
                   "document": text,
                   "metadata": meta,
               })
           collection = {
               "name"     : pdf.stem,
               "metadata" : {"source": "gw_docs", "extracted_at": datetime.now().isoformat()},
               "count"    : len(docs),
               "documents": docs,
           }
           out_path = DIRS["pdf"] / f"{pdf.stem}.json"
           out_path.write_text(
               json.dumps(collection, indent=2, ensure_ascii=False),
               encoding="utf-8"
           )
           ok(f"{pdf.name}  →  {len(docs)} pages")
           generated.append(out_path.name)
           log_lines.append(f"OK  | {pdf.name:50} | {len(docs)} pages")
       except Exception as e:
           err(f"{pdf.name}: {e}")
           log_lines.append(f"ERR | {pdf.name:50} | {e}")
   _write_log("pdf_conversion", log_lines)
   print(f"\n  {GREEN}{BOLD}Total: {len(generated)} PDFs{RESET}")
   return generated
 
# ------------------------------------------------------------------------------
# MODULE 3 — WEB SCRAPING (docs.guidewire.com)
# ------------------------------------------------------------------------------
def _url_to_filename(url: str) -> str:
   parsed = urllib.parse.urlparse(url)
   path   = parsed.path.strip("/")
   safe   = re.sub(r"[/\\]", "__", path)
   safe   = re.sub(r"[^\w\-.]", "_", safe)
   return (safe if safe.endswith(".json") else safe + ".json")[:180]
 
def _url_to_product_folder(url: str) -> Path:
   parts   = [p for p in urllib.parse.urlparse(url).path.split("/") if p]
   product = "general"
   for part in parts:
       for key, val in PRODUCT_MAP.items():
           if key in part.lower():
               product = val
               break
       if product != "general":
           break
   folder = DIRS["web"] / product
   folder.mkdir(parents=True, exist_ok=True)
   return folder
 
def _extract_toc_links(page, base_url: str) -> list[str]:
   links         = set()
   parsed_base   = urllib.parse.urlparse(base_url)
   toc_selectors = [
       "nav a[href]", ".toc a[href]", ".sidebar a[href]",
       "[class*='toc'] a[href]", "[class*='nav'] a[href]",
       "[class*='sidebar'] a[href]", "[class*='menu'] a[href]",
       "[class*='tree'] a[href]", "aside a[href]",
   ]
   for selector in toc_selectors:
       try:
           for el in page.query_selector_all(selector):
               href = el.get_attribute("href")
               if not href or href.startswith("#") or href.startswith("javascript"):
                   continue
               if href.startswith("http"):
                   full = href
               elif href.startswith("/"):
                   full = f"{parsed_base.scheme}://{parsed_base.netloc}{href}"
               else:
                   full = urllib.parse.urljoin(base_url, href)
               if urllib.parse.urlparse(full).netloc == parsed_base.netloc:
                   links.add(full)
       except Exception:
           pass
   return list(links)
 
def _scrape_page_content(page) -> dict:
   title = ""
   try:
       title = re.sub(r"\s*\|\s*Guidewire.*$", "", page.title()).strip()
   except Exception:
       pass
   raw_text = ""
   for sel in ["main", "article", "[class*='content']", "[role='main']", ".topic", "body"]:
       try:
           el = page.query_selector(sel)
           if el:
               raw_text = el.inner_text()
               if len(raw_text) > 200:
                   break
       except Exception:
           pass
   headings = []
   for level in ["h1", "h2", "h3", "h4"]:
       try:
           for el in page.query_selector_all(level):
               txt = el.inner_text().strip()
               if txt:
                   headings.append({"level": level, "text": txt})
       except Exception:
           pass
   code_blocks = []
   try:
       for el in page.query_selector_all("pre, code")[:20]:
           code = el.inner_text().strip()
           if len(code) > 20:
               code_blocks.append(code)
   except Exception:
       pass
   clean_text = re.sub(r"\n{3,}", "\n\n", raw_text).strip()
   return {
       "title"      : title,
       "content"    : clean_text,
       "headings"   : headings,
       "code_blocks": code_blocks,
       "char_count" : len(clean_text),
   }
 
def _do_login(page, email: str, password: str) -> bool:
   step("Logging into docs.guidewire.com...")
   try:
       page.goto("https://docs.guidewire.com", timeout=30000)
       page.wait_for_load_state("networkidle", timeout=20000)
       if "gw-login" not in page.url and "login" not in page.url.lower():
           ok("Session already active")
           return True
       login_pairs = [
           ("input[type='email']",    "input[type='password']"),
           ("input[name='username']", "input[name='password']"),
           ("#okta-signin-username",  "#okta-signin-password"),
           ("#username",              "#password"),
       ]
       for email_sel, pass_sel in login_pairs:
           try:
               page.wait_for_selector(email_sel, timeout=4000)
               page.fill(email_sel, email)
               time.sleep(0.4)
               page.wait_for_selector(pass_sel, timeout=4000)
               page.fill(pass_sel, password)
               time.sleep(0.4)
               for btn in ["button[type='submit']", "#okta-signin-submit", "input[type='submit']"]:
                   try:
                       page.click(btn)
                       break
                   except Exception:
                       pass
               page.wait_for_load_state("networkidle", timeout=25000)
               time.sleep(2)
               if "gw-login" not in page.url and "login" not in page.url.lower():
                   ok("Login successful")
                   return True
           except Exception:
               continue
       err("Automatic login failed")
       return False
   except Exception as e:
       err(f"Login error: {e}")
       return False
 
def scrape_web_docs() -> list[str]:
   header("MODULE 3 — Scraping docs.guidewire.com")
   if not HAS_PLAYWRIGHT:
       err("Missing 'playwright'.")
       print(f"\n  {YELLOW}Install with:{RESET}\n  pip install playwright\n  playwright install chromium\n")
       return []
   if not GW_DOCS_ENTRY_POINTS:
       warn("GW_DOCS_ENTRY_POINTS list is empty. Add URLs in configuration.")
       return []
   DIRS["web"].mkdir(parents=True, exist_ok=True)
   DIRS["logs"].mkdir(parents=True, exist_ok=True)
   generated, log_lines = [], []
   with sync_playwright() as pw:
       browser = pw.chromium.launch(headless=False, slow_mo=50)
       context = browser.new_context(
           viewport={"width": 1280, "height": 900},
           user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
       )
       page = context.new_page()
       if GW_DOCS_EMAIL and GW_DOCS_PASSWORD:
           if not _do_login(page, GW_DOCS_EMAIL, GW_DOCS_PASSWORD):
               browser.close()
               return []
       else:
           page.goto("https://docs.guidewire.com", timeout=30000)
           print(f"\n  {YELLOW}{'-'*60}{RESET}")
           print(f"  {YELLOW}Browser is open.{RESET}")
           print(f"  {YELLOW}Please login manually to Guidewire Portal.{RESET}")
           print(f"  {YELLOW}Once documentation loads, return here.{RESET}")
           print(f"  {YELLOW}{'-'*60}{RESET}")
           input(f"\n  {BOLD}→ Press ENTER once you have logged in: {RESET}")
       visited: set[str] = set()
       queue: list[str]  = list(GW_DOCS_ENTRY_POINTS)
       step(f"Starting scraping — {len(queue)} entry point(s)")
       while queue:
           url = queue.pop(0)
           if url in visited: continue
           visited.add(url)
           info(f"Processing ({len(visited)}/{len(visited)+len(queue)}): {url[-80:]}")
           try:
               page.goto(url, timeout=30000, wait_until="networkidle")
               time.sleep(1.5)
               if "gw-login" in page.url or "login" in page.url.lower():
                   warn("Session expired — returning to login")
                   if GW_DOCS_EMAIL:
                       _do_login(page, GW_DOCS_EMAIL, GW_DOCS_PASSWORD)
                       page.goto(url, timeout=30000, wait_until="networkidle")
                   else:
                       input(f"  {YELLOW}→ ENTER when you have logged back in: {RESET}")
                       page.goto(url, timeout=30000, wait_until="networkidle")
               content = _scrape_page_content(page)
               if content["char_count"] < 100:
                   log_lines.append(f"SKIP| {url}")
                   continue
               if url in GW_DOCS_ENTRY_POINTS:
                   toc_links = _extract_toc_links(page, url)
                   new_links  = [l for l in toc_links if l not in visited]
                   queue.extend(new_links)
               folder   = _url_to_product_folder(url)
               out_file = folder / _url_to_filename(url)
               doc = {
                   "id"      : re.sub(r"[^\w\-]", "_", url.split("//")[-1])[:120],
                   "url"     : url,
                   "document": content["content"],
                   "metadata": {
                       "title"       : content["title"],
                       "headings"    : content["headings"],
                       "code_blocks" : content["code_blocks"][:5],
                       "source"      : "gw_web_docs",
                       "product"     : folder.name,
                       "extracted_at": datetime.now().isoformat(),
                   },
               }
               out_file.write_text(json.dumps(doc, indent=2, ensure_ascii=False), encoding="utf-8")
               ok(f"[{folder.name:25}] {content['title'] or '(no title)'}  ({content['char_count']} chars)")
               generated.append(str(out_file))
               log_lines.append(f"OK  | {folder.name:25} | {content['title']:40} | {url}")
           except PWTimeout:
               warn(f"Timeout: {url[-70:]}")
               log_lines.append(f"TOUT| {url}")
           except Exception as e:
               warn(f"Error: {e}")
               log_lines.append(f"ERR | {url} | {e}")
           time.sleep(0.8)
       browser.close()
   _write_log("web_scraping", log_lines)
   print(f"\n  {GREEN}{BOLD}Total pages saved: {len(generated)}{RESET}")
   return generated
 
# ------------------------------------------------------------------------------
# MODULE 4 — VISUAL GUIDE TXT
# ------------------------------------------------------------------------------
def generate_visual_guide() -> Optional[Path]:
   header("MODULE 4 — Structure Visual Guide")
   if not OUT_ROOT.exists():
       err(f"Folder '{OUT_ROOT}' does not exist. Run downloads first.")
       return None
   lines: list[str] = []
   now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
   lines += [
       "=" * 72,
       "GUIDEWIRE DOCUMENTATION — STRUCTURE GUIDE".center(72),
       f"Generated: {now}".center(72),
       "=" * 72,
       "",
       f"Root Path: {OUT_ROOT.resolve()}",
       "",
   ]
   folder_descs = {
       "01_core_apis"    : "Core APIs (Account, Admin, Policy, ProductDefinition...)",
       "02_farmers_apis" : "Farmers Custom APIs",
       "03_system_apis"  : "System APIs (DB, Cluster, Workflows...)",
       "04_custom_apis"  : "Additional Custom APIs",
       "05_pdf_docs"     : "PDF Documentation → JSON (1 entry per page)",
       "06_web_docs"     : "Scraped Web Documentation from docs.guidewire.com",
       "_logs"           : "Execution Logs",
   }
   subdirs = sorted([d for d in OUT_ROOT.iterdir() if d.is_dir()])
   for subdir in subdirs:
       desc      = folder_descs.get(subdir.name, "")
       all_files = list(subdir.rglob("*.json")) + list(subdir.rglob("*.log"))
       n         = len(all_files)
       lines.append(f"+ Folder: {subdir.name}/")
       if desc: lines.append(f"  Description: {desc}")
       lines.append(f"  ({n} file{'s' if n != 1 else ''})")
       lines.append("")
   out_path = OUT_ROOT / "_STRUCTURE_GUIDE.txt"
   out_path.write_text("\n".join(lines), encoding="utf-8")
   ok(f"Guide generated: {out_path.resolve()}")
   return out_path
 
# ------------------------------------------------------------------------------
# UTILS
# ------------------------------------------------------------------------------
def _ts() -> str:
   return datetime.now().strftime("%Y%m%d_%H%M%S")
 
def _write_log(prefix: str, lines: list[str]) -> None:
   DIRS["logs"].mkdir(parents=True, exist_ok=True)
   path = DIRS["logs"] / f"{prefix}_{_ts()}.log"
   path.write_text(
       f"{prefix} log — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
       + "=" * 80 + "\n"
       + "\n".join(lines),
       encoding="utf-8"
   )
   info(f"Log saved: {path}")
 
# ------------------------------------------------------------------------------
# MAIN MENU
# ------------------------------------------------------------------------------
def print_banner() -> None:
   print(f"""
{CYAN}{BOLD}====================================================================
     GUIDEWIRE DOCUMENTATION EXTRACTOR  v2
     Swagger APIs  +  PDFs  +  Web Docs  ->  Organized JSON
===================================================================={RESET}
""")
 
def check_deps() -> None:
   missing = []
   if not HAS_REQUESTS:   missing.append(("requests", "for Swagger"))
   if not HAS_PYPDF:      missing.append(("pypdf", "for PDFs"))
   if not HAS_PLAYWRIGHT: missing.append(("playwright", "for Web Docs"))
   if missing:
       print(f"{YELLOW}Missing dependencies:{RESET}")
       for pkg, reason in missing:
           print(f"  pip install {pkg}  <- {reason}")
       print()
 
def print_menu() -> None:
   sw  = f"{GREEN}OK{RESET}" if HAS_REQUESTS   else f"{RED}missing requests{RESET}"
   pdf = f"{GREEN}OK{RESET}" if HAS_PYPDF      else f"{RED}missing pypdf{RESET}"
   web = f"{GREEN}OK{RESET}" if HAS_PLAYWRIGHT else f"{RED}missing playwright{RESET}"
   print(f"""
{BOLD}  What would you like to do?{RESET}
 {CYAN}1{RESET}  Download Swagger APIs from PolicyCenter  [{sw}]
 {CYAN}2{RESET}  Convert Guidewire PDFs to JSON           [{pdf}]
 {CYAN}3{RESET}  Scrape docs.guidewire.com                [{web}]
 {CYAN}4{RESET}  Run EVERYTHING  (1 + 2 + 3)
 {CYAN}5{RESET}  Generate visual TXT guide
 {CYAN}0{RESET}  Exit
""")
 
def main() -> None:
   if sys.platform == "win32":
       os.system("color")
   print_banner()
   check_deps()
   while True:
       print_menu()
       choice = input(f"  {BOLD}Option [{CYAN}0-5{RESET}{BOLD}]: {RESET}").strip()
       if choice == "0":
           print(f"\n{DIM}Goodbye.{RESET}\n")
           break
       elif choice == "1":
           download_swagger_docs()
       elif choice == "2":
           convert_pdfs()
       elif choice == "3":
           scrape_web_docs()
       elif choice == "4":
           header("FULL EXECUTION")
           s = download_swagger_docs()
           p = convert_pdfs()
           w = scrape_web_docs()
           g = generate_visual_guide()
           header("FINAL SUMMARY")
           print(f"  {GREEN}✓{RESET} APIs Downloaded : {sum(len(v) for v in s.values())}")
           print(f"  {GREEN}✓{RESET} PDFs Converted  : {len(p)}")
           print(f"  {GREEN}✓{RESET} Web Pages       : {len(w)}")
           if g: ok(f"Guide generated: {g}")
       elif choice == "5":
           generate_visual_guide()
       else:
           warn("Invalid option. Please enter 0-5.")
       input(f"\n  {DIM}Press ENTER to continue...{RESET}")
 
if __name__ == "__main__":
   main()
