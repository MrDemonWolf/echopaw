# Audio output and OBS routing

Research checked 2026-11-18. System Default is the first-run route. Physical and virtual devices use the same EchoPaw picker. A local test clip and EchoPaw gain control work independent of TTS provider credentials.

## Choose one speech feed into OBS

| Route | EchoPaw output | OBS setup | Streamer monitoring |
| --- | --- | --- | --- |
| Basic, no virtual driver | System Default, usually headphones or speakers | Add **macOS Audio Capture**, choose application mode and select EchoPaw. Capture game audio separately from the game or capture card. Mute the audio row from the mascot window source if it also carries EchoPaw. Disable any all-desktop capture that also includes the mascot. | Hear the normal system output. Keep OBS monitoring off for this source. |
| Physical output | Select headphones, USB interface or other available output | Try the same per-app source and verify with a local recording. Per-device output capture compatibility requires hardware testing. | Hear the selected physical output. |
| Isolated loopback | Select BlackHole 2ch inside EchoPaw. Keep macOS Sound Output pointed to the physical listening device. | Add **Audio Input Capture** and select BlackHole 2ch. Disable any second EchoPaw feed. Confirm game and mic still have their own paths. | Optional **Monitor and Output** to physical headphones. Select the physical device as OBS Monitoring Device. |

OBS documents desktop or per-application audio via macOS Audio Capture on OBS Studio 30+ and macOS 13+. Its macOS Screen Capture source can also carry audio. A recording is the acceptance test for whether the chosen sources are isolated. Use **Monitor Off** if hearing the direct output. When using loopback, never monitor into that loopback device or into a multi-output device containing it. Avoid capturing the monitor output again. The normal path requires only EchoPaw and OBS. [OBS macOS audio guide](https://obsproject.com/kb/macos-desktop-audio-capture-guide), [OBS audio mixer](https://obsproject.com/kb/audio-mixer-guide), [BlackHole direct application routing](https://github.com/ExistentialAudio/BlackHole#route-audio-between-applications), [Apple Audio MIDI Setup](https://support.apple.com/guide/audio-midi-setup/play-audio-through-multiple-devices-at-once-ams7c093f372/mac).

BlackHole is an optional independently installed driver. It cannot isolate speech if the entire Mac is configured to use it as the system output. Direct output to a single virtual device keeps EchoPaw as the sole intended sender. A dedicated multi-output device may duplicate EchoPaw for hardware monitoring, but adds sample-rate and clock configuration. Start with OBS monitoring and recommend wired headphones near an active microphone.

## Core Audio and playback

1. Enumerate devices through the Core Audio HAL. Query device list, default input/output, input/output stream configuration, device UID and alive state. Filter by direction and live channels. Store the UID for an explicit choice and a separate System Default case. Current object IDs are runtime handles, so resolve the UID again after device events. Observe default and inventory changes with property listeners and remove listeners on shutdown. Refresh and validate routes on wake. [Apple Core Audio functions](https://developer.apple.com/documentation/coreaudio/core-audio-functions), [Current default output and device lookup](https://developer.apple.com/documentation/coreaudio/audiohardwaresystem), [Device alive property](https://developer.apple.com/documentation/coreaudio/kaudiodevicepropertydeviceisalive).
2. Prototype short approved audio clips with `AVAudioPlayer` from in-memory data. The macOS SDK exposes `currentDevice` for a Core Audio UID. Verify the default-player path, explicit UID and per-app OBS capture with a physical and virtual route. Apply volume at the player. This is a small baseline for measuring the benefit of streaming. [Apple AVAudioPlayer](https://developer.apple.com/documentation/avfaudio/avaudioplayer), [Apple currentDevice](https://developer.apple.com/documentation/avfaudio/avaudioplayer/currentdevice).
3. If provider streaming materially improves speech onset, use one `AVSampleBufferAudioRenderer` with `AVSampleBufferRenderSynchronizer` as the first streaming candidate. It exposes `audioOutputDeviceUniqueID` and uses default output when nil. Feed supported PCM as timestamped sample buffers with a bounded preroll and backpressure. Keep one current utterance and one renderer. If mixing or DSP needs emerge, compare an `AVAudioEngine` and player node feeding a supported output unit. Validate device binding and configuration changes against the SDK and hardware before adopting that graph. [Apple renderer device identifier](https://developer.apple.com/documentation/avfoundation/avsamplebufferaudiorenderer/audiooutputdeviceuniqueid), [Apple sample-buffer playback](https://developer.apple.com/documentation/avfaudio/audio_engine/playing_custom_audio_with_your_own_player), [Apple AVAudioEngine](https://developer.apple.com/documentation/avfaudio/avaudioengine).

## Switching and recovery

- **System Default changed:** cancel the current clip during reconfiguration, rebuild against the new default and verify the route. Resume only with new eligible speech. Do not replay the interrupted clip.
- **Explicit device disconnected:** immediately stop playback and cancel queued voice work. Persist the chosen UID as missing. Show **Device disconnected** and offer **Use System Default**, **Choose another device** and **Test audio**. An explicit virtual route never silently falls back to speakers. On reconnect, show the device as available again and require an explicit resume.
- **Manual output switch:** stop, flush and increment the output generation before switching. Ignore late callbacks. Return to idle until the new device is ready. App gain stays bounded, with a separate hard speech mute. A bundled short test signal respects mute and gain and requires an explicit click.

## Recording checklist

- [ ] Trigger an offline test signal. Only the intended EchoPaw audio meter moves and OBS playback contains one copy.
- [ ] Play gameplay audio and speak into the mic separately. The mascot meter stays quiet for both.
- [ ] Turn monitoring on only in the loopback setup. Verify no second meter activity or delayed echo. Turn it off and confirm recording still contains speech.
- [ ] Test a wired headset, USB interface, Bluetooth output and BlackHole 2ch where available. Switch output during speech, unplug the selected route and reconnect, sleep and wake, and change System Default.
- [ ] Record device type, drift or dropout, exact fallback behavior, and p50/p95 first-sound and stop timing. Proposed local targets are first audio ≤150 ms p95 after decoded audio is ready and emergency silence ≤150 ms p95 on wired output. Keep cloud calls in a separate timing report.

These are design and test instructions. No OBS or audio device tests were run.
