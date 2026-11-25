#!/bin/bash
[ "$(id -u)" = 0 ] || exec sudo bash "$0" "$@"
set -e; echo JP_START; cd /opt/px
python3 - <<'P'
import json
c=json.load(open('/opt/px/config.json'))
c['inbounds']=[i for i in c['inbounds'] if i.get('port')!=10001]
c['inbounds'].append({"listen":"0.0.0.0","port":10001,"protocol":"vless","settings":{"clients":[{"id":"<SECRET>"}],"decryption":"none"},
 "streamSettings":{"network":"ws","wsSettings":{"path":"<SECRET>"}},"sniffing":{"enabled":True,"destOverride":["http","tls","quic"],"routeOnly":True}})
json.dump(c,open('/opt/px/config.json','w'))
P
/opt/px/xray run -test -c /opt/px/config.json >/dev/null && systemctl restart px-xray
echo -n '<SECRET>' > /opt/px/jp.token; chmod 600 /opt/px/jp.token
cat > /etc/systemd/system/px-cfjp.service <<'S'
[Unit]
Description=px-cfjp
After=network-online.target
Wants=network-online.target
[Service]
ExecStart=/bin/sh -c 'exec /opt/px/cloudflared tunnel --no-autoupdate --protocol http2 run --token $(cat /opt/px/jp.token)'
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
S
systemctl daemon-reload; systemctl enable --now px-cfjp >/dev/null 2>&1; sleep 6
echo "xray: $(systemctl is-active px-xray)  cfjp: $(systemctl is-active px-cfjp)"; ss -ltn | grep -c ':10001 ' | sed 's/^/10001 listening: /'
echo JP_DONE
