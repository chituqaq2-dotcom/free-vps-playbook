#!/bin/bash
# For containers WITHOUT systemd (proot / panel sandboxes). Put this in /opt/px/run.sh,
# start watch loop from ~/.bashrc:  pgrep -f px-watch >/dev/null || setsid /opt/px/run.sh watch >/dev/null 2>&1 &
cd /opt/px
up(){ pgrep -f "$1" >/dev/null || { setsid $2 >>/opt/px/$3.log 2>&1 & }; }
start(){
  up "xray run"            "./xray run -c config.json"                                        xray
  up "cloudflared tunnel"  "./cloudflared tunnel --no-autoupdate run --token $(cat tunnel.token)" cf
  up "cloudflared access"  "./cloudflared access tcp --hostname nzgrpc.example.com --url 127.0.0.1:18008" cfnz
  up "nezha-agent"         "./nezha-agent -c nz.yml"                                          nz
}
if [ "$1" = watch ]; then exec -a px-watch bash -c 'while :; do /opt/px/run.sh; sleep 30; done'; else start; fi
