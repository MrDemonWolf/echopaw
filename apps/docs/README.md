# EchoPaw documentation site

Astro and Starlight generate a static website. Better-T Stack supports Astro
and Starlight as frontend and docs choices. This project uses those pieces
directly and keeps the website independent from the native app. Bun installs
and runs the tooling. The pinned Astro release requires Node.js 22.23.4 or
later. [Better-T Stack options](https://www.better-t-stack.dev/docs),
[Starlight setup](https://starlight.astro.build/getting-started/).

```bash
bun install --frozen-lockfile
bun run dev
bun run check
bun run build
bun run check:links
```

Content is organized inside `src/content/docs`. The calculator and interface
prototype are browser-only. Fonts are bundled locally. Update setup commands
and screenshots when native behavior is verified.

## Deployment plan

The intended domain is `echopaw.mrdemonwolf.dev`. On November 18, 2026, it
resolved to the same Cloudflare addresses as a separate probe hostname.
Confirm the exact record, owning zone, project binding and current response
before deployment. The proposed Cloudflare Pages
build uses `apps/docs` as its root, `bun run build` as the build command and
`dist` as the output directory. Pin the matching Bun and Node versions,
verify a preview, confirm the configured canonical site URL and verify HTTPS.
[Cloudflare Pages Astro guide](https://developers.cloudflare.com/pages/framework-guides/deploy-an-astro-site/).
