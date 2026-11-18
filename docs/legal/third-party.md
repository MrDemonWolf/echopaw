# Third-party services and attribution

Reviewed on 2026-11-18. List package versions and license notices from actual lockfiles and outputs for each release. This is a planning inventory for owned app features and upstream integrations.

| Project or provider | Use | Release requirement |
| --- | --- | --- |
| [Sparkle](https://github.com/sparkle-project/Sparkle/blob/2.x/LICENSE) | Native update framework | Preserve MIT notices and other bundled notices from the resolved release. Record the exact version and shipped framework evidence. |
| [Montserrat](https://github.com/JulietaUla/Montserrat/blob/master/OFL.txt), [Roboto](https://github.com/googlefonts/roboto-3-classic/blob/main/OFL.txt) | Branded headings and body | Track exact font files and versions. Carry the license from the actual source used, including attribution and any reserved name terms. Prefer self-hosted web font files if shipping fonts. |
| [Twitch Developer Agreement](https://legal.twitch.com/legal/developer-agreement/) | OAuth and enabled chat/events | Review constraints on third-party sharing of Twitch data and derivatives before any cloud moderation, chat generation, or TTS containing Twitch data. Keep the unconfirmed paths disabled. |
| [OpenAI Services Agreement](https://openai.com/policies/services-agreement/), [API key guidance](https://help.openai.com/en/articles/5112595-best-practices-for-api-key-safety) | Optional cloud moderation and dialogue | Verify public desktop BYOK support and use user-owned projects and Keychain. No app-owned credential. Confirm permitted content and retention configuration. |
| [ElevenLabs billing and licensing](https://elevenlabs.io/docs/overview/administration/billing), [Terms](https://elevenlabs.io/terms-of-use) | Optional voice output | Verify plan, generation rights, voice permissions and context of use. Free is noncommercial and carries attribution requirements. Recheck rights on plan or voice changes. |
| [OBS Studio](https://github.com/obsproject/obs-studio), [BlackHole](https://github.com/ExistentialAudio/BlackHole) | User-installed capture and optional routing | Link to official releases and setup. The base app ships without a virtual audio driver. Review licenses before any future redistribution. |
| [Elgato Stream Deck SDK](https://docs.elgato.com/streamdeck/sdk/introduction/getting-started/) | Optional plugin | Inventory SDK dependency licenses and distribution terms when a plugin exists. |
| [GitHub](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement), [Cloudflare](https://www.cloudflare.com/privacypolicy/) | Proposed release or docs hosts | Verify actual hosts, privacy notices, retention and DNS before publication. |

Record links or license files for bundled Swift packages, build tool/runtime packages, fonts, UI icons, demo PNGs, sound samples and any plugin dependencies. Prefer original assets with documented author permission for the sample pack. The source license in this repo does not confer rights to a user’s imported art, voice, or other media. Provider APIs and their output retain their own licensing conditions.
