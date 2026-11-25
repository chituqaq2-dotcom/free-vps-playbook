# 06 · 自动化与保活

## 放在 GitHub Actions 的（不消耗 Agent 额度）
- 住宅代理池刷新：定时挑选节点（proxy/hosting 双 false、稳定 IP、204 通、速度过最低线），写进 Cloudflare KV，订阅 Worker 读 KV。
- Oracle A1 抢机：`templates/github-actions/grab.yml`；容量不足视为成功退出，抢到后开 issue 并 @用户（邮件通知取决于用户的 GitHub 通知设置）。
- GitHub schedule 很不可靠（一天只触发几次）→ 用 `templates/github-actions/kick_worker.js`（CF Worker cron `*/30`）调用 workflow_dispatch 兜底。
- PAT 用细粒度（只勾需要的仓库，Actions 读写）。

## 放在 Agent 定时任务的
- 需要浏览器登录面板的：续期点击、宕机后点 Start、web console 里跑启动脚本。
- 写法：在线/没事就**安静结束**不发消息；只有修好了或修不好才告诉用户。
- 续期按钮还没出现：建一个次日的一次性任务顺延，直到截止前一天；截止前还不行就告诉用户。
- 点击失败：每 30 分钟重试，最多 10 次。

## 防回收
- Oracle Always Free 空闲回收：跑一个低优先级 keepbusy（CPU 占用维持在阈值以上）+ BBR。
- 按 CPU 时长计费的免费容器：探针和服务监控间隔放宽，避免把额度烧光。
- 面板类机器：Worker cron 每天访问一次其公开地址保活。
