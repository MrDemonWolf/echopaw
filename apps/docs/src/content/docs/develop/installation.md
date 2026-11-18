---
title: Developer installation
---

Install [Bun](https://bun.sh/) and the Node version required by the pinned Astro release. From your checkout:

```bash
cd apps/docs
bun install --frozen-lockfile
bun run dev
```

To validate the static build:

```bash
bun run check
bun run build
bun run check:links
```

Open the printed local address. The browser demo and docs run without Twitch, OpenAI or ElevenLabs credentials. Native development and Stream Deck packaging begin after the planning gates.
