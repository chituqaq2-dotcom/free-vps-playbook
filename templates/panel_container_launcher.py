# Panel container (Pterodactyl-style, single port): xray REALITY on the allocated port + nezha-agent via cloudflared access tcp
import os, sys, time, json, zipfile, urllib.request, subprocess, platform, stat
BASE = os.path.join(os.getcwd(), "px"); os.makedirs(BASE, exist_ok=True); os.chdir(BASE)
PORT = int(os.environ.get("SERVER_PORT") or 443)
m = platform.machine()
XA, CA = ("64", "amd64") if m in ("x86_64", "amd64") else ("arm64-v8a", "arm64")
def log(*a): print("[px]", *a, flush=True)
def dl(url, out):
    for i in range(5):
        try:
            urllib.request.urlretrieve(url, out); return
        except Exception as e:
            log("download retry", i, url.split("/")[-1], e); time.sleep(5)
    raise SystemExit("download failed " + url)
def unz(zf, name):
    with zipfile.ZipFile(zf) as z: z.extract(name, ".")
    os.remove(zf)
def ex(p): os.chmod(p, os.stat(p).st_mode | stat.S_IEXEC)
GH = "https://github.com/"
if not os.path.exists("xray"):
    dl(GH + "XTLS/Xray-core/releases/latest/download/Xray-linux-%s.zip" % XA, "x.zip"); unz("x.zip", "xray"); ex("xray")
if not os.path.exists("cloudflared"):
    dl(GH + "cloudflare/cloudflared/releases/latest/download/cloudflared-linux-%s" % CA, "cloudflared"); ex("cloudflared")
if not os.path.exists("nezha-agent"):
    dl(GH + "nezhahq/agent/releases/latest/download/nezha-agent_linux_%s.zip" % CA, "a.zip"); unz("a.zip", "nezha-agent"); ex("nezha-agent")
cfg = {"log": {"loglevel": "warning"},
 "inbounds": [{"listen": "127.0.0.1", "port": PORT, "protocol": "vless",
   "settings": {"clients": [{"id": "<SECRET>", "flow": "xtls-rprx-vision"}], "decryption": "none"},
   "streamSettings": {"network": "tcp", "security": "reality",
     "realitySettings": {"show": False, "dest": "www.microsoft.com:443", "xver": 0, "serverNames": ["www.microsoft.com"],
       "privateKey": "<SECRET>", "shortIds": ["<SECRET>"]}},
   "sniffing": {"enabled": True, "destOverride": ["http", "tls", "quic"], "routeOnly": True}}],
 "outbounds": [{"protocol": "freedom", "tag": "direct"}, {"protocol": "blackhole", "tag": "block"}]}
json.dump(cfg, open("config.json", "w"))
open("nz.yml", "w").write("""client_secret: <SECRET>
server: 127.0.0.1:18008
tls: false
uuid: <SECRET>
disable_auto_update: true
disable_force_update: true
disable_command_execute: true
disable_nat: true
disable_send_query: false
skip_connection_count: true
skip_procs_count: true
report_delay: 3
""")
os.chmod("config.json", 0o600); os.chmod("nz.yml", 0o600)
CMDS = {
 "xray": ["./xray", "run", "-c", "config.json"],
 "cf": ["./cloudflared", "access", "tcp", "--hostname", "nzgrpc.example.com", "--url", "127.0.0.1:18008", "--loglevel", "warn"],
 "agent": ["./nezha-agent", "-c", "nz.yml"],
}
procs = {}
def start(n):
    procs[n] = subprocess.Popen(CMDS[n], stdout=open(n + ".log", "ab"), stderr=subprocess.STDOUT)
    log("started", n, "pid", procs[n].pid)
log("arch", m, "port", PORT)
start("xray"); start("cf"); time.sleep(4); start("agent")
log("ready")
while True:
    time.sleep(20)
    for n, p in list(procs.items()):
        if p.poll() is not None:
            log(n, "exited", p.returncode, "- restarting"); time.sleep(2); start(n)
