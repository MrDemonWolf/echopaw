# Twitch connection and EventSub

**Status** Proposed implementation contract. Provider documentation checked November 18, 2026. OAuth and live events still need validation with test accounts.

Use Twitch public-client Device Code Grant, direct EventSub WebSockets, and the Helix Send Chat Message API. The streamer identifies the channel and authorizes channel events. The separate bot account reads chat and sends optional replies. Use immutable Twitch user IDs for identity; login and display names are labels. One EchoPaw channel per installation is sufficient for the first release. [Twitch OAuth](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/) · [Twitch Chat setup](https://dev.twitch.tv/docs/chat/authenticating/) · [Chat API](https://dev.twitch.tv/docs/api/reference/chat#send-chat-message)

## Permissions and event ownership

| Feature | Connection and user-token scope | EventSub type or API |
| --- | --- | --- |
| Identify broadcaster | Streamer, no additional scope for ID/login returned by validation | OAuth `/validate`. Confirm empty scope device grant with the registered public client before promising identity-only connection. |
| Direct mentions and chat keywords | Bot, `user:read:chat` | `channel.chat.message` v1, condition `broadcaster_user_id` = streamer and `user_id` = bot. |
| Outgoing chat, off by default | Bot, add `user:write:chat` | `POST /helix/chat/messages`, with broadcaster ID and matching bot sender ID. |
| Selected custom Channel Points rewards | Streamer, `channel:read:redemptions` | `channel.channel_points_custom_reward_redemption.add` v1. Match selected reward ID and eligible status. |
| Cheers and built-in Power-ups | Streamer, `bits:read` | `channel.bits.use` v1, handle only `cheer` and `power_up`. |
| Custom Power-ups | Streamer, `bits:read` | `channel.custom_power_up_redemption.add` v1, filter by selected reward ID, use redemption ID for dedup. |
| Incoming raid | Streamer token, no event-specific scope | `channel.raid` v1 with `to_broadcaster_user_id`. |
| New subscriptions, gifts and announced renewals | Streamer, `channel:read:subscriptions` | `channel.subscribe`, `channel.subscription.gift`, `channel.subscription.message`, all v1. Ignore gifted individual subscription events if responding to the aggregate gift, and treat renewal messages as viewer announcements. |
| Stream status, optional | Streamer token, no event-specific scope | `stream.online` and `stream.offline` v1. Initial UI state remains unknown until queried or observed. An authenticated account is not evidence that streaming is live. |

The WebSocket transport uses user access tokens even for scopes-free subscriptions. The app-access flow's `user:bot`, `channel:bot`, hosted webhook/conduit setup, and related authorization conditions are outside this design. Basic chat needs no moderator role or moderation scopes. PackGuard screens EchoPaw inputs and outputs. It does not moderate the channel or publish messages from AutoMod review. EchoPaw observes redemptions first and leaves fulfillment, refunds and reward creation to Twitch. Broadcaster account eligibility and reward ownership limit what Helix can manage, and broadcaster use of free Power-ups does not emit the general Bits event. [Scope reference](https://dev.twitch.tv/docs/authentication/scopes/) · [Chat EventSub](https://dev.twitch.tv/docs/eventsub/reference/chat) · [Channel EventSub](https://dev.twitch.tv/docs/eventsub/reference/channel) · [Channel Points reference](https://dev.twitch.tv/docs/eventsub/reference/channel-points) · [Channel Points API](https://dev.twitch.tv/docs/api/reference/channel-points) · [Bits API](https://dev.twitch.tv/docs/api/reference/bits)

## Authorization and recovery

1. Register a Twitch public client and ship only the public client ID in source. Verify current Dashboard settings and public-client refresh before the native release build.
2. Start one connection flow at a time. Present Twitch's short code, accessible copy control, role label and expiry. Open Twitch in the user's browser and poll at Twitch's returned interval. Handle pending, slow down, denied, expired, and cancel. Never read a Twitch password.
3. Validate `client_id`, actual user ID and granted scopes. Show “Connected as …” before activating the role. Warn if both flows returned the same account and keep the second role disconnected until the user authorizes a different account. Retain the previous connection until a confirmed replacement succeeds.
4. Store each token pair as one Keychain item per role, isolated from pack exports and logs. Serialize refresh per role, replace the access and refresh token together after success, and pause affected delivery while a refreshed grant is checked. Device-grant refresh tokens are single-use and public-client refresh tokens expire after 30 days if unused. Recover from a lost rotation response or rejected refresh through sign-in.
5. Call `/validate` at startup and hourly thereafter while maintaining the session. Distinguish transient validation failures, access-token expiry and revocation. Pause affected routes on uncertain authorization. Refresh when applicable after a 401, revalidate scope and identity, and require sign-in if revocation or invalid refresh is confirmed. Changing scopes or disconnecting cancels queued work bound to the former grant and triggers applicable local and downstream deletion. Offer explicit Twitch revocation and report any unconfirmed revoke separately from local sign-out.

References [Device code grant](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#device-code-grant-flow) · [Refreshing tokens](https://dev.twitch.tv/docs/authentication/refresh-tokens/) · [Validating tokens](https://dev.twitch.tv/docs/authentication/validate-tokens/) · [Revoking tokens](https://dev.twitch.tv/docs/authentication/revoke-tokens/)

## Event pipeline

Start one `URLSessionWebSocketTask` per active role with enabled subscriptions. Start with the Twitch endpoint `wss://eventsub.wss.twitch.tv/ws`, take the session ID from Welcome, and create an enabled subscription with Helix within Twitch's advertised welcome window, ordinarily 10 seconds. Retain independent status for each requested subscription. The WebSocket limits currently apply per client ID and user ID pair, with three active connections and 300 enabled subscriptions per connection. Respect the subscription-reported cost and limit. [WebSocket handling](https://dev.twitch.tv/docs/eventsub/handling-websocket-events/) · [Subscription management and limits](https://dev.twitch.tv/docs/eventsub/manage-subscriptions/)

- Use the Welcome keepalive interval and monotonic inactivity deadlines. Handle protocol ping/pong. No client application messages go over this socket.
- On Twitch's reconnect notification, use the supplied secure endpoint as provided after checking its scheme and Twitch hostname. Keep the old connection until the new Welcome arrives. Subscriptions transfer and delivery during overlap still goes through deduplication. On an unexpected disconnect, reconnect with bounded exponential backoff and jitter and recreate subscriptions. Show a gap in stream status because Twitch does not replay the missing events.
- Validate envelope type/version, condition, active role and current connection generation. Deduplicate retries by `metadata.message_id` in a proposed 15-minute, 4,096-entry in-memory cache. Deduplicate domain IDs where available. Keep the chat and payment paths single-source. Filter cheermote and relevant reward duplicates out of generic chat triggers. Drop `custom_power_up` variants of `channel.bits.use` when the dedicated custom subscription is enabled.
- Skip the app's own bot identity and EchoPaw-originated message IDs. Acknowledge redemptions or raids using type and mapped local action. Reject remote chat from other Shared Chat source channels using the provided source broadcaster ID. Confirm shared-chat behavior with a second account before enabling outgoing chat.

References [WebSocket handling and retransmissions](https://dev.twitch.tv/docs/eventsub/handling-websocket-events/) · [Chat metadata](https://dev.twitch.tv/docs/eventsub/reference/chat#channel-chat-message) · [Sending and receiving chat](https://dev.twitch.tv/docs/chat/send-receive-messages/)

## Outgoing chat

Default to the app's 180-character target and 240-character hard cap. Twitch permits 500 characters. Measure final text conservatively in Unicode scalars and UTF-16 units until emoji and combined-grapheme behavior is tested. Clip on grapheme boundaries only before final approval. Use `reply_parent_message_id` only for a matching approved chat event. Parse `is_sent` and `drop_reason` even on HTTP 200. A timeout with unknown delivery status must never cause a second send. For 429, respect reset or retry guidance and discard expired work. Twitch's baseline chat backend limits are 20 messages per 30 seconds per ordinary sender plus one per second per channel for non-privileged senders. EchoPaw's limit is stricter. [Send Chat Message](https://dev.twitch.tv/docs/api/reference/chat#send-chat-message) · [Chat rate limits](https://dev.twitch.tv/docs/chat/#rate-limits) · [Helix rate limits](https://dev.twitch.tv/docs/api/guide/#twitch-rate-limits)

Twitch's user-token sends fan out into Shared Chat and cannot set `for_source_only`. Use `GET /helix/shared_chat/session` to check for an active session at connection and before sending. Consider the begin and end EventSub types for prompt status updates. Keep text send off for active or unknown Shared Chat by default. There is a possible race if the session changes between preflight and send. Verify the observed behavior and disclose that risk before enabling any bot text. [Get Shared Chat Session](https://dev.twitch.tv/docs/api/reference/chat#get-shared-chat-session) · [Shared Chat EventSub](https://dev.twitch.tv/docs/eventsub/reference/chat#channel-shared-chat-session-begin)

## Twitch data release gate

Twitch's Developer Services Agreement, section VI, defines Twitch Data to include derived insights. Section VI.C requires prior written permission for third-party sharing. Confirm Twitch's written permission for the exact OpenAI moderation and generation paths and any Twitch-derived ElevenLabs input, plus the applicable provider terms and deletion obligations, before enabling those routes, including during testing with real Twitch data. Viewer consent, streamer consent and removing the viewer's name do not settle that condition. Before clearance, validate with synthetic fixtures and offer local-only Twitch event decisions with silent animations. Keep cloud demo inputs independently authored or synthetic. Handle required deletion on revoked or reduced grants, contract termination and valid requests. Leave viewer memory deferred and off until those workflows are verified. [Twitch Developer Services Agreement](https://legal.twitch.com/en/legal/developer-agreement/)

## Acceptance gates

- [ ] Two distinct public-client OAuth sign-ins, cancel, wrong signed-in identity, scope add/remove, app restart, concurrent refresh, revoked token, denied scope and expired refresh.
- [ ] Test WebSocket Welcome, keepalive, handover, abrupt disconnect, permissions, duplicate delivery, role change and independently recovering bot chat and channel events with Twitch CLI and fixtures.
- [ ] Test selected Channel Points redemption, ordinary cheer, built-in Power-up, custom Power-up, raid and subscription in permitted test channels. Each event fires once with scoped access. Verify Shared Chat, bot sends without moderator rights, dropped sends and mixed Unicode lengths.
- [ ] Clear the Twitch Data and OpenAI desktop credential gates before Twitch cloud replies. Verify public notices, retention and deletion with the explicit data map.

[Twitch CLI WebSocket tests](https://dev.twitch.tv/docs/cli/websocket-event-command/) · [Reaction scheduler](reaction-scheduler.md) · [PackGuard](packguard.md)
