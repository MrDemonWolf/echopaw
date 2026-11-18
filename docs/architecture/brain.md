# The Brain

**Status** Product contract and proposed request design. Official OpenAI documentation checked November 18, 2026. Key permissions, response quality, latency and cost have no live-account verification yet.

Use GPT-6 Luna (`gpt-6-luna`) as the default OpenAI dialogue model. OpenAI documents text output, Structured Outputs and the Responses API for Luna. OpenAI is the sole cloud LLM provider. The picker selects a compatible OpenAI model, and the voice provider is configured separately. Cloud AI is optional for preview and requires the user's own provider credentials and the release gates below. [GPT-6 Luna model](https://developers.openai.com/api/docs/models/gpt-6-luna) · [Responses create](https://developers.openai.com/api/reference/resources/responses/methods/create)

## What the streamer controls

| Settings | Contract |
| --- | --- |
| Identity and personality | Character name, optional pronouns, brief role and traits. Whole profile is editable and versioned. Imported text is untrusted. |
| Style | Preferred phrases, words to avoid, language, short replies, allowed expression IDs. PackGuard governs the final response. |
| Reaction preferences | Per-trigger tone and voice/text choice, bounded by the scheduler and available destinations. |
| Stream context | Creator-approved category or session notes. Optional transient context from the active approved event only. |
| Mood and expression | Runtime state from a small local enum and current pack. Only the renderer can apply an allowlisted expression. |
| Memory | Creator notes are manually curated. Viewer memory is opt-in and deferred as below. |
| OpenAI | Model selector, known-model compatible parameters and prices, local usage summaries and conservative budget caps. |

## Request and output boundary

1. Check trigger, consent, destination, provider readiness, stream session and cost allowance in the [scheduler](reaction-scheduler.md). Apply [PackGuard](packguard.md) input approval before cloud generation. Twitch-derived data requires prior written Twitch permission before either call.
2. Build one bounded `POST /v1/responses` request. Use a stable developer instruction prefix with response schema. Put character preferences in a separate bounded context field and put approved variable context and the current event last as data. Strip handles/IDs where they are unnecessary, use no tools, conversations or `previous_response_id`, set `store: false` and keep `truncation` disabled. Skip full chat transcripts. Target 900 input tokens and enforce a 1,500-token local ceiling with a conservative preflight estimate. Drop expired/session details first, then optional memory, then shorten eligible input or drop the event. Preserve policy instructions and schema. Never increase prompt length just to obtain a cache hit.
3. Request a short structured response containing text plus a nullable expression from a finite list. Start Luna at `reasoning.effort: none` and `max_output_tokens: 192`, which includes any billable reasoning tokens. Check each alternate model for these parameter capabilities before offering it. Luna supports Structured Outputs. Enforce schema again locally, accept only a successful completed response, and treat refusal, incomplete output, invalid fields or over-cap output as silent fallback. Target 180 visible characters, enforce 240 hard, and cap the final Twitch payload independently at 500; prefer a safe fallback over cutting words in a way that changes meaning.
4. Approve the exact final payload per destination through PackGuard. Hold generation output privately until complete. Streaming LLM text never feeds live chat or TTS directly. Use a generation ID to reject late completions after mute, pause, disconnect, stop or stream change. Cancel the local foreground task and downstream playback. Closing the local request may still incur provider charges. OpenAI's response-cancel endpoint is for background-mode responses.
5. Classify failures for recovery. On 401/403, stop and expose key/scope help. On missing model or incompatible capability, offer explicit choice of another tested, available OpenAI model within the user's budget. No silent upgrade, provider change or repeated paid calls when outcome is uncertain. Respect retry instructions on rate limit and allow the next eligible event after backoff. A stale event expires instead of producing a delayed interruption.

[Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs) · [Response cancel](https://developers.openai.com/api/reference/resources/responses/methods/cancel) · [List models](https://developers.openai.com/api/reference/resources/models/methods/list) · [OpenAI errors](https://developers.openai.com/api/docs/guides/error-codes)

## Memory and privacy

- Before launch, use local creator notes and bounded in-memory session state. Scope notes to an active profile. The streamer approves what goes to OpenAI. Notes are excluded from synthetic tests unless selected.
- Later viewer memory requires explicit viewer opt-in after disclosure. A general chat message, mention or paid redemption grants no consent. Keep a short approved fact or summary keyed locally by broadcaster ID and immutable viewer ID, with purpose, consent date, provenance, expiry and review state. Default proposal is at most two short facts per viewer, no more than 160 characters each, 30-day expiry and no automatic renewal without fresh interaction or permission. Exclude private contact data, sensitive traits, offensive content, secrets and raw transcripts. Prefer deterministic type/value fields over a freeform summarizer at launch. Import summaries as data and review them under PackGuard before use.
- Keep consent separate from notes and provide streamer search/review/delete, viewer opt-out and a forget command that is handled locally before generation. Honor valid requests through a published route that works even when the viewer is not in chat. Purge local data and cached context on expiry, removal or Twitch authorization loss according to the applicable data policy. Confirm a downstream deletion path for any data shared with provider permission. No viewer content in character packs, profile exports, support logs or price analytics.
- OpenAI's API data-control documentation states API inputs are not used for training by default. `store: false` disables normal Responses application-state storage, subject to documented exceptions, and does not remove default Responses abuse-monitoring retention of up to 30 days. The provider currently lists none for the standalone moderation endpoint. Cache behavior has separate controls. Disclose provider processing separately from the app's local retention.

[OpenAI API data controls](https://developers.openai.com/api/docs/guides/your-data) · [Twitch data policy](https://legal.twitch.com/en/legal/developer-agreement/)

## Usage and caps

Track completed responses using provider-reported input counts, `input_tokens_details.cached_tokens`, cache-write breakdown where present, and billed output tokens including reasoning. Keep the instructions stable, without adding private data to prompt cache keys. Treat cache savings as optional. GPT-5.6 and later models have a documented 1,024-visible-token cache minimum. Requests below it can be cheaper at Standard uncached rates than padded requests. [Prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching)

The Standard short-context Luna rates checked November 18, 2026 were **$0.10 uncached input, $0.01 cache hit, $0.125 30-minute write, $0.25 12-hour write, and $0.50 output per million tokens**. Cost is the sum of each disjoint billed token count times its rate divided by one million. A 900-input, 100-output uncached response is about $0.00014. A thousand such responses are about $0.14. Actual billed tokens, processing tier, retries, cache writes and premiums change the estimate. Treat unknown model prices and missing usage as unavailable or estimated, never as free. [OpenAI pricing](https://developers.openai.com/api/docs/pricing)

Reserve worst-case input and output usage before sending, settle when usage arrives and keep uncertainty reserved after cancellation or timeout. Track OpenAI and ElevenLabs separately at stream and month level. Default proposed limits for Standard Luna are $0.10 per stream and $1 per month, plus the scheduler's much lower call-count ceilings. Fixed provider plan fees and requests from other apps sit outside local caps. Show the rate timestamp and “estimated” in the UI. Reconcile aggregate usage against the user's platform dashboard. [ElevenLabs estimate](../research/elevenlabs.md) · [Reaction limits](reaction-scheduler.md)

## Public desktop credential gate

OpenAI's API reference cautions against exposing API keys in client-side code such as apps. Its key-safety guidance recommends sending requests through a backend. EchoPaw's proposed BYOK model keeps a user-created restricted project key in the owner's Keychain, with zero embedded or shared keys. That proposal needs OpenAI confirmation before public enablement of generation or moderation in the backend-free desktop app. Until then, public distributions use the offline sample path. Independently confirm Twitch written permission before routing Twitch Data to providers. [API authentication](https://developers.openai.com/api/reference/overview#authentication) · [API key safety](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety) · [API keys and permissions](https://developers.openai.com/api/docs/guides/api-keys)

## Acceptance gates

- [ ] Verify allowed BYOK deployment and test a restricted, non-admin key for compatible models, Responses and moderation.
- [ ] Confirm fixed fixture prompts and exact outbound wire fields, truncation order, bounded tokens, locale handling, finite expression IDs, refusal and malformed output.
- [ ] Test unavailable Luna, rate limits, cancellation, timeout, uncertain charges, stale responses and budget reservation. Record p50/p95 generation latency and measured usage for a synthetic reply fixture set.
- [ ] Verify viewer consent, data minimization and downstream deletion before any release with viewer memory or real Twitch cloud inputs.
