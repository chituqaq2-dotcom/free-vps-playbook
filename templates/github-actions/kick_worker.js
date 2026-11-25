// Cloudflare Worker cron "*/30 * * * *": GitHub's own schedule fires only a few times a day,
// so this dispatches workflows reliably. Secret binding GH_TOKEN = fine-grained PAT (Actions: Read & write).
// Note: don't name a const "URL" (shadows the global). Keep secret bindings when redeploying.
const JOBS = [
  { repo: "<owner>/<repo-a>", wf: "refresh.yml", ref: "main" },
  { repo: "<owner>/<repo-b>", wf: "grab.yml", ref: "main", inputs: { mode: "a1" } },
];
export default {
  async scheduled(_e, env, ctx) {
    ctx.waitUntil(Promise.all(JOBS.map(j => fetch(
      `https://api.github.com/repos/${j.repo}/actions/workflows/${j.wf}/dispatches`, {
        method: "POST",
        headers: { authorization: `Bearer ${env.GH_TOKEN}`, accept: "application/vnd.github+json", "user-agent": "kick" },
        body: JSON.stringify({ ref: j.ref, inputs: j.inputs || {} }),
      }))));
  },
  async fetch() { return new Response("ok"); },
};
