# Optional Stream Deck control

Research checked 2026-11-18. Ship keyboard commands and menu-bar controls in the native app first. The separate TypeScript plugin is a later slice in `apps/streamdeck`. Elgato's current SDK getting-started guide uses Node.js 24+ and Stream Deck 7.1+. Build and test with Bun where compatible, bundle JavaScript targeting the Node runtime owned by Stream Deck. Recheck versions and the manifest schema when the plugin starts. [Elgato SDK setup](https://docs.elgato.com/streamdeck/sdk/introduction/getting-started/), [Manifest](https://docs.elgato.com/streamdeck/sdk/references/manifest/).

## Controls

| Action | Required behavior |
| --- | --- |
| Speech mute | Stop active playback and cancel pending voice work. Display confirmed app mute state. Explicit unmute never replays an interrupted item. |
| AI responses | Pause generation and cancel pending AI work. Keep app safety protections and local controls active. |
| Microphone listening | Show active policy and toggle a previously authorized local mode. Native UI owns initial opt-in, mode selection and permissions. |
| Push-to-talk | Begin on key down, release on key up. App enforces the microphone timeout and cancels on disconnect, hidden action, suspend or lost release. |
| Manual reaction | Trigger a named configured animation or reaction through the native scheduler. |
| Reaction mode | Choose Quiet, Balanced, Chatty or Chaos. Stream Deck settings may bind each key to a mode. |
| Expression and outfit | Select by stable ID. Disable a choice that is unavailable in the current pack. |
| Emergency stop | One press immediately stops speech, generation and listening and clears the queue. Resume is an explicit native action. |
| Connection state | Show ready, app closed/disconnected, integration disabled, incompatible version or rejected connection. Show text or a distinct icon with any color changes. |

All controls dispatch the same app commands as SwiftUI and the menu bar, through the same PackGuard, session-arm and output checks. Use an idempotent set command for binary states. Start with mute, stop, pause AI and a status key. Add PTT only after the native mic contract passes missing-release tests. [Elgato actions](https://docs.elgato.com/streamdeck/sdk/guides/actions/), [key events and images](https://docs.elgato.com/streamdeck/sdk/guides/keys/).

## IPC proposal

Use one shared Unix domain socket for the plugin on the same Mac. The native app listens only while the user has enabled local controls. Publish its short socket path through a user-owned discovery file outside any export. Create the socket under a private mode-0700 directory, restrict its socket and discovery file permissions, reject invalid owner/type and validate the connecting UID with peer credentials. Check the path length before binding and recover stale same-owner sockets without replacing a live listener. This design authorizes the current macOS account's processes to send a narrow set of local controls while enabled. It provides no authentication of individual same-user processes. App Sandbox compatibility is a signed-app prototype gate. If a stronger pairing boundary is needed, add an explicitly paired control-only token outside Elgato profiles/settings exports. Keep provider keys and Twitch login outside the plugin entirely. [Node net IPC](https://nodejs.org/docs/latest-v24.x/api/net.html#ipc-support), [Apple peer credentials](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/getpeereid.3.html), [Apple App Sandbox](https://developer.apple.com/documentation/security/app-sandbox).

Use newline-delimited UTF-8 JSON with an initial version exchange, command IDs echoed in responses, bounded 4 KiB frames and typed argument validation. Reject messages before action dispatch when policy fails. Send one redacted app snapshot on connect, then snapshots on relevant state changes. Snapshots may include revisions, mode, mute, AI pause, listening and allowed character choices. Exclude chat, audio, credentials and viewer data. Cap bad input and client rates. Disconnect lagging clients and reconnect with bounded backoff and jitter. Never replay stale key presses. Deduplicate duplicate command IDs during a live connection and clear client state when that connection ends.

WolfWave checkout reviewed at `2a9629d4`. Reuse the convention of a pure wire parser/reducer, one shared transport, manifest validation, connection-driven key art, and fresh state on reconnect. WolfWave uses a loopback-authenticated WebSocket with distinct OBS and control credentials. EchoPaw needs only same-machine desktop controls and can spike local IPC without opening a TCP listener. Add request IDs so simultaneous same-action presses correlate directly. [WolfWave app contract](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/docs/streamdeck-control-api.md), [WolfWave plugin](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/streamdeck/README.md).

## Packaging and acceptance

Use a Mac-only manifest and compare keys at 72 px and 144 px. EchoPaw's brand forbids pure white, while Elgato requires it on action-list glyphs. Confirm an accepted platform-specific treatment with the owner before Marketplace submission. Package with `streamdeck validate` and `streamdeck pack`. Keep compiled bundles out of source control. [Elgato plugin art requirements](https://docs.elgato.com/streamdeck/sdk/style-guide/plugin-guidelines/), [Elgato distribution](https://docs.elgato.com/streamdeck/sdk/introduction/distribution/).

- [ ] Contract fixtures cover unknown commands, invalid arguments, unsupported version, oversized frames, disabled control and duplicate IDs.
- [ ] A real device validates reconnect, app quit/restart, profile switch, stale ack, status images and no unintended replays. PTT ends even if the device vanishes on key down.
- [ ] Dashboard and keyboard controls work when the device and integration are absent. Require a permission and focus test before offering optional global shortcuts.
- [ ] Confirm live stop latency, listening consent and that exported profiles contain no credentials. No plugin, package or hardware testing exists yet.
