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

## 补充约定
- **脚本生成的订阅**（例如住宅代理池，每 N 分钟由脚本重写）不要手工往里加节点，会被冲掉；要加东西就在订阅 Worker 输出时注入（例如用一个 Worker secret 存一整行前置节点 YAML，输出 Clash 时插入并给 socks5 加 `dialer-proxy`）。
- 注入整行 YAML 后必须 `yaml.safe_load` 校验最终输出；少一个 `}` 客户端就整份订阅解析失败。
- base64 行的顺序会影响部分客户端的默认选择：新节点（尤其没验证过的）建议追加在末尾，别插在第一行。
- 每次改动的本地备份按时间+原因命名，形成可回滚的链；改完同时核对 base64 行数、Clash proxies 数、PROXY 组和自动选择组成员数，并把预期数量同步给巡检任务。
