---
title: Set up OBS
---

Start with native per-app audio capture in OBS Studio 30 or later on macOS 15 or later. This path uses no virtual audio driver. The mascot window was recorded with transparency on OBS 33.0.1 and macOS 27.0.1.

1. In EchoPaw, select **Show mascot window**. In OBS, add **macOS Screen Capture** in **Window Capture** mode and choose **EchoPaw Mascot**. Grant OBS the relevant macOS capture permission. Test alpha against a contrasting scene. If your capture shows an opaque background, try **Settings > Audio & capture > Use green screen** with the [OBS Chroma Key filter](https://obsproject.com/kb/chroma-key-filter).
2. Add **macOS Audio Capture** in application mode and choose **EchoPaw**. Capture the game through its own source. Disable overlapping audio from the mascot window capture or all-desktop source if they also carry its voice.
3. Record locally. Play your game, speak into your mic and trigger a mascot line separately. Each should move only its intended mixer meter and the recording should contain one copy of each voice.
4. If per-app capture fails, keep macOS output on a physical device and [route only EchoPaw](/stream/audio/) to [BlackHole](https://existential.audio/blackhole/). Add BlackHole as **Audio Input Capture** and disable duplicate per-app or window audio. For headphone monitoring, set the OBS monitoring device to physical headphones and use **Monitor and Output** on the BlackHole source.

```text
EchoPaw voice -> OBS mascot source
Game audio   -> OBS game source
Your mic     -> OBS microphone source
```

See the [OBS macOS capture guide](https://obsproject.com/kb/macos-desktop-audio-capture-guide).

## Troubleshoot the picture

- **Controls or landscape in the recording**. Set the source to Window Capture and select **EchoPaw Mascot**. Application or display capture also includes the editor.
- **No mascot after an emergency stop**. Choose **Resume preview** and explicitly reopen the mascot window. Reselect the window in OBS if needed.
- **Audio plays twice**. Disable the overlapping window, desktop or monitoring source, then record another local test.
