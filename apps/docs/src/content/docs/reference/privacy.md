---
title: Security and privacy
---

EchoPaw plans to keep credentials in macOS Keychain and store character assets and settings locally. EchoPaw needs no hosted user account. App logs and exports are designed to exclude secrets and raw chat or microphone content.

| Feature | Planned data path |
| --- | --- |
| Offline preview | Local images and a local test sound. |
| Twitch connection | Twitch sends authorized channel events. Those events stay local until any further processing is cleared. |
| Cloud dialogue and moderation | Minimum approved text goes to OpenAI. |
| Speech | Only the approved voice line and synthesis settings go to ElevenLabs. |
| Activity reactions | Audio stays on your Mac and is discarded. |
| Keyword recognition | Local where supported. An explicitly initiated voice question may send recognized text to OpenAI after consent and required checks. Any future cloud audio transcription mode requires separate consent. |
| Viewer memory | Off by default. Optional short local summaries require opt-in and deletion controls. |

To revoke access, disconnect the service in EchoPaw and revoke its credential with the provider as appropriate. See the [privacy draft](https://github.com/MrDemonWolf/echopaw/blob/main/docs/legal/privacy.md) and [security policy](https://github.com/MrDemonWolf/echopaw/blob/main/SECURITY.md).
