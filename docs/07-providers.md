# 07 · 免费机平台笔记（截至 2026-11）

| 平台 | 免费档 | 适合 | 注意 |
|---|---|---|---|
| Oracle Cloud | E2.1.Micro ×2（1/8 OCPU、1 GB）；A1 共 2 OCPU/12 GB；200 GB 块存储 | 主力节点 | 东京等热门区 A1 长期没容量，靠 Actions 抢；Ubuntu iptables 默认挡端口；空闲回收 |
| Altare | 每团队 6 GB/150% CPU/10 GB，最多 2 个团队 | 大内存容器 | 条款禁公开代理；节点常 "No capacity"/"Node down"；proot 无 systemd；单端口（可占为 REALITY） |
| Cloady | 0.5 vCPU/1 GB，10 GB 流量 + 4 CPU-h/月 | 小备用节点、跳板（有 IPv6） | 无公网入站，只能走 CF 隧道；exec API 约 110 s 超时；重部署会丢 apk 安装 |
| PlutoByte | 0.5 GiB/50% CPU/2 GB，1 槽 | 小 REALITY 节点 | **每 7 天手动续期**（剩 24 h 才出按钮），过期停机不删；Google 登录+手机确认，难自动化；域名可疑 |
| Nodaroo | 小容器 | 备用 | 线路慢 |
| ASCS Cloud | E5-2650v0 1 核、实际 256 MB、16 GB，IPv6-only LXC | CF 隧道节点、cron、bot | **每 30 天点免费层确认**；会自己停机；web 终端无法粘贴 |
| URnetwork | 免费账号 1 个活跃住宅 socks | 家宽出口（解锁/风控） | 速度一般，节点会掉，靠 Actions 轮换 |
| InstaBox 等 microVM | 4C/8G，空闲暂停，最长运行数小时 | 编译/打包 | 条款禁代理，有封号报告——别做节点 |

经验：
- 没有就排队等，不要为了"有"去绑卡。
- 面板 web 终端里浏览器 Agent 往往无法自动填密码；改密码的 JS prompt() 填不了时，命令可能其实生效了，先 SSH 验证。
- 出口 IP 的地理库可能和机房不符（例如美国机房出口被谷歌判成澳洲），可向 Google 提交 IP 位置更正。
