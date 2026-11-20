---
title: Developer installation
---

## Native app

Use an Apple Silicon Mac with full Xcode selected. From the repository root:

```bash
./scripts/run-native.sh
```

This builds and opens the offline preview using the shared EchoPaw scheme.

## Docs site

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

Open the printed local address. The browser demo and docs run without Twitch, OpenAI or ElevenLabs credentials.
