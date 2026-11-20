# EchoPaw for macOS

The offline preview is a Swift 6 and SwiftUI app for Apple Silicon on macOS 15 or later. Its checked-in Xcode project and shared scheme follow the [WolfWave-based architecture](../../docs/architecture/native.md).

## Build and run

With full Xcode selected, run from the repository root:

```sh
./scripts/run-native.sh
```

The script builds and opens the ad hoc-signed Debug app. If a previous build is open, quit it before rerunning the script to try the new binary.

1. Start with the bundled sample or select **Import character…** and choose a folder containing two identically sized static PNGs named `idle.png` and `talking.png`. Add aligned `blinking.png` and `talking-blinking.png` for optional blinking. EchoPaw keeps one local imported character. A successful reimport replaces the stored images together.
2. Choose **System Default** or an explicit **Device**, set the volume, then select **Test output**. The mascot uses its talking pose during playback.
3. Select **Show mascot window** for the dedicated **EchoPaw Mascot** capture window. Turn on **Use green screen** to try OBS's Chroma Key filter.
4. Select **Emergency stop** to stop the clip and latch mute. **Resume preview** restores the controls. Unmute explicitly before testing audio again.

The sample uses four original blue radio-host poses. **Auto-blink** controls the short, irregular blink. macOS Reduce Motion pauses it.

The preview uses a local test sound and does not request microphone or screen capture access. A connected OBS scene can still capture its window or sound. Rehearse in a local recording.

## Run the unit tests

```sh
xcodebuild -project apps/native/EchoPaw.xcodeproj -scheme EchoPaw \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath apps/native/DerivedData test
```

## Capture and audio validation

In OBS Studio 30 or later, add **macOS Screen Capture** in **Window Capture** mode and select **EchoPaw Mascot**. Compare transparent and green-screen modes against a contrasting background. Add a separate **macOS Audio Capture** source for EchoPaw and disable any overlapping window or desktop audio. Record one game sound and one EchoPaw test as separate sources. Repeat with an explicit physical device and a virtual device if available. Unplug the selected output during a test and check the app prompts for a deliberate route choice before the next playback.

See the [audio-routing spec](../../docs/architecture/audio-routing.md) and [OBS capture guide](https://obsproject.com/kb/macos-desktop-audio-capture-guide). macOS 15 runtime, physical hotplug, BlackHole, OBS recording, and Developer ID distribution are separate validation steps.
