import assert from "node:assert/strict";
import { estimateCost } from "../src/components/estimate";

const baseline = {
  replies: 300, inputTokens: 900, outputTokens: 80, spokenCharacters: 120,
  inputPrice: 0.10, outputPrice: 0.50, speechPrice: 0.04,
};
assert.equal(estimateCost(baseline)?.total.toFixed(2), "1.48");
assert.equal(estimateCost({ ...baseline, replies: 0 })?.total, 0);
assert.equal(estimateCost({ ...baseline, replies: -1 }), null);

const pages = new Map<string, string>();
for await (const path of new Bun.Glob("**/*.html").scan("dist")) {
  const route = "/" + path.replace(/(^|\/)index\.html$/, "$1");
  pages.set(route, await Bun.file("dist/" + path).text());
}
assert(pages.has("/"), "Build the docs before checking links.");
const failures = [];

for (const [route, html] of pages) {
  for (const [, href] of html.matchAll(/<a\s[^>]*?\bhref="([^"]+)"/g)) {
    const url = new URL(href, "https://docs.test" + route);
    if (url.origin !== "https://docs.test") continue;
    const target = pages.get(url.pathname) ?? pages.get(url.pathname + "/");
    if (!target || (url.hash && !target.includes(`id="${decodeURIComponent(url.hash.slice(1))}"`))) {
      failures.push(`${route} → ${href}`);
    }
  }
}
assert.equal(failures.length, 0, `Broken links:\n${failures.join("\n")}`);
console.log(`Checked internal links across ${pages.size} pages and verified calculator examples.`);
