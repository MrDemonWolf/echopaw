# Reaction scheduler

**Status** Proposed first-release thresholds. Balanced is the locked default. Validate limits in replay tests and private rehearsals before tuning for stream use.

One scheduler evaluates events for one active stream. The model supplies optional dialogue and expressions. The app owns triggering, priority, spending, delivery and every stop control.

## Presets

| Mode | Eligible reactions | Global speech start interval | AI / speech calls per hour | Pending |
| --- | --- | ---: | ---: | ---: |
| Quiet | Manual, selected paid events and raids, deliberate streamer wake if enabled | 60 s | 10 each | 2 |
| Balanced | Quiet plus direct mention, configured chat keyword, enabled cheers, Power-ups, subscriptions | 45 s | 20 each | 3 |
| Chatty | Balanced with shorter cooldowns and more chances for brief acknowledgements | 30 s | 35 each | 3 |
| Chaos | Chatty with more local animation and a lower speech interval | 20 s | 45 each | 3 |

Intervals are minimums between actual playback starts, with only one utterance playing. Outgoing bot chat is independently opt-in in every preset and limited to one post per 30 seconds by default. Per-rule, per-viewer, stream, and monthly caps also apply. Higher-frequency presets never widen a permission or override PackGuard. Active streaming and rehearsal are separate sessions. Rehearsal cannot post to Twitch. All cloud calls remain subject to provider and Twitch data gates.

## Balanced defaults

Each rule has `enabled`, match conditions, action, priority, event cooldown, viewer cooldown, global cooldown, max queue size, destinations and maximum cloud allowance. The rules below inherit a 45-second speech start interval, common maximum of 3 pending and at most one AI + one TTS request per accepted event. Canned approved lines reserve one TTS request and zero generation requests when their delivery uses cloud speech. Silent actions reserve zero. These are product proposals for controlled testing.

| Trigger | Initial state and condition | Action and possible output | Priority | Trigger / viewer cooldown |
| --- | --- | --- | ---: | --- |
| Manual | Ready during preview or armed session. Streamer button or shortcut. | Safe rehearsal action. Explicitly choose AI or voice from the production control. | 90 | 5 s / local only |
| Streamer wake keyword | Off. Local recognized configured phrase while listening; PTT may provide deliberate activation. | Short voice response, independent of chat output. | 80 | 30 s / local only |
| Channel Points | Off until reward is mapped. Selected reward ID, new redemption. | Approved gesture or short voice. | 70 | 45 s / 2 min |
| Bits cheer | Off until configured. Minimum threshold, matching channel and ordinary cheer. | Approved gesture or short voice. | 65 | 45 s / 3 min |
| Built-in Power-up | Off until configured. Allowlisted subtype. | Matching local gesture first. Optional approved voice. | 60 | 30 s / 3 min |
| Custom Power-up | Off until reward ID is mapped. New dedicated redemption. | Approved gesture or short voice. | 70 | 45 s / 3 min |
| Raid | On when incoming raid capability is enabled. Incoming only, exclude replay. | One generic acknowledgement or gesture. | 67 | 60 s / per raider 5 min |
| Subscription | Off until enabled. New paid sub, aggregate gift or announced renewal. | Single acknowledgement or gesture. | 50 | 60 s / 5 min |
| Direct mention | On after chat input is enabled. Match tagged identity or bounded, configured alias. Ignore bot and command/system traffic. | Short reply, voice by default if ready; optional approved bot text. | 55 | 45 s / 3 min |
| Twitch chat keyword | Off until explicitly configured. Literal allowed phrase, normalized with word boundaries. | Short reply if enabled, or gesture. | 40 | 60 s / 5 min |
| Streamer speech activity | Off, independent microphone permission and toggle. Local speech onset. | Visual attention only. | Local | 1 s visual retrigger interval / local only |

The wake rule's scheduler cooldown and the visual retrigger interval apply after admission. The microphone detector has its own shorter wake debounce and activity thresholds. [Microphone design](microphone.md).

The rule editor permits disabled, silent visual, canned line, or AI reply. Rules with freeform viewer text require the input safety gate before action. A checkout, cheer or redemption never grants precedence over a block or causes EchoPaw to change its Twitch status. Keep speaking limits and charge-outcome boundaries visible at configuration time.

## Admission and delivery

1. Normalize source, immutable viewer ID when present, event ID, event kind, creation time and selected route. Reject own messages, duplicates, disabled/unmatched rules, non-active sessions, stale data, permissions gaps and blocked conditions. Deduplicate at Twitch transport and domain level before touching counters. Claim at most one matching trigger for a message, using highest priority.
2. Keep at most three pending eligible events plus one active job. Order by descending priority and FIFO within each priority. Drop a newcomer when full, unless it outranks the oldest item among the lowest-priority entries, which it may replace. Coalesce repetitive equivalent arrivals into one local indication. Never coalesce a paid event into an action that repeats or records the raw user payload.
3. Use monotonic time. Proposed expiry is 20 s for chat, 30 s for wake/manual, and 60 s for paid or important event acknowledgements. Expire rather than letting old events interrupt the stream. Reserve cooldown when dispatch starts, even on provider failure, to prevent rate spikes on repeated errors. Recheck route, mute, gates and affordability at dispatch.
4. If local input policy or missing provider clearance blocks text, suppress dialogue and use an eligible silent animation. For dialogue, reserve worst-case cost, check input, call [The Brain](brain.md), approve exact destination text through [PackGuard](packguard.md), and send one utterance or text output per selected route. Unselected routes stay closed. A voice-only muted rule skips the cloud pipeline. Text continues after ordinary voice mute only if explicitly selected. Pause AI blocks generation. Optional pre-approved local actions remain subject to the active safety state.
5. Allow one generation and one speech playback at a time, serialized together in the first release. Minor animations can continue while speech plays. Skip lower priority ordinary voice events rather than interrupt speech. Emergency Stop always advances the session generation, cancels generation/TTS/send, clears all queues, mutes immediately, pauses AI and disarms listening. Late completions cannot restart output. A completed Twitch send cannot be retracted by cancel.
6. Track outcome without raw text: filtered, cooling down, queued, expired, blocked, budget exhausted, cancelled, delivered, or delivery unknown. Persist budget totals across restart and disable remote routes if the ledger cannot reserve safely. Offer a compact status explaining what happened.

## Budget proposals

- Balanced defaults to 20 generation dispatches and 20 TTS dispatches in a rolling hour, at most 60 of each per stream, and 200 of each per month. The other presets adjust hourly caps while retaining stream/month ceilings until explicitly edited.
- Initial illustrative dollar caps are $0.10 OpenAI / $0.50 metered-equivalent ElevenLabs per stream, and $1 / $2 per month. Dollar caps supplement counts. Logged usage from other apps, fixed subscriptions, and provider-side deductions deserve separate disclosure. No automatic pay-as-you-go enrollment or model upgrade.
- Reserve one maximum response per dispatch and one pre-approved payload for TTS. Keep uncertain consumption reserved until the ledger can reconcile it. Use separate counters so blocked AI or TTS cannot trigger repeated attempts.
- The local visual reaction path survives missing network or provider credentials. Bounded UI controls still work. The cloud gate applies before any Twitch-derived user data leaves the app, including moderation.

## Acceptance gates

- [ ] Use a fake monotonic clock to prove mode defaults, per-user + global gates, expiry, full-queue priority and same-priority order.
- [ ] Replay reconnect duplicates, a chat cheer plus Bits event, custom Power-up duplicated across feeds, gift bundle plus individual gift events, own outgoing chat and multiple matches.
- [ ] Force denial, moderation failure, budget exhaustion, unknown send, voice mute and Emergency Stop at every pipeline boundary. Show no overlapping payload delivery and no output started after stop.
- [ ] Tune via a synthetic four-hour replay and a private approved rehearsal. Record interruptions per hour, drops by reason, queue age, estimated costs and p95 latency. Use outcomes to tune thresholds conservatively.
