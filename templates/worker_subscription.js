// Cloudflare Worker: one URL, three outputs.
//   default UA            -> base64 of vless:// lines (v2rayN / Shadowrocket)
//   UA contains "clash" or ?target=clash -> Clash/mihomo YAML with a url-test group
// Path must be /<KEY>; everything else 404.  Optional cron pings KEEPALIVE urls.
const KEY = "<SUB_KEY>";
const NODES = [
  // REALITY direct
  { name: "VPS1-SG新加坡 | 不限 | 170ms | 3.6MB/s", type: "reality", server: "1.2.3.4", port: 443,
    uuid: "<UUID>", sni: "www.microsoft.com", pbk: "<REALITY_PUBLIC_KEY>", sid: "<SHORT_ID>" },
  // VLESS+WS behind a Cloudflare tunnel
  { name: "VPS2-US西 | 10GB/月 | 250ms | 5MB/s", type: "ws", server: "node2.example.com", port: 443,
    uuid: "<UUID>", host: "node2.example.com", path: "/<WS_PATH>" },
];
const KEEPALIVE = []; // e.g. ["https://your-free-container.example/"]

const enc = encodeURIComponent;
function link(n) {
  if (n.type === "reality")
    return `vless://${n.uuid}@${n.server}:${n.port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${n.sni}&fp=chrome&pbk=${n.pbk}&sid=${n.sid}&type=tcp#${enc(n.name)}`;
  return `vless://${n.uuid}@${n.server}:${n.port}?encryption=none&security=tls&sni=${n.host}&fp=chrome&type=ws&host=${n.host}&path=${enc(n.path)}#${enc(n.name)}`;
}
function clash(n) {
  const q = JSON.stringify(n.name);
  if (n.type === "reality")
    return `  - {name: ${q}, type: vless, server: ${n.server}, port: ${n.port}, uuid: ${n.uuid}, network: tcp, tls: true, udp: true, flow: xtls-rprx-vision, servername: ${n.sni}, client-fingerprint: chrome, reality-opts: {public-key: ${n.pbk}, short-id: ${n.sid}, support-x25519mlkem768: true}}`;
  return `  - {name: ${q}, type: vless, server: ${n.server}, port: ${n.port}, uuid: ${n.uuid}, network: ws, tls: true, udp: true, servername: ${n.host}, client-fingerprint: chrome, ws-opts: {path: ${JSON.stringify(n.path)}, headers: {Host: ${n.host}}}}`;
}
function yaml() {
  const names = NODES.map(n => "      - " + JSON.stringify(n.name)).join("\n");
  return `mixed-port: 7890
allow-lan: false
mode: rule
log-level: info
proxies:
${NODES.map(clash).join("\n")}
proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - ⚡自动选择
${names}
      - DIRECT
  - name: ⚡自动选择
    type: url-test
    url: https://www.gstatic.com/generate_204
    interval: 300
    tolerance: 80
    proxies:
${names}
rules:
  - GEOIP,PRIVATE,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
`;
}
export default {
  async fetch(req) {
    const u = new URL(req.url);
    if (u.pathname !== "/" + KEY) return new Response("Not found", { status: 404 });
    const ua = (req.headers.get("user-agent") || "").toLowerCase();
    if (u.searchParams.get("target") === "clash" || ua.includes("clash") || ua.includes("mihomo"))
      return new Response(yaml(), { headers: { "content-type": "text/yaml; charset=utf-8" } });
    return new Response(btoa(unescape(encodeURIComponent(NODES.map(link).join("\n")))),
      { headers: { "content-type": "text/plain; charset=utf-8" } });
  },
  async scheduled(_e, _env, ctx) {
    ctx.waitUntil(Promise.all(KEEPALIVE.map(x => fetch(x).catch(() => 0))));
  },
};
