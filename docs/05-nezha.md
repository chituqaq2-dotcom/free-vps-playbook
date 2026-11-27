# 05 · 哪吒探针

- 面板装在最稳的那台（有 systemd、内存够），用 CF 隧道暴露 `status.<域名>`，origin 用 http2。
- Agent 通用配置：`disable_command_execute: true`（防 webssh 被利用）、关自动更新、`disable_send_query: false`（要做 TCPing 服务监控时）。
- 当 CF zone 的 gRPC 开不了：面板隧道加一条 `nzgrpc.<域名>` → `tcp://localhost:8008`；各 agent 用
  `cloudflared access tcp --hostname nzgrpc.<域名> --url 127.0.0.1:18008`，agent 连 `127.0.0.1:18008`，`tls: false`。
- 安全：CF WAF 只对 `/dashboard*` 做托管质询；**别质询登录接口**（会让登录 XHR 报 Network Error）；登录接口加限速（如 10 s 内 >5 次封）。
- API：2.x 写操作要带 `X-CSRF-Token`（值 = `nz-csrf` cookie）。公开 `/api/v1/server` 需要鉴权时，读 `wss://<面板>/api/v1/ws/server` 拿实时状态和 `last_active`。
- 服务监控：三网 TCPing（广东电信/联通/移动的探测点 :80），60 s；资源紧张的机器（按 CPU 时长计费的免费容器）单独 180 s 或排除。
- 新机器上线后：改名为订阅里的同名（不带限额/速度后缀），国旗由 IP 自动识别。
- 判断离线：`last_active` 超过 3 分钟 = 离线；`0001-01-01` = 从未上报过。

## 补充（2026-11）
- 哪吒 2.x：agent 的 client secret 只在后台 Servers → Installation command 里出现；要先在 Settings 填好 Agent 连接地址和站点名，这条命令才会显示。
- 机器删掉后，后台条目会一直显示离线/从未上报，巡检要么忽略这个 id，要么问用户后删掉条目；别让它天天报红灯。
- 面板网页终端装 agent 的“临时 root 密码法”见 [09 篇第 4 节](09-lessons-2026-11-27.md)。
