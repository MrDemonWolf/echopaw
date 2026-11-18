# First-time setup

Research reviewed 2026-11-18. This is a prototype specification. Offer **Quick Start** and **Advanced Setup**. Both start in Preview. Preview simulations never post to Twitch, synthesize with cloud services, or broadcast. A separate explicit provider test can use a key and incur usage. Starting an EchoPaw session enables the selected integrations, while OBS controls recording and broadcasting.

## Quick Start

Five minutes is a usability target from an installed app to a successful local preview. Test it with first-time streamers.

| Step | Action and purpose | Recovery |
| --- | --- | --- |
| 1 of 3 · Choose a character | Open the sample or choose a folder with `idle.png` and `talking.png`. Show both states before continuing. | Keep the picker open and name a missing, invalid, or mismatched image. Offer **Use sample** and **Choose another folder**. |
| 2 of 3 · Try a reaction | **Preview reaction** alternates idle and talking art with a fixed on-screen line. **Test output** is a separate local fixed-clip action at a low level. Start on **System Default**. | Show the detected output and let the user retry the local clip or finish with silent preview. |
| 3 of 3 · Finish | Open Dashboard in Preview with the mascot visible, Balanced selected, and microphone off. Offer a link to set up streaming later. | Recover the last valid character and in-progress setup on restart. |

Use small progress text with the current step title, one primary action, Back and Cancel. Keep untouched services under **Advanced Setup**. Show an accessible explanation that the overlay and local audio are only going to this Mac. When capture verification differs, explicitly state that OBS is a separate app and may already be capturing.

## Advanced Setup

An individually skippable checklist holds progress even if the user closes the window. Select one area at a time. Each section has its own **Try**, **Retry**, and **Done** controls. Statuses use **Ready**, **Skipped**, **Needs attention**, or **Verifying…** with readable text.

| Area | Default and reason | Error and recovery |
| --- | --- | --- |
| Character | Start with two matching PNGs. Extras appear only once core states pass preview. | Preserve the last valid pack and show which file to correct. Offer numeric placement and reset. |
| Voice & AI | Connect separately. Show where provider data goes, which actions can cost money, selected model, license status, and an explicit local-only alternative. Ask whether the intended output is monetized. | Keep pasted keys masked. Invalid key offers Replace key. Rate limit shows when retry is available. Unsupported or unlicensed selections stay unavailable with a direct explanation. |
| Twitch | Connect broadcaster and bot on separate rows. Explain scopes on the relevant feature only. Keep Twitch-to-cloud gated pending provider and platform clearance. | Show the authenticated identity before confirming. An expired code offers **Get a new code**. A mismatch offers **Switch account**. Passive authorization never posts chat. |
| OBS and Audio Output | Use separate capture and sound checks. System Default with verified OBS per-app capture is the simple starting route. | Show which app needs the macOS permission. Offer a one-source recording check for missing or doubled audio, and the advanced virtual route only when needed. |
| Reactions and PackGuard | Balanced and PG-13. Preview a mention and a redeem using safe fixtures. Explain why a moderation failure silences output. | Link the blocked action to a safe decision reason and offer a canned demo or silent animation without exposing rejected input. |
| Microphone | Activity and keyword listening both off. Ask only on the explicit toggle. Preview the local input level and allow push-to-talk where available. | Denied access links to System Settings. Lost hardware shows **Microphone disconnected** and pauses that feature. A missing keyword backend leaves the listening mode unavailable. |
| Stream Deck | Optional connection after core setup. Keep controls usable with native menus and keyboard. | Show disconnected state and connection instructions. Failure never changes a streaming control. |
| Review | Show Preview, credentials status, selected sound route, budget and **Emergency stop**. Optionally test in a local OBS recording. | Each incomplete requirement links back to its exact setting. Live remains inactive until separately armed. |

Example recovery copy:

- **Twitch code expired.** Get a new code to continue. Your character and audio settings are saved.
- **Microphone access is off.** Enable EchoPaw in System Settings to use voice reactions. You can continue without a microphone.
- **Headphones disconnected.** Speech is paused. Reconnect your headphones or choose another output.
- **Safety check unavailable.** Speech and chat responses are paused. You can still preview character states.

## Acceptance checks

- [ ] Fresh install reaches a sample preview without network access, credentials, microphone permission or a virtual driver.
- [ ] Keyboard-only users can complete and leave both paths. VoiceOver identifies step, purpose, focused field, result, and next action.
- [ ] Simulate button, local clip test, provider test, and actual send have separate labels and permissions. Simulated tests have no outgoing writes.
- [ ] Go back from every step without re-prompting for a granted permission or rerunning a paid test.
- [ ] When focus returns from a browser or System Settings, restore the initiating control and announce a useful status update. Avoid repeated announcements from meters.
- [ ] Test clean install, returning user, canceled sign-in, invalid/missing assets, denied mic permission, voice licensing block, wrong OBS source and disconnected output. Keep the local preview usable.
- [ ] Prototype observation with three to five first-time streamers. Record time to preview, tasks requiring help and first recovery success. The time target remains unmeasured.

## Reference patterns

- Life Reset’s iOS walkthrough uses one prompt per page and a persistent progress treatment. Use a compact macOS step label and native buttons. [Mobbin flow](https://mobbin.com/flows/e91bc9a4-db92-449a-8de2-2d5e81381f6b?tab=screens)
- Canva’s web connected apps use one row per service with actions attached to the row. Show broadcaster, bot, OpenAI and ElevenLabs as separately actionable connections. [Mobbin screen](https://mobbin.com/screens/d6790bb0-b827-473a-9991-526c3f4b03f3)
- Quo’s web audio settings place an input meter under its device and Test audio next to the speaker picker. Pair each EchoPaw test with its own source or destination. [Mobbin screen](https://mobbin.com/screens/f99800d4-e789-47a8-8d2f-2a2aa8d75365)
- Flo’s iOS customization shows selected choices immediately. EchoPaw’s character inspector should update its own preview when safe and show the current selection in text. [Mobbin screen](https://mobbin.com/screens/11d4818e-5e46-4e2f-a821-03fd44f06761)
- CapCut’s iOS prompt puts purpose next to the choice. Adopt the timing and plain explanation, with an explicit cancel before the real macOS prompt. [Mobbin screen](https://mobbin.com/screens/a42c5955-a17e-4abd-80e9-db05b8401273)
- Steep’s web settings show a retry action in the failed connection panel. Keep EchoPaw’s next step similarly close, with sanitized details. [Mobbin screen](https://mobbin.com/screens/c70f80de-5c92-4044-b3b5-b44b819647b9)
- Contra’s web settings show a preview alongside the setting it affects. Adopt paired preview and control placement in Character and The Brain using native layout. [Mobbin screen](https://mobbin.com/screens/bdb59499-1ae4-46dc-8a25-9de7be5e2a71)

[Apple designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) · [Mac media capture authorization](https://developer.apple.com/documentation/bundleresources/requesting-authorization-for-media-capture-on-macos) · [Apple privacy guidance](https://developer.apple.com/design/human-interface-guidelines/privacy) · [Screen map](screen-map.md)
