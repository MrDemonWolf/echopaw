# Development handoff and proposed Jira breakdown

Updated November 18, 2026. Work from the [decisions](decisions.md), [risk matrix](../research/feasibility.md) and [roadmap](roadmap.md). This is a proposed Jira breakdown. Assign identifiers in the existing project when tickets are created.

## Epic outcome

An Apple Silicon streamer can privately preview a two-PNG mascot, record it in OBS with isolated sound, and stop it immediately. Enable the cloud-backed Twitch co-host only once the provider gates and live acceptance tests pass.

| Order | Proposed issue | Acceptance |
| --- | --- | --- |
| 1 | Validate signed mascot capture and audio on macOS 15 | Signed arm64 app launches, loads two fixture PNGs and drives their state from playback. Record OBS alpha or tested key-color fallback, separate game/mic/mascot audio and device-loss recovery. |
| 2 | Build an accessible offline Quick Start | Import or sample preview, device test, menu bar controls, emergency stop and explicit resume. Test keyboard-only flow and VoiceOver. |
| 3 | Build the bounded reaction scheduler and PackGuard contract | Replay deterministic events. Test dedup, prioritization, cooldowns, overflow, ambiguous use, cancellation and denial at final sinks. |
| 4 | Confirm Twitch and OpenAI public-use permissions | Record written policy disposition and permitted data flows. Confirm Twitch registrations without embedded secrets, and identify deletion and logging requirements. |
| 5 | Add Twitch Device Code Grant and local EventSub | Validate separate identities, least privilege, reconnect, event dedup and no moderator dependency. Add events in independently verifiable batches. |
| 6 | Add OpenAI and ElevenLabs adapters and enforce budgets | Validate model access, commercial voice rights, scoped Keychain access, first-audio latency, safe output and cost reservation. Depends on provider gates. |
| 7 | Validate stable release and updater | Name clearance, complete docs/screenshots, clean install and signed update, notarization, failure rejection, opt-in nightly and soak evidence. |
| 8 | Evaluate optional mic activity, keyword and deck controls | Confirm independent permissions, local activity privacy, PTT/manual alternatives, feedback and hardware stop. Split into separate issues before scheduling. |

## Implemented offline workspace

The working checkout now includes Dashboard, Character, Settings, the local wolf pack and the capture panel. Each service remains disconnected. A local permission-gated microphone can drive the mouth or detect a wake phrase. A detected phrase only shows a local confirmation. The release gates for PackGuard, provider policy and live scheduling still apply. See the [dated evidence and next hardware check](../research/native-preview-validation.md).

## First development slice

1. Use synthetic art and a local sound file. Capture independent observations for sprite transparency, separate software audio capture, physical output, BlackHole and unplug while playing.
2. Attach a short OBS recording plus a benchmark table with macOS and OBS versions, hardware, measured timings and failed routes. Use [audio routing](../architecture/audio-routing.md) and [native architecture](../architecture/native.md) for acceptance cases.
3. Keep software in rehearsal until the observed route and stop behavior are stable. No credentials or account connections are needed for the first spike.
