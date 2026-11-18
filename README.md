# EchoPaw - A Streaming Mascot for Mac

EchoPaw is a planned open-source macOS utility for streamers who want a PNG
mascot that can speak and react to Twitch events. The project is in research
and planning. The documentation and browser prototype are available in this
checkout.

## Planned features

- **Two-image mascot** with an offline preview and optional expressions.
- **OBS routing** with System Default output and optional device selection.
- **Balanced reactions** with separately connected Twitch identities.
- **OpenAI and ElevenLabs** using user-owned keys, with PackGuard and budgets.
- **Streamer controls** for mute, pause and emergency stop.

## Getting started

1. Read the [planning index](docs/README.md) for architecture and open gates.
2. Run the docs site to try the browser prototype and cost calculator.
3. Follow the [development handoff](docs/product/handoff.md) for the first native validation slice.

## Tech stack

| Layer | Technology |
| --- | --- |
| Planned desktop app | Swift 6, SwiftUI, AppKit where needed, Apple Silicon macOS 15+ |
| Docs and prototype | Astro, Starlight, TypeScript and Bun |
| Planned integrations | Twitch, OBS, OpenAI, ElevenLabs, Sparkle and optional Stream Deck |

## Development

Use Bun 1.4.4 and Node.js 22.23.4 or later, as required by the pinned Astro
version. From the repository root:

```bash
cd apps/docs
bun install --frozen-lockfile
bun run dev
```

`bun run check` type-checks the docs. `bun run build` builds the static site.
Run `bun run check:links` afterward to verify generated internal links and the
calculator examples. See [contributing](CONTRIBUTING.md) for the workflow.

## Project structure

```text
apps/native/      Native architecture entry point
apps/docs/        Static website and browser prototype
apps/streamdeck/  Optional plugin plan
assets/           Brand assets, icon source and previews
design-system/    Shared design tokens and visual conventions
docs/             Research, design, architecture and legal drafts
```

## License

[![GitHub license](https://img.shields.io/github/license/MrDemonWolf/echopaw.svg?style=for-the-badge&logo=github)](LICENSE)

EchoPaw is licensed under [GPL-3.0](LICENSE). See [third-party
disclosures](docs/legal/third-party.md) for service and asset terms.

## Contact

- Project questions and feedback go to [GitHub Issues](https://github.com/MrDemonWolf/echopaw/issues) or [Discord](https://mrdwolf.net/discord).
- Report security concerns using the [security policy](SECURITY.md).

Made with love by [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)
