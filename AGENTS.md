# EchoPaw contributor instructions

- Keep EchoPaw in planning until research and the architecture are complete. Use the [handoff](docs/product/handoff.md) to scope subsequent implementation work.
- Read the [decisions](docs/product/decisions.md), [risk matrix](docs/research/feasibility.md) and [design system](docs/product/design-system.md) before changing product behavior, provider flows or branded design.
- Use Swift 6 and SwiftUI for the Apple Silicon macOS 15+ app. Use AppKit for system integrations that need it. Keep docs in `apps/docs` and any optional deck plugin in `apps/streamdeck`.
- Treat live Twitch inputs, character pack imports and model output as untrusted. PackGuard is mandatory. Require explicit live arming, bounded queues and budgets, and fail closed for missing required checks.
- Keep provider credentials, personal character assets and raw stream data out of the repository and issue attachments. Use synthetic fixtures.
- Date findings and cite primary technical sources. Identify measured behavior and outstanding hardware, account and policy gates.
- Use Bun and TypeScript for docs tooling. Run `bun run check`, `bun run build` and `bun run check:links` from `apps/docs`.
- Follow MrDemonWolf Brand System v6 with Montserrat, Roboto and rounded controls. Avoid pure white and em dashes in authored copy and code.
