# PackGuard safety specification

**Status** Mandatory safety invariant and proposed implementation. Provider documentation checked November 18, 2026. Moderation accuracy and latency need fixture-based validation.

Every untrusted input that could produce dialogue enters PackGuard. Every final string sent to ElevenLabs or posted to Twitch needs a current approval for that destination. A required check that fails, times out, or returns an invalid decision closes that output route. Local preview and non-dialogue animations can continue when allowed. [Twitch data release gate](twitch.md#twitch-data-release-gate) · [OpenAI desktop credential gate](brain.md#public-desktop-credential-gate)

## Policy and order

| Stage | Required behavior |
| --- | --- |
| Local input | Bound length and confirm origin. Remove credential-like or private data from allowed context, or block uncertain cases. Validate trigger, consent, active session, authorization and destination. Normalize a comparison copy for block rules, keeping the real string for later exact approval. Unknown actors, imports and viewer text remain untrusted. |
| Provider input | Use a standalone text moderation request on only the eligible input to be processed initially. Check permitted context, including optional approved memory or imported personality snippets, before any model request using them. Treat provider flags and category output as policy signals. If data transfer has no clearance, bypass dialogue and choose an eligible local-only action. |
| Generation | Pass approved input as untrusted data to The Brain. App policy, renderer state, secrets, budgets and actions stay outside model control. Structured expression suggestions require available allowlisted IDs. No tools, provider switching, embedded directives or automatic execution. |
| Generated output | Accept one completed, parsed result. Normalize plain visible text, validate language and size, strip unsupported controls and markup, and apply mandatory and stricter local rules. The unapproved result remains private and never streams to a destination. |
| Final pre-TTS / chat | Build each exact final plain-text payload, including any prefix or transformation that could change spoken meaning. Recheck local rules and provider moderation on that final string. An identical text may reuse a successful classification within the same action and policy revision, with separate destination policy checks. Approve immutable text, destination, session generation, expiry and policy version. The output adapter verifies approval immediately before sending. No arbitrary audio tags, post-approval interpolation or freeform SSML. A stale, replaced or unknown approval closes the route. |

Use OpenAI `POST /v1/moderations` with `omni-moderation-latest` for text. It is documented as free to use, has no audio classification, and has service/availability limits. Empty result, missing required fields, unsupported category schema, rate limit, timeout or revoked permissions mean “unavailable.” Review applicable categories and evaluate false positives and false negatives before changing policy after a model revision. Apply category scores alongside other policy signals. [OpenAI moderation guide](https://developers.openai.com/api/docs/guides/moderation) · [Moderation endpoint](https://developers.openai.com/api/reference/resources/moderations/methods/create) · [Twitch Community Guidelines](https://safety.twitch.tv/s/article/Community-Guidelines?language=en_US)

## Mandatory minimums and presets

- Always block identity-based hate, violent threats or targeted intimidation, private personal information or doxxing, sexual material involving minors, and content that violates applicable Twitch policies. Treat credible threats, targeted harassment and unsafe self-harm instructions conservatively. SFW, PG-13 and Twitch-safe Mature all retain this floor.
- Use provider flags appropriate to Twitch and EchoPaw's policy alongside deterministic detection of obvious secrets, contact details and local prohibited phrases. Moderation has no dedicated doxxing guarantee. Reject uncertain sensitive fields before cloud transmission. Avoid claims of comprehensive detection, and validate false positives with benign gameplay context, reclaimed terms and ordinary names.
- **SFW** reduces profanity and mature references. **PG-13** is the default and proposed to allow mild profanity that meets Twitch and local rules. **Twitch-safe Mature** permits stronger language within the safety floor and Twitch policies. Channel classification labels remain the streamer's responsibility. None of these modes guarantees compliance.
- Custom rules can further restrict words or topics. Scope rules to input, output or both. Use normalized literal/word-boundary matching and bounded topic labels in the first release. Preserve graphemes for output. Evaluate Unicode normalization, accented scripts, homoglyphs, spacing and punctuation in fixtures. Subjective topic classification may use a later approved classifier with explicit uncertainty handling. Rules add restrictions and never downgrade an earlier denial.

## Available actions

| Action | Behavior |
| --- | --- |
| Ignore | Discard the trigger with no output or paid call. |
| Block | Suppress voice and chat with a local status reason. |
| Rewrite safely | Permit at most one reserved attempt for a non-mandatory rating or style issue when source input was already approved. Process the rewrite from scratch through final approval. A mandatory denial stays denied. |
| Canned response | Pick a neutral app-provided phrase or a locally configured phrase already approved for testing. For live cloud TTS or chat, the final exact text still requires current approval. No user payload interpolation. |
| Silent animation | Trigger an approved local gesture or do nothing when the state is unavailable. No content leaves the app. |
| Hold for review | Show a temporary private item. A streamer edit is a new payload evaluated through PackGuard. Reviewers cannot override mandatory denials. |
| Notify streamer | Show compact reason and origin category locally. Skip raw content in banners or system notifications. |

If output is denied or moderation is unavailable, prefer silent animation. A known-safe phrase can still be used when its independently required checks succeed. The app's offline hardware preview may play a bundled, static non-speech sound and animate the sample; it opens no destination for untrusted text or media.

## Local review and records

- Logs contain coarse time, route, policy version, safe rule code, outcome and counts. Skip raw viewer input, prompts, responses, credentials, audio and viewer IDs. Keep an in-memory recent view by default. If persistent logs are opted in, rotate after seven days or 500 records, with Clear Logs and an export preview. Avoid stable identifiers in exported diagnostics.
- Hold for review remains in memory, capped at three items and expiring after 60 seconds by default. Rule testing defaults to local synthetic fixtures with a visible proposed decision. A separate explicit provider test uses non-sensitive synthetic text when the integration is available.
- App UI shows PackGuard status and “Why it was blocked.” Track provider health separately from policy. Mute and Emergency Stop stay operable during a stalled safety check.

## Acceptance gates

- [ ] Rule precedence, unsafe imported personality, prompt injection, exact payload mismatch, malformed outputs, profanity presets, privacy leakage, identity-targeted abuse and benign gameplay fixtures.
- [ ] Required provider check timeout/401/403/429/5xx, missing fields, revocation mid-flight and cancellation between approval and delivery. Assert no voice or chat dispatch through the failed route.
- [ ] Test all actions, offline silent fallback, false-positive handling, log/export minimization and expiry. Retain decision counts and fixture outcomes without real viewer content.
- [ ] Verify no media, model command, user-edited rule or separate control path bypasses the approval adapter. Test mute and Emergency Stop while a check or send is in flight.
