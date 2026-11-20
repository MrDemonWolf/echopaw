# EchoPaw live co-host plan

November 20, 2026. This plan consolidates the product interview. The setup guide, sample speech, transparent mascot window, key checks, and separate Twitch sign-ins are the starting point. Live conversation and Twitch event handling are planned.

## Build order

1. **Mac mini rehearsal.** Keep OBS, EchoPaw, Stream Deck and the dedicated mic on the Mac mini. Verify one copy of mascot audio and a stable OBS source while switching outfits. Offer direct idle and speaking image pickers, optional blink art, and named outfits. Switching looks keeps voice, personality and conversation context.
2. **Streamer conversation.** When listening is enabled, recognize EchoPaw or a custom wake name on the dedicated mic. Start one multi-turn conversation and end it by voice, Stream Deck Stop, or 30 seconds without a follow-up. Suspend recognition while the mascot speaks in v1 and keep replies short. Keep the macOS 15 baseline and test the existing on-device recognition path before assessing newer APIs. Add local Stream Deck actions for listening, Stop, Viewer Interactions and named outfits. [Apple Speech](https://developer.apple.com/documentation/speech) · [Stream Deck actions](https://docs.elgato.com/streamdeck/sdk/guides/actions/)
3. **Twitch participation.** Ship the app-owned public Client ID and use device authorization for separate broadcaster and optional bot accounts. Validate the actual account and scopes. Viewer Interactions starts off and gates viewers and Twitch events independently of streamer controls. Chat accepts a bot mention or the configured mascot name at the start of a message. Chat output uses the original message as its reply parent. Offer Chat, Voice, Both or Off per trigger. Viewer speech waits until the streamer conversation ends and the mic is quiet. Use bounded queues, expiration, per-role cooldowns, an overall limit and bot-only blocks. Mods can pause, skip viewer replies, block or unblock, and check status. Allow a lead-mod restriction. Only the streamer can resume. [Device authorization](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/) · [Chat API](https://dev.twitch.tv/docs/api/reference/chat)
4. **Rewards and events.** Prioritize custom Power-ups over ordinary Cheers. Guide the streamer through creating Ask EchoPaw in Twitch, then link by ID and distinguish missing from unavailable. Support outfit rewards the app creates in Channel Points. While an outfit redeem is active, pause the managed outfit rewards on Twitch and cancel any conflicting pending redemption that slipped through. Keep redemption fulfillment pending until the outfit change succeeds. Reconcile managed reward state after restart or lost permissions. Support timed, until stream ends, and until changed. Manual changes cancel the pending reset. Keep paid outfit swaps out of the first release while Power-ups lack a pause API. Add subscriptions, gifts, raids and Hype Trains as separately configurable triggers. [Channel Points API](https://dev.twitch.tv/docs/api/reference/channel-points) · [Bits API](https://dev.twitch.tv/docs/api/reference/bits)
5. **Memory and fallbacks.** Keep conversation context through the current exchange. Persistent streamer memory is opt-in and saves only approved details. Relevant recalls and suggestions can happen automatically. Viewer memory waits for bot-based opt-in and deletion. Evaluate Apple Intelligence for opt-in local text and an independently licensed offline voice. Check provider policy and PackGuard before live outputs, including Twitch data use with third parties. [Twitch developer agreement](https://legal.twitch.com/en/legal/developer-agreement/) · [Release gates](decisions.md)

## OpenAI model picker

Offer **GPT-6 Luna** by default, with **GPT-6.1 Terra** and **GPT-6.2 Sol** as choices. Maintain a single versioned catalog for display name, provider model ID, supported request options and budget metadata. Bundle the catalog and design its update path so a model swap is a catalog change, with validation before loading updates. Use the account's model list to check access, then verify the exact request parameters before marking a model usable. Persist the selected ID. If it becomes unavailable, explain why and offer a replacement. A fallback may run only if the streamer explicitly configured it and it still passes the budget and safety checks. [OpenAI model catalog](https://developers.openai.com/api/docs/models/all) · [List models](https://developers.openai.com/api/reference/resources/models/methods/list/)

## Approved defaults

- Pilot on the two-machine setup with streamer conversation, outfits and Stream Deck. Viewer controls follow in a second milestone.
- Leave automatic local fallback off by default. Offer an explicit opt-in after validating availability, safety and Stop on the Mac mini.
- When the Ask EchoPaw description says a chat reply counts, use a substantive chat reply as fallback if speech cannot play. Flag failed delivery for streamer review when neither output works.
- Default opted-in viewer memory to expire after 90 days of inactivity, with an adjustable retention window and earlier viewer deletion.

Treat the rest as defaults to validate on the Mac mini rather than interview questions. Check mic/voice isolation, Stop during playback, half-open Twitch sessions, scoped permissions, queued-output cancellation, and duplicate or overlapping redemptions before release.

## Pilot cleanup audit

| Finding | Disposition |
| --- | --- |
| The Dashboard offered AI pause and resume without a reply engine. | Removed the control and its unused session state. The emergency stop and speech mute remain. |
| Connection status and Twitch setup competed with the local rehearsal. | Removed the connection panel from Dashboard and the Twitch step from Setup Guide. Provider keys and existing Twitch connection management remain in Settings so saved accounts can still be managed. |
| The local mic can detect activity or a wake phrase. | The pilot still needs actual multi-turn transcription, reply generation, routed speech and cancellation. Validate those together on the Mac mini. |
| Character import currently starts from a PNG folder. | Direct idle and speaking image selection now uses the same validated import path as folders. Named outfits are next. Verify a look change reuses the same OBS source. |
| The stop path hides the mascot window. | Verify OBS source recovery after stop before treating it as a live-ready control. The committed transparent video proof used silent sources. |
| Stream Deck is part of the pilot but needs a local control path. | Exercise listen, stop and select outfit with the physical deck connected to the Mac mini before pilot sign-off. |
