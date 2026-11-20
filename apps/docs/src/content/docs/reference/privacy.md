---
title: Security and privacy
---

The current offline app uses local character files and test audio. Optional microphone activity and supported keyword detection run on this Mac. Listening stops on emergency stop. Recent activity is limited to five action labels in memory.

EchoPaw keeps saved OpenAI and ElevenLabs keys and each Twitch account’s OAuth tokens in macOS Keychain. The public Twitch client ID is an app preference. Saving an API key makes no network request. Twitch sign-in, token checks, refresh and revocation contact Twitch. The offline mascot needs no accounts.

| Feature | Data path |
| --- | --- |
| Offline preview | Local images and a local test sound. |
| Twitch connection | Twitch verifies the selected role and returns its user ID and login. Live event delivery is pending. |
| Cloud dialogue and moderation (planned) | Minimum approved text goes to OpenAI. |
| Cloud speech (planned) | Only the approved voice line and synthesis settings go to ElevenLabs. |
| Activity reactions | Audio stays on your Mac and is discarded. |
| Keyword recognition | Local where supported. An explicitly initiated voice question may send recognized text to OpenAI after consent and required checks. Any future cloud audio transcription mode requires separate consent. |
| Viewer memory | Off by default. Optional short local summaries require opt-in and deletion controls. |

To revoke access, disconnect the service in EchoPaw and revoke its credential with the provider as appropriate. See the [privacy draft](https://github.com/MrDemonWolf/echopaw/blob/main/docs/legal/privacy.md) and [security policy](https://github.com/MrDemonWolf/echopaw/blob/main/SECURITY.md).
