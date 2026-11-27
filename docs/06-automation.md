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

## 补充（2026-11）
- GitHub Actions 带 `concurrency` 组的长循环 workflow：后续 dispatch 显示 cancelled/pending 是排队被挤掉，**不是故障**；看有没有一条 in_progress 即可。
- 住宅代理池：免费档常只允许 1 个活跃代理，池子空时 workflow 会失败并给用户发“All jobs have failed”邮件，下一轮有候选过检就自愈。检测太严（例如 IP 查询要求 3/3 成功）会让抖动的住宅节点全部落选，可放宽到 2/3，其余条件（住宅、无代理标记、204、最低速度）不放。池子空时不发布，订阅会暂时留着死节点。
- 平台的“免费建机暂停/缺货”用低频定时任务轮询（30 分钟～2 小时），没变化就静默；任务里写清用户事先授权到哪一步（例如恢复后可直接加入平台社群并建机）。
