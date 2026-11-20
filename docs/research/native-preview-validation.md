# Native preview verification

November 20, 2026. Native implementation commits `d067d28` and `dab9fa8`. Tested the local arm64 Debug app from this checkout on an Apple M1 Pro with 16 GB RAM, macOS 27.0.1 and Xcode 27.2. Verified the running process executable under `apps/native/DerivedData/Build/Products/Debug/EchoPaw.app`, its ad hoc signature and its macOS 15.0 deployment target.

## Watch the result

- [Dashboard session recording with sound](../onboarding/recordings/native-session.mp4). The 14-second window recording shows idle, manual blink, the local playback mouth, mute, emergency stop and explicit resume. Speech stays muted after resume.
- [OBS mascot-only recording](../onboarding/recordings/obs-mascot.mp4) and [closed-eye frame](../onboarding/screenshots/obs-mascot-blink.png). OBS Studio 33.0.1 used macOS Screen Capture in **Window Capture** mode, with its cursor disabled, over two independent color sources. All four recorded corners matched the respective background within one RGB level. The center retained the wolf. Over 330 video frames with Dashboard minimized, eye-region comparison found 321 open and nine closed frames across two blinks. The test used the transparent output with no key filter and silent OBS sources.
- [Light Dashboard](../onboarding/screenshots/native-dashboard-light.png), [dark Dashboard](../onboarding/screenshots/native-dashboard-dark.png), [compact light layout](../onboarding/screenshots/native-compact-light.png) and [character inspector](../onboarding/screenshots/native-character-dark.png). Inspected full and compact windows down to 590 × 492 points. Playback buttons wrap at compact width.

## Interaction and isolation

Fourteen Swift Testing cases passed in the hosted native target, including two-image import, malformed input, atomic replacement, cached pose selection, deterministic blink timing, cancelled callbacks, capture lifetime, missing route persistence, emergency stop and late microphone authorization.

After the final microphone cancellation change, all 14 passed again using the Xcode-built native and test object files in a temporary Swift Testing app runner. Both Debug and ad hoc Release compiled.

The XCUITest target compiled. Its runner timed out while enabling UI automation on this host, with developer mode disabled and an OS authorization request. No XCUITest assertion ran. Separately exercised the running app through macOS Accessibility, including native sidebar selection, capture, sound, mute, stop, deliberate resume, keyboard blink and the real folder chooser. Importing a two-PNG fixture into isolated Application Support showed **No blink artwork supplied**, played both mouth states and exposed no blink, outfit or prop control.

For the offline rehearsal, a process sandbox denied outbound IP connections. The clip played throughout the recorded workflow. A socket inspection found no Internet sockets, and the native Swift source has no provider client or network request call. The rehearsal used no credentials or provider requests.

## Resource sample

Measured the app process alone with `ps -o %cpu,rss` in a separate light-appearance Debug run with outbound IP denied, the bundled wolf, automatic blinks, System Default output, microphone off and OBS closed. The figures use RSS divided by 1024 for MiB, and the process CPU percentage reported by macOS.

| Condition | Sampling | Median CPU | CPU range | RSS range |
| --- | --- | --- | --- | --- |
| Dashboard idle after resize | 12 samples about one second apart | 0.0% | 0.0–1.2% | 120.9–122.1 MiB |
| During one local sound test | 10 samples about 150 ms apart | 10.75% | 6.6–25.7% | 128.2–131.5 MiB |

The short playback sample includes button activation and rendering. These measurements cover one machine and Debug configuration. Release performance targets require a longer controlled run.

## Outstanding checks

The supplied concept board was unavailable as an image in this session. The workspace follows its written layout brief. The two supplied Notion pages were updated. The MDW Jira search returned no matching EchoPaw issue.

Run the same capture and audio check on macOS 15. Disconnect an explicitly selected physical device mid-sound and verify silence on the speakers. Separate game/mic/mascot audio tracks, real microphone permission and keyword accuracy, VoiceOver speech, Increase Contrast on hardware, Spaces, sleep, and Developer ID distribution remain open. Emergency stop closes the capture panel, so OBS may require window reselection after resuming.
