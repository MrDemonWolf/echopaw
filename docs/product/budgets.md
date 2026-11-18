# Cost and performance budgets

Planning estimates checked November 18, 2026. Provider rates are USD, before plan fees, credits, taxes or other consumption.

## Cost per session and month

Use GPT-6 Luna Standard short-context rates of $0.10 per 1M uncached input tokens and $0.50 per 1M output tokens. Use $0.04 per 1,000 characters as the ElevenLabs v4 Turbo metered reference, separate from subscription billing or commercial entitlement. The example assumes 900 input tokens, 80 billed output tokens and 120 speech characters for each completed spoken reply. [OpenAI Luna](https://developers.openai.com/api/docs/models/gpt-6-luna), [ElevenLabs API rate card](https://elevenlabs.io/pricing/api?v=1019).

| Example | Replies | Dialogue | Metered voice | Combined |
| --- | ---: | ---: | ---: | ---: |
| Three-hour Balanced rehearsal at 10 lines/hour | 30 | $0.0039 | $0.144 | $0.148 |
| Proposed monthly default ceiling | 200 | $0.026 | $0.96 | $0.986 |
| 10 such streams in a month with a raised monthly cap | 300 | $0.039 | $1.44 | $1.479 |

Use actual billed token counts for reports, including billed reasoning output where applicable. Cache hits and writes have different rates. Moderation rechecks, retries, other models, text-only replies, TTS previews and optional transcription are separate accounting paths. Check the provider usage dashboard against estimates. The [calculator source and guides](../../apps/docs/) run locally.

The scheduler proposes at most 20 per hour, 60 per stream and 200 per month for each provider, with a maximum of 240 spoken characters per line. Use separate per-stream, day and month ceilings for tokens, characters and estimated cost. Reserve worst-case cost before dispatch, avoid retrying ambiguity, and reconcile against responses where available. Cost estimates cannot enforce spend across other clients. Start with user-confirmed monthly budgets and document provider-level controls. [Scheduler](../architecture/reaction-scheduler.md), [Brain](../architecture/brain.md).

## Runtime budgets

| Target | Measurement |
| --- | --- |
| Offline cold launch p95 ≤ 2 seconds | Ten signed launches on a base Apple Silicon machine. |
| Minimal pack idle physical footprint p95 < 150 MB and mean CPU < 2% of a core | Instruments over 15 minutes with OBS present. Measure OBS baseline independently. |
| Sprite response p95 ≤ 100 ms from playback start | Timestamp 30 transitions and confirm the OBS recording. |
| Emergency stop p95 ≤ 150 ms to silence on wired output | 30 trials across active and pending speech. Bluetooth is a separate measurement. |
| Cloud reply p95 ≤ 4 seconds from dispatch to first audio | Proposed under ordinary network conditions, including mandatory checks. Measure each boundary and do not begin streaming TTS until the full text is approved. |
| One-hour rehearsal | No overlapping utterances, old audio after stop or sustained growth > 20 MB above steady state. |

Use the [native measurement plan](../architecture/native.md) to record hardware, OS, OBS, output and provider model. App measurements are pending.
