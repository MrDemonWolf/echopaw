# EchoPaw privacy notice draft

Planning draft, 2026-11-18. The behavior below describes the release design. Verify the shipped app and site before approving a public notice.

## On your Mac

EchoPaw runs on your Mac. You can preview sample art and a sample reaction using local files. The proposed distribution has no EchoPaw account and no analytics SDK.

The app uses the macOS Keychain for connected service credentials. Character files, app settings and configured budget counters stay in Application Support. Local diagnostic logs record reason codes, timing and provider status for troubleshooting. Logs and routine export exclude API keys, OAuth tokens, raw chat, microphone audio and rejected content. Clearly label any separate content review that retains text temporarily.

Voice activity and wake phrase listening are optional and begin off. Activity detection uses the chosen mic locally and saves no recording. Local keyword tests use a short rolling buffer in memory. If a later release offers cloud transcription, it requires a separate consent choice describing exactly when mic segments leave the Mac, for which provider, and how to turn it off. It never silently substitutes for unavailable local recognition.

Viewer memories begin off, require viewer opt-in, and contain short approved summaries keyed to the individual channel and viewer. The design supports expiry, reviewing what is remembered, withdrawing consent, individual deletion and clearing all records. Confirm the exact retention before release and make it visible in the app. A viewer’s ability to hear ordinary reactions does not depend on memory opt-in.

## Connected services

| Service | Proposed use and data |
| --- | --- |
| Twitch | Your separate broadcaster and bot OAuth tokens authorize selected read or send actions. The app receives enabled events and can send a bot reply if you enable it. The public cloud-chat path stays disabled until applicable Twitch developer permissions for Twitch data and derivatives are confirmed. |
| OpenAI | With an enabled supported configuration, the approved pipeline sends selected text for moderation and eligible dialogue. Configure Responses with `store: false`. OpenAI documents separate abuse monitoring retention and account controls. Review the desktop BYOK architecture with OpenAI before public enablement. |
| ElevenLabs | A licensed configuration receives approved speech text, selected voice ID and synthesis settings. EchoPaw plays the resulting audio. The app uses the provider account’s applicable retention and licensing terms. |
| OBS and Stream Deck | OBS captures the chosen window and audio route when configured, and controls any broadcast or local recording. The optional Stream Deck connector exchanges narrow local commands and status signals. |
| GitHub, site hosting and updates | Downloads and update checks make network requests to the applicable host. Network metadata may be processed by those providers. Confirm the final hosts, retention and whether the docs site sets any cookies before publishing this notice. |

Data may remain at a connected provider under its own terms after deletion on your Mac. Disconnect a provider in EchoPaw and revoke access in the provider’s account settings. Clear data from Logs & Privacy or remove the app and its data using the [uninstall guide](../../apps/docs/src/content/docs/start/install.md#uninstall-and-remove-data). Ask the stream operator about data used or exposed on their stream and the provider about copies held by that provider.

[OpenAI API data controls](https://developers.openai.com/api/docs/guides/your-data) · [Twitch Developer Agreement](https://legal.twitch.com/legal/developer-agreement/) · [ElevenLabs Privacy Policy](https://elevenlabs.io/privacy-policy) · [Service disclosures](third-party.md)

## Owner review before publication

- [ ] Supply a confirmed MrDemonWolf, Inc. public privacy contact and, where required, legal address, local representative and complaint route. Assign who responds to project and website requests.
- [ ] Map controller and provider roles for distribution, website access logs, streamed data, support requests and opt-in viewer memory. Confirm applicable laws, purposes and legal bases, retention, transfers/safeguards and rights contact per processing activity. Local control does not eliminate duties for a stream operator processing viewer data.
- [ ] Verify exported fields, no recordings, data deletion and revocation, session retention, database backup behavior, and actual traffic from a fresh install. Set exact retention and effective date. Keep the docs site in sync with the release.
- [ ] Verify current policies before provider or hosted features go live. [GDPR official text, Articles 12–14](https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng/)
