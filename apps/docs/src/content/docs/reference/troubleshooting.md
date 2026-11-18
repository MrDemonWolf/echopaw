---
title: Troubleshooting
---

| What you see | Try this first |
| --- | --- |
| The character jumps | Export both PNGs on the same canvas with the same anchor, then [import](/character/import/) again. |
| OBS shows a blank window | Confirm screen capture permission and the selected mascot window, then follow the [OBS test](/stream/obs/). |
| Mascot voice plays twice | Disable overlapping desktop or window audio. Check the recording track assignments. |
| A headset disconnects | Confirm the replacement output and rerun [the sound test](/stream/audio/). |
| The mic never reacts | Confirm the selected input, macOS permission and activity meter. Retry with a physical mic. |
| Keyword recognition is unreliable | Use headphones, choose a distinct phrase and try [push-to-talk](/stream/keyword/). |
| Twitch stopped sending events | Check the connection and requested scopes. Reconnect the affected identity. |
| Speech stopped but the overlay works | Inspect [PackGuard](/reference/packguard/), mute, the queue and provider budgets before reconnecting. |
| An API test fails | Verify provider status, valid scoped keys, model or voice access and billing. Keep live output paused. |

For help, share app and OS versions, a timestamp and short redacted steps in the [GitHub issue tracker](https://github.com/MrDemonWolf/echopaw/issues). Report security concerns using the [security policy](https://github.com/MrDemonWolf/echopaw/blob/main/SECURITY.md).
