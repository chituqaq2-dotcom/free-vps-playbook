# 04 · 订阅

- 模板：`templates/worker_subscription.js`。一个 URL 按 UA 输出 base64 或 Clash YAML；路径即密钥。
- 用自定义域名绑定 Worker（`sub.<你的域名>`），别用 workers.dev（国内常被墙）。
- 订阅分组：
  - 「羊毛 VPS」合并订阅：所有白嫖机放一起。
  - 用户主力机订阅：独立。
  - 住宅代理订阅：独立（socks 行 / base64 / Clash）。
- Clash YAML：PROXY 选择组第一项「⚡自动选择」（url-test，gstatic 204，300 s，tolerance 80），新节点必须同时进两个组。
- 改动流程：拉当前脚本 → 本地备份（带日期和原因）→ 修改 → 部署 → `curl` 验证 base64 行数和 Clash 节点数 → 让用户刷新订阅。
- Workers API 部署：multipart 的脚本字段需要 `filename=worker.js`；重新部署时保留已有 secret 绑定（`keep_bindings`）。
- 临时安装脚本可以挂在 Worker 的一个随机路由或临时子域上，装完立即删。
