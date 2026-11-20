# EchoPaw setup and product checklist

Reviewed November 20, 2026. The first onboarding win is to hear the wolf and check it in OBS. Credentials and live reactions follow from that working path. The estimates below are test targets. [Competitive workflow research](../research/competitive-workflows.md)

## What to borrow from WolfWave

I reviewed WolfWave at commit `2a9629d4`. The wizard keeps the progress header and footer in place, scrolls the step content, and gives each step one brief purpose. Explicit **Skip setup** leads to a shorter completion screen. A shared Twitch editor keeps the account state consistent between Settings and onboarding. When the code is visible, the user sees the sign-in task and its recovery actions. Leaving a presentation cancels that presentation’s sign-in. [Wizard source](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/WolfWave/Views/Onboarding/OnboardingView.swift) · [Step scaffold](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/design-system/components/onboarding-step-scaffold.md) · [Device code view](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/WolfWave/Views/Twitch/DeviceCodeView.swift)

EchoPaw has a starter wolf, two-PNG import, a local audio test, a dedicated OBS capture window and separate account screens. The first Setup Guide uses the current audio test. A spoken local clip will make the first step demonstrate the character’s voice as well as its mouth movement. [Native app](../../apps/native/README.md) · [Onboarding spec](../onboarding/setup.md)

## First-run flow

| Screen | What the user does | Recovery or exit |
| --- | --- | --- |
| **Try your mascot** | See the wolf, choose an output and play the bundled sample line. | Change the output and retry in place. Use the starter wolf if a custom import failed. Custom packs belong in Character when the user wants them. |
| **Check your OBS output** | **Show mascot window** names the exact OBS source to select. Play one clip in an OBS test scene and confirm that you can see and hear it. | Skip OBS to finish quickly or use **Set up later** to resume this step. Add more targeted recovery for missing or doubled audio after recording the behavior. |
| **Connect accounts when ready** | Open the shared API Keys or Twitch settings, or choose **Done** to go back to rehearsing. | Retain normal settings and keep live output disarmed. Show the output destination and emergency stop shortcut on the Dashboard. |

Keep **Back** and **Set up later** in a stable footer, show compact step progress, and announce the step heading. Offer the guide once on first launch and let **Help > Setup Guide** resume an unfinished walkthrough. Preserve preferences. On close or quit, clear draft secrets and cancel the attempt owned by that presentation. Set a minimum usable window size, leave fullscreen disabled, and keep the preview background-free. [Apple onboarding guidance](https://developer.apple.com/design/human-interface-guidelines/onboarding) · [EchoPaw design system](design-system.md)

## Optional setup checklist

| Card | User action | What success means |
| --- | --- | --- |
| **OpenAI** | Follow a provider link for a project key with read access to Models. Paste it into the masked field and choose **Check and save**. | The provider accepted the read-only check and the key was stored in macOS Keychain. Response generation and moderation require their own release checks. |
| **ElevenLabs** | Create a restricted key with Voices read access. Choose **Check and save**. | The read-only check passed and Keychain storage succeeded. Voice entitlement, synthesis and commercial rights have their own later checks. |
| **Twitch broadcaster** | Use **Connect broadcaster** and sign in as the account that owns the channel. | Twitch confirmed the broadcaster login. Surface the verified account name and what that connection permits. |
| **Twitch bot** | Use **Connect bot** and authorize a different Twitch user. | Twitch confirmed a different login with the requested read-only chat scope. Add chat send permission later only for a feature the user enables. |
| **Audio and OBS** | Inspect the chosen route, retest the mascot window and check the mixer. | The streamer has explicitly confirmed picture and one copy of the audio in a test scene. |

Both setup and Settings should share the existing account models and editors. Each card has a clear state such as **Not set up**, **Checking…**, **Verified and saved**, **Connected as [name]**, or **Needs attention**. Use the saved-key state for entries that predate verification. Reserve **Live ready** for when the account, permission and output checks pass.

### Key and sign-in behavior

- [x] Make **Check and save** an explicit network action. Use `GET https://api.openai.com/v1/models` with the Models read permission and `GET https://api.elevenlabs.io/v2/voices?page_size=1` with Voices read access. Send the candidate only to its provider over HTTPS. Keep the request free of prompts, viewer messages, and generation or synthesis. [OpenAI list models](https://developers.openai.com/api/reference/resources/models/methods/list) · [ElevenLabs list voices](https://elevenlabs.io/docs/api-reference/voices/search)
- [x] Save only the exact candidate that passed the check. Preserve any working Keychain value if the check fails, times out or is canceled. Keep raw secrets and provider responses out of app logs, standard preferences and screenshots.
- [ ] Give distinct recovery copy for rejected credentials, missing permissions, rate limits, offline service and Keychain write failure. Offer **Try again** or **Replace key** next to the issue. Separate a verification failure from permission to make paid requests.
- [ ] Explain broadcaster and bot roles before opening Twitch. Display the official activation site, copyable code, expiry, cancellation and **Get a new code**. Confirm the returned login and granted scopes. Never embed a client secret in the desktop app. Keep the public client ID field during development and confirm a registered public client before offering a simpler public setup. [Twitch Device Code Grant](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#device-code-grant-flow) · [Validating tokens](https://dev.twitch.tv/docs/authentication/validate-tokens/)
- [ ] Test wrong account, same account for both roles, denied or expired approval, cancellation, app restart, refresh, revoked consent and incorrect client ID with synthetic transport fixtures first. Run real Twitch checks only with approved test accounts and document what the registered client actually accepts.

## Prioritized build list

### P0 · First usable rehearsal

- [x] Check before saving and exercise successful and rejected replacements, cancellation before a write, and relaunch with synthetic keys.
- [x] Build the three-step Setup Guide. Exercise sample playback, skipping OBS, and reopening at the saved step in the native UI.
- [ ] Verify the first-launch offer on a clean install and exercise keyboard and VoiceOver navigation.
- [x] Bundle one short spoken line for offline setup. Include playback and the output picker in the guide.
- [ ] Group playback, audio destination and **Show mascot window** under the wolf in the Dashboard. Surface mute and Emergency stop near the controls. Show live-only controls when they can act.
- [ ] Make OBS verification explicit and document expected permissions, exact source names and the single intended audio route. Check separate game, mic and mascot audio in a recording. Run Stop and Resume three times and record whether the OBS source needs reselection. [OBS audio guide](https://obsproject.com/kb/macos-desktop-audio-capture-guide) · [Existing capture evidence](../research/native-preview-validation.md)
- [ ] Validate clean install, skip, resume, and reopening setup. Check keyboard-only and VoiceOver navigation, narrow windows, reduced motion, light and dark mode, and the macOS 15 floor. Try the flow with three to five streamers. Target hearing the wolf in one minute and recording a check in OBS in five.

### P1 · Connections and stream readiness

- [ ] Add the optional setup checklist using the same connection screens and audio settings. Show exactly what each currently available capability can do.
- [ ] Verify the public-client Twitch flow with both real roles. Add reconnect, recovery and scoped EventSub in small batches, beginning with one local mention or redeem. Keep consent and live arming separate.
- [ ] Route synthetic events through the bounded scheduler. Show one concise outcome and reason, including cooldown, canceled or stopped. Use an immediately reachable Emergency stop, a separate resume, and tests for duplicate or delayed events.
- [ ] Verify PackGuard’s full input and output checks, fail-closed behavior, rate limits and budget reservations before enabling cloud or chat output. Confirm Twitch data-sharing permission, public desktop OpenAI key policy, and ElevenLabs voice and commercial rights for the enabled paths. [Feasibility gates](../research/feasibility.md) · [Scheduler](../architecture/reaction-scheduler.md) · [PackGuard](../architecture/packguard.md)

### P1 · Optional local fallbacks

On November 20, 2026, a standalone Swift check built with a macOS 15 deployment target reported the on-device model available and generated one synthetic mascot greeting on macOS 27.0.1. That checks the OS path. The model is still outside EchoPaw’s live reply pipeline. The System Voices clause was checked in the public Tahoe license and the installed macOS 27 license.

- [ ] Prototype an opt-in **Apple Intelligence** reply provider with the on-device `SystemLanguageModel` on macOS 26+. Check runtime availability and keep the existing macOS 15 minimum. Test short structured replies, model refusal, burst load and Stop. Keep PackGuard in the path and keep the provider selection visible. [Apple model availability](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel) · [Apple acceptable use](https://developer.apple.com/support/terms/acceptable-use-requirements-for-the-foundation-models-framework/)
- [ ] Evaluate an offline speech engine and a specific voice with documented permission for public and commercial streams. Send its audio through EchoPaw’s existing route and Stop handling. Apple’s `AVSpeechSynthesizer` is technically capable of local speech, but the macOS System Voices license restricts public sharing and commercial use. Keep those voices out of the stream fallback. [Speech buffer API](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/write(_:tobuffercallback:)) · [macOS Tahoe license, section 2.F](https://www.apple.com/legal/sla/docs/macOSTahoe.pdf)

### P1 · Logo in parallel

The chosen direction is **wolf ears in a speech bubble**. Use two broad ear shapes to read at a glance, with the bubble tail carrying the speech cue. Use the navy-to-blue brand palette for the app icon and simple one-color geometry for smaller surfaces. The prior bubble, paw and waveform concept showed the thin waveform fading at 32 px. Reserve full character art for the app’s stage. [Icon assets and proof sheet](../../assets/icons/README.md)

- [x] Replace the app icon and docs identity with the approved wolf-ear speech bubble. Compare 16, 32, 64 and 128 px exports on light and dark surfaces.
- [ ] Check a monochrome version and ask viewers what they see at Dock size before showing the wordmark.
- [ ] Take the strongest mark through Finder, Dock, menu bar, installer and website checks. Export a vector master, a monochrome menu bar template and layered Xcode artwork. Validate the actual rendering on macOS 15 and the current release.
- [ ] Resolve the working-name clearance and durable distribution identifiers before public brand launch. [Naming review](../research/naming.md) · [Apple Icon Composer](https://developer.apple.com/icon-composer/)

### P2 · Public release and later additions

- [ ] Walk through one signed beta from clean installation and OBS rehearsal to deliberate stop. Validate macOS audio device loss, recoverable configuration, notarization, and a genuine Sparkle update across signed builds. Publish setup, replacement, disconnect, privacy and troubleshooting guidance with synthetic screenshots. [Distribution](../architecture/distribution.md)
- [ ] Opt in independently to microphone reactions, optional Stream Deck control, richer character states and later viewer memory. Validate their permissions, accessibility, stop behavior and removal before treating them as supported. [Product roadmap](roadmap.md)

The next useful checkpoint is a clean install that reaches the spoken sample without a provider sign-in. Live OAuth approval, OBS audio isolation and signed-release behavior require their own evidence.
