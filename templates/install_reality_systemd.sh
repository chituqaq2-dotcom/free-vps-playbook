#!/bin/bash
# VPS with public IPv4 + systemd: Xray VLESS+REALITY :443 + nezha-agent (via cloudflared access tcp). systemd.
[ "$(id -u)" = 0 ] || exec sudo bash "$0" "$@"
set -e; echo OCI_START
case $(uname -m) in x86_64) XA=64; CA=amd64;; aarch64) XA=arm64-v8a; CA=arm64;; esac
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null; apt-get install -y -qq unzip curl ca-certificates >/dev/null
mkdir -p /opt/px && cd /opt/px
[ -x xray ] || { curl -fsSL -o x.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-$XA.zip && unzip -oq x.zip xray && rm x.zip; chmod +x xray; }
[ -x cloudflared ] || { curl -fsSL -o cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$CA && chmod +x cloudflared; }
[ -x nezha-agent ] || { curl -fsSL -o a.zip https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_$CA.zip && unzip -oq a.zip nezha-agent && rm a.zip; chmod +x nezha-agent; }
cat > config.json <<'J'
{"log":{"loglevel":"warning"},
 "inbounds":[{"listen":"0.0.0.0","port":443,"protocol":"vless",
  "settings":{"clients":[{"id":"<SECRET>","flow":"xtls-rprx-vision"}],"decryption":"none"},
  "streamSettings":{"network":"tcp","security":"reality",
   "realitySettings":{"show":false,"dest":"www.microsoft.com:443","xver":0,"serverNames":["www.microsoft.com"],"privateKey":"<SECRET>","shortIds":["<SECRET>"]}},
  "sniffing":{"enabled":true,"destOverride":["http","tls","quic"],"routeOnly":true}}],
 "outbounds":[{"protocol":"freedom","tag":"direct"},{"protocol":"blackhole","tag":"block"}]}
J
cat > nz.yml <<'C'
client_secret: <SECRET>
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
C
chmod 600 config.json nz.yml
mk(){ cat > /etc/systemd/system/$1.service <<S
[Unit]
Description=$1
After=network-online.target
Wants=network-online.target
[Service]
WorkingDirectory=/opt/px
ExecStart=$2
Restart=always
RestartSec=5
$3
[Install]
WantedBy=multi-user.target
S
}
mk px-xray "/opt/px/xray run -c /opt/px/config.json" "AmbientCapabilities=CAP_NET_BIND_SERVICE"
mk px-cfnz "/opt/px/cloudflared access tcp --hostname nzgrpc.example.com --url 127.0.0.1:18008 --loglevel warn" ""
mk px-nezha "/opt/px/nezha-agent -c /opt/px/nz.yml" ""
# Oracle Ubuntu images REJECT everything but 22 in iptables: allow 443
iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -I INPUT 5 -p tcp --dport 443 -j ACCEPT
command -v netfilter-persistent >/dev/null && netfilter-persistent save >/dev/null 2>&1 || true
# 1 GB RAM: add 1 GB swap
[ -f /swapfile ] || { fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile && echo '/swapfile none swap sw 0 0' >> /etc/fstab; }
systemctl daemon-reload; systemctl enable --now px-xray px-cfnz px-nezha >/dev/null 2>&1
sleep 8
echo "xray: $(systemctl is-active px-xray)  cf: $(systemctl is-active px-cfnz)  nezha: $(systemctl is-active px-nezha)"
ss -ltn | grep -q ':443 ' && echo "443 listening"
echo OCI_DONE
