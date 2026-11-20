# Competitive review of the first stream

November 20, 2026. Compared first-party guides, published screenshots and release artifacts with EchoPaw’s current SwiftUI code, setup screens and recorded preview evidence. Competitor findings describe published workflows. This review did not run competing apps or benchmark their performance.

## What others already do well

| Product | What a streamer gets | Lesson for EchoPaw |
| --- | --- | --- |
| **PixelyChat Companion** | Free app with Intel and Apple Silicon support. Its 2D companion has a dedicated OBS browser source, voice preview, selectable reactions and optional ElevenLabs. Its custom-pack guide asks for five matching images. | The closest peer. The published screen puts the visible on-stream result above identity and display settings. Lead with the wolf speaking and keep the two-PNG import. [Product](https://www.pixelychat.com/) · [Companion manual](https://www.pixelychat.com/manual/companion) · [Published screen](https://www.pixelychat.com/news/companion) · [Mac install](https://www.pixelychat.com/manual/install) |
| **LivLiv Stage** | v0.5.0 lists arm64 and Intel Mac installers. Its broader studio offers ready-to-use characters, Twitch chat, OBS output, voice conversations and tracking. | A polished talking character on a Mac already has alternatives. Focus EchoPaw on quick setup and a small set of controls a streamer can use mid-show. [Project](https://github.com/livliv-dev/stage) · [v0.5.0 release](https://github.com/livliv-dev/stage/releases/tag/v0.5.0) |
| **OpenCohost Kira** | The free Windows beta documents short queued turns, interruption and failure recovery. | Queueing and a Stop button are baseline co-host features. Make the reason for silence visible and demonstrate a predictable recovery. [Product and edited runtime demo](https://www.opencohost.com/) |
| **StreamTracker** | Its guided setup starts with a sample and calls for a test followed by manual confirmation in OBS. It reports whether an output is polling separately from broadcast status. | Adopt the visible or audible confirmation step. EchoPaw can report the mascot window and selected audio route locally and ask the streamer to confirm what reached OBS. [Setup guide](https://streamtracker.cloud/help/ai-cohost-setup) |
| **veadotube mini** | Two images can drive a basic reactive avatar. Its macOS OBS guide gives a Syphon route and window capture alternatives. | Two images are familiar to PNGTuber users. EchoPaw’s advantage over a separate avatar utility depends on how reliably it connects rehearsal, behavior and output. [Avatar guide](https://veado.tube/docs/usage/mini/) · [OBS guide](https://veado.tube/docs/usage/obs/) |

In a CHI 2026 study of 1,891 YouTube comments about Neuro-sama, viewers discussed the character’s distinctive personality and interaction with the human creator. The same study identified moderation challenges. Based on that one community, a worthwhile test for EchoPaw is whether a short, recognizable line at the right moment feels like a character. [Hu and Freeman, CHI 2026](https://doi.org/10.1145/3772318.3791077)

## Feedback on the current app

1. **The first click undersells the wolf.** The starter art reads clearly, and the dedicated capture panel keeps the sprite by itself. The large preview makes the app feel like an avatar viewer. The primary **Preview talking** button plays a tone, so it demonstrates mouth movement without showing how the character will sound on stream. Give it one short bundled spoken line. Put **Rehearse**, the current audio destination, and a labeled **Show mascot window** control together below the wolf. Keep that row within reach in a compact window. Keep the background-free capture and native Character inspector. [Dashboard capture](../onboarding/screenshots/native-workspace.png)
2. **The dashboard mixes rehearsal with future live controls.** **Resume AI** is clickable in the offline preview and changes a local preference. Saved keys and validated Twitch identities are useful setup milestones. Live event input, generated speech and automatic chat output are still pending. Keep key entry and broadcaster/bot setup in Settings and surface the next action on the Dashboard. Introduce live controls when they have an output to operate.
3. **Show what OBS actually received.** A visible mascot panel tells us EchoPaw opened its output. Let the streamer confirm the wolf and a moving mascot audio meter in an OBS test scene. The existing recording demonstrates transparent video in one Mac/OBS configuration with silent sources. OBS can also carry audio through its screen source, so the guide should specify which one path carries the mascot and how to spot duplication. [EchoPaw capture evidence](native-preview-validation.md) · [OBS audio capture guide](https://obsproject.com/kb/macos-desktop-audio-capture-guide)
4. **Make quiet behavior easy to read.** The current action history records actions such as mute and stop. As the planned scheduler arrives, explain the last event with a short reason such as **Played**, **Skipped · cooldown** or **Canceled · stopped**. Start with one manual demo and a simulated mention plus a repeat. Exercise Stop while a reply is playing or queued. The current stop hides the mascot panel, so test source recovery in OBS before choosing whether to leave the panel available with its sprite blanked. [Scheduler draft](../architecture/reaction-scheduler.md) · [Streamer.bot actions and queues](https://docs.streamer.bot/guide/core/actions#action-queues)

## Recommended next slice

**Rehearse with the starter wolf → play a short bundled line → confirm picture and sound in OBS → stop and resume deliberately.** Run the first version without a Twitch login or provider key. Use an OBS test scene for the output check, since an active OBS scene can transmit local rehearsal sound.

Proposed acceptance targets for a first-user check:

- A new user gets a recognizable spoken line and sees the wolf react within 60 seconds of opening the app.
- In five minutes, the user can add the wolf to an OBS test scene and make a local recording with distinct game, mic and mascot audio.
- Three stop-and-resume cycles produce silence while stopped, no stale utterance after resume, and a known OBS source recovery path. Check the macOS 15 floor as well as the current macOS release.

Positioning hypothesis: **a small Mac mascot for OBS that you can rehearse before you go live.** Free software is a baseline alongside PixelyChat and OpenCohost. Keep the account-free demo free to run and show metered provider usage when paid speech and generation become available. A reliable rehearsal earns more trust at this stage than a wardrobe, 3D rigs or scene automation.
