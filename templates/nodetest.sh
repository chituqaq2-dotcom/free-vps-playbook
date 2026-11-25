#!/bin/bash
# usage: nodetest.sh <server> <host/sni> <uuid-file> <path> <socksport>
S=$1; H=$2; U=$(cat $3); P=$4; SP=${5:-10808}; D=$(dirname $0)
umask 077; CF=/tmp/xc_$SP.json
cat > $CF <<J
{"log":{"loglevel":"warning"},"inbounds":[{"listen":"0.0.0.0","port":$SP,"protocol":"socks","settings":{"udp":false}}],
"outbounds":[{"protocol":"vless","settings":{"vnext":[{"address":"$S","port":443,"users":[{"id":"$U","encryption":"none"}]}]},
"streamSettings":{"network":"ws","security":"tls","tlsSettings":{"serverName":"$H"},"wsSettings":{"path":"$P","headers":{"Host":"$H"}}}}]}
J
$D/bin/xray run -c $CF >/tmp/xc_$SP.log 2>&1 & X=$!; sleep 2
C=(curl -s --noproxy "" --socks5-hostname 127.0.0.1:$SP)
echo "ipapi: $("${C[@]}" -m 20 "http://ip-api.com/json/?fields=status,query,country,regionName,city,isp,org,as,mobile,proxy,hosting")"
L=(); for i in 1 2 3 4 5 6; do t=$("${C[@]}" -m 20 -o /dev/null -w "%{time_total}" https://www.google.com/generate_204); L+=($t); done
echo "g204 times: ${L[*]} (first is cold)"
python3 -c "import statistics,sys;v=[float(x)*1000 for x in sys.argv[2:]];print('median_ms(warm 5)=%.0f'%statistics.median(v))" x ${L[@]:1}
echo "down: $("${C[@]}" -m 60 -o /dev/null -w "%{size_download}B %{time_total}s %{speed_download}B/s" "https://speed.cloudflare.com/__down?bytes=10000000" | head -c 200)"
kill $X; rm -f $CF
