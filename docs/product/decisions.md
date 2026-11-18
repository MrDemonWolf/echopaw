# Decisions and open questions

Status reviewed November 18, 2026. The project brief and its three project pages are the product sources. This register captures public decisions and research changes. The personal character, voice design and stream information are maintained outside the public repository.

## Locked

- Swift 6, SwiftUI and Apple Silicon macOS 15+. Use AppKit for capture-window behavior where needed.
- Public GitHub and GPL-3.0. Free and open source initially. Signed and notarized DMG with Sparkle updates.
- OpenAI cloud LLM only. GPT-6 Luna is the default when available, with OpenAI model selection. ElevenLabs is the preferred TTS provider with user-owned keys held in Keychain. No required EchoPaw service account, mandatory backend or local LLM.
- Twitch primary, with distinct broadcaster and user-controlled bot credentials. OBS is the primary broadcast target. Balanced and always-on PackGuard are defaults, with PG-13 as the default rating.
- Require idle and talking PNGs for a talking character. Other states, microphone features, viewer memory and Stream Deck are optional. Default audio route is System Default. Support explicit output selection.
- EchoPaw stays a working name. Follow MrDemonWolf Brand System v6. The creator's personal character remains separate from the app icon and any public sample art.

## Proposed for the first build

- Start with one app and one test target. Validate render and audio in a signed test build before adding provider connections.
- Primary OBS path is a capture window plus per-app audio. Use an explicit color-key fallback only after testing it. If a specific output disappears, stop the current item and ask the streamer to confirm a replacement before resuming.
- Enable public provider features only after policy confirmation. While gated, keep safe local preview, synthetic scenarios and local Twitch event animations where authorized.
- Use an Astro and Starlight static docs site with Bun and TypeScript. This matches the Better-T Stack Astro/Starlight choices without generating an unused application stack. Keep website code independent of the Swift app.
- Start with native in-app keyboard controls and reserve deck actions for an optional plugin. Begin with local-only mic activity after core streaming and audio validation. Treat keyword listening as an independent milestone.
- Reserve durable viewer memory for later, where opt-in, deletion and third-party terms can be tested. Use small settings storage and introduce transactional storage only as needed.

## Decisions still open

| Decision | Evidence to close it |
| --- | --- |
| Final app name, icon and identifiers | Search similar marks in launch markets, review overlap, then approve the name and rendered icon. [Naming](../research/naming.md). |
| Twitch data in third-party providers | Confirm written scope under the Twitch Developer Services Agreement before sharing upstream data or derived text. Scope viewer memory, retention and downstream deletion. |
| Public OpenAI desktop BYOK | Confirm the proposed local user-owned key flow is compatible with provider policy. Confirm account access to Responses and moderation, and distribution controls. |
| OBS alpha and device-loss recovery | Record evidence on macOS 15 and a current macOS release. Check capture and routing at normal stream load. |
| Voice plan, model and rights | Confirm actual account entitlement, compatible voice and broadcast license. Check metering and format support before choosing the production profile. |
| Controls, speech and IPC | Verify VoiceOver, reduced motion and background shortcuts. Prove local wake reliability, then test Elgato hardware and packaging before promising it. |

See the [risk matrix](../research/feasibility.md) for release gates and the [roadmap](roadmap.md) for sequencing.
