# free-vps-playbook

> 白嫖小鸡 → 搭节点 → 进探针 → 进订阅 → 自动保活 / 续期。
> 一份给 AI Agent（以及人）的完整工作手册：接手的 Agent 读完就能按同样的方式、同样的规矩继续干活，不用用户从头交代。

**本仓库不含任何主机、域名、账号、密钥。** 所有 `<SECRET>`、`<UUID>`、`example.com` 都是占位符。
具体机器清单与私密信息由用户另行私下提供（`HANDOFF_PRIVATE.md`，不进仓库）。

## 目录

| 文档 | 内容 |
|---|---|
| [01-working-style](docs/01-working-style.md) | 沟通方式、口头指令含义、自主程度 |
| [02-rules](docs/02-rules.md) | 用户定下的硬规则（只白嫖、不打印密钥、命名规范…） |
| [03-node-recipes](docs/03-node-recipes.md) | REALITY 直连 / WS+CF 隧道 / 优选 / IPv6-only 配方与验收 |
| [04-subscription](docs/04-subscription.md) | 订阅 Worker、分组、改动流程 |
| [05-nezha](docs/05-nezha.md) | 哪吒探针部署、gRPC 绕行、安全加固、API |
| [06-automation](docs/06-automation.md) | GitHub Actions、CF cron、定时任务、防回收 |
| [07-providers](docs/07-providers.md) | 各免费机平台的额度、坑、适用场景 |
| [08-handoff-checklist](docs/08-handoff-checklist.md) | 新 Agent 接手第一天要做的事 |

| 模板 | 用途 |
|---|---|
| `templates/install_reality_systemd.sh` | 公网 VPS：Xray REALITY + 哪吒 agent（经 cloudflared access）systemd 一键装 |
| `templates/panel_container_launcher.py` | 面板容器（Pterodactyl 类，单端口、无 systemd）启动器 |
| `templates/add_cf_tunnel_ws.sh` | 给已有机器加 WS inbound + 第二条 CF 隧道（优选变体） |
| `templates/run_watch.sh` | 无 systemd 容器的进程看门狗 |
| `templates/xray_ws_ipv6only.json` | IPv6-only 机器的 Xray 配置（UseIPv6 + DNS64） |
| `templates/worker_subscription.js` | 订阅 Worker：base64 / Clash YAML + url-test 组 |
| `templates/nodetest.sh` | 沙箱节点验收：出口归属、204 延迟、10 MB 速度 |
| `templates/github-actions/` | Oracle A1 抢机 workflow、CF cron 调度器 |

## 一页速览

**工作方式**：中文、简短、先结论；能查不问，能修直接修；花钱/注册/删机/改地址先问；"可以"=执行，"等等"=停。

**硬规矩**：只用免费档、永不绑卡；不在聊天里出现任何密钥；排队中的免费机每 30 分钟自己查、最多 10 次；改订阅先备份；REALITY 的 Clash 输出带 `support-x25519mlkem768: true`；建定时任务前先查重。

**标准流程**：

```
拿到机器 → 判断网络条件选配方 → 装 xray / cloudflared / nezha-agent
        → 沙箱验收（出口、204、速度、常用站）
        → 探针改名 → 备份订阅 → 加入 LINKS / Clash / PROXY / ⚡自动选择
        → 验证订阅输出 → 告诉用户刷新 → 写笔记（地址、服务、到期规则、坑）
        → 有到期/续期就排定时任务
```

**文档同步**：机器有任何变动，做完顺手更新私密交接仓库和本仓库（本仓库只收脱敏的通用经验），不用问。

**命名**：`<VPS商>-<地区中文> | <限额/不限/N天续期> | <电信延迟> | <速度>`，住宅 IP 加「家宽」。

## 用模板前

1. 把所有 `<SECRET>` / `<UUID>` / `<SUB_KEY>` / `example.com` 换成你自己的值（`xray uuid`、`xray x25519`、`openssl rand -hex 8`）。
2. 带密钥的成品脚本只放本地（`chmod 600`），不要提交。
3. 遵守各平台服务条款；本仓库仅作个人自用节点的运维记录。

## License

MIT
- [09 · 2026-11-27 经验汇总](docs/09-lessons-2026-11-27.md)
