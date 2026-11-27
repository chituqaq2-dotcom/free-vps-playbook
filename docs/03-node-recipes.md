# 03 · 节点配方

## 选型
```
有公网 IPv4 且能开端口？
 ├─ 是 → A. REALITY 直连（最快）  + 可选 C. CF 隧道优选变体
 └─ 否（NAT / 只有一个面板端口 / IPv6-only / 无 systemd 容器）
      ├─ 只给一个端口且是裸 TCP → A. REALITY 占用该端口
      └─ 其他 → B. VLESS+WS 本地监听 + cloudflared 命名隧道
```

## A. VLESS + REALITY 直连
- 模板：`templates/install_reality_systemd.sh`（systemd 版），`templates/panel_container_launcher.py`（面板容器版，端口取 `SERVER_PORT`）。
- 参数：flow `xtls-rprx-vision`，dest/SNI `www.microsoft.com:443`，fingerprint `chrome`，shortId 8–16 位 hex。
- `xray x25519` 生成密钥对；私钥只在服务器，公钥进订阅。
- Oracle Ubuntu 镜像的 iptables 默认只放行 22，要插一条放行 443（模板里有），并在 VCN 安全列表放行。
- 1 GB 内存的小机器加 1 GB swap。

## B. VLESS + WS + Cloudflare Tunnel
- Xray 只监听 `127.0.0.1:10000`，WS 路径随机。
- Cloudflare Zero Trust 建命名隧道 → Public hostname `nodeX.<你的域名>` → `http://localhost:10000`；DNS CNAME 开橙云。
- cloudflared：`tunnel --no-autoupdate run --token <TOKEN>`；IPv6-only 机器加 `--edge-ip-version 6`；容器里 QUIC 不稳时用 `--protocol http2`。
- 客户端：server 填隧道域名（或优选域名），443，tls，SNI/Host = 隧道域名。

## C. CF 优选变体
- 同一台机器多开一个 WS inbound（如 10001）+ 第二条隧道（`templates/add_cf_tunnel_ws.sh`）。
- 订阅里 server 写优选域名（如 `www.visa.com.sg`），SNI/Host 写隧道域名，名字加「-优选」。
- 电信用户往往直连 REALITY 跑不满时，优选 CF 反而更稳。

## IPv6-only 机器
- 见 `templates/xray_ws_ipv6only.json`：freedom `domainStrategy: UseIPv6` + 公共 DNS64，IPv4-only 站点会经 NAT64 出（出口在 NAT64 提供方所在国）。
- WARP WireGuard 出口在这类 LXC 里实测 TLS 卡 ~11 s，放弃。
- Agent 沙箱若没有 IPv6，就通过另一台有 IPv6 的机器（例如一个免费容器）做跳板 SSH。

## 进程托管
- 有 systemd：每个进程一个 unit，`Restart=always`，`enable --now`。
- 无 systemd：`templates/run_watch.sh`（缺哪个拉哪个，每 30 s 巡检）+ `.bashrc` 钩子。这类机器重启后要有人打开 web console 触发一次。

## 上线验收（沙箱）
`templates/nodetest.sh`：ip-api 出口归属（proxy/hosting 字段）、generate_204 冷/热中位数、10 MB 下载速度；再抽查 chatgpt.com / gemini.google.com / x.com / github.com 状态码。

## D. SOCKS5 落地（链式）
- 别人送的/薅来的 SOCKS5（静态 IP、商宽、“家宽”）在国内直连通常会被墙，必须**链式**：Clash/mihomo 里给 socks5 节点加 `dialer-proxy: <前置节点名>`，前置用一条国内连得上的加密节点（自己的 REALITY 机或 CF 优选 WS）。
- base64（v2rayN/小火箭）格式表达不了链式，所以 SOCKS5 落地**只进 Clash 版**。
- 前置选哪条以用户本地实测为准（沙箱在海外，延迟没有参考价值）。
- 拿到 IP 先查两家以上的库（如 ip-api 的 proxy/hosting、proxycheck 的类型/风险分）。各家结论常打架，汇报时如实说“不保证是纯家宽”。论坛公开发的 IP 多人共用，不建议用来注册重要账号。

## 不适合做节点的平台形态
- 只给 HTTP 入口、且平台反代**缓冲整段响应**的（实测下行被憋 10 秒以上才吐出）：VLESS+WS/XHTTP 都走不通，加 `X-Accel-Buffering: no` 也没用。先用一个流式接口测一下再投入。
- 闲置就休眠、只认外部访问唤醒的容器：内部跑程序保活无效（会被一起冻住）；外部定时 ping 能唤醒但往往按运行小时计额度。
