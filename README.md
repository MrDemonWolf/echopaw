# EchoPaw - A Streaming Mascot for Mac

EchoPaw is an open-source macOS utility for streamers building a speaking
PNG mascot. The current build lets you rehearse offline, try your character
art and check the dedicated mascot window in OBS.

## Features

- **Character preview** with a blinking starter wolf and two-PNG import.
- **Audio rehearsal** with a bundled spoken line and output device selection.
- **Mascot window** for OBS with speech mute and emergency stop in EchoPaw.
- **Connection settings** for checking provider keys and authorizing separate
  Twitch broadcaster and bot accounts.

Live conversation, viewer reactions and Stream Deck controls are on the
[pilot checklist](docs/product/next-steps.md).

## Getting started

1. [Build and run the native preview](apps/native/README.md) on an Apple Silicon Mac.
2. Read the [planning index](docs/README.md) for architecture and open gates.
3. Run the docs site to try the browser prototype and cost calculator.

## Tech stack

| Layer | Technology |
| --- | --- |
| Desktop app | Swift 6, SwiftUI, AppKit for the capture window, Apple Silicon macOS 15+ |
| Docs and prototype | Astro, Starlight, TypeScript and Bun |

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
apps/native/      Xcode project, Swift app and tests
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
