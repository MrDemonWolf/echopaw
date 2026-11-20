# EchoPaw for macOS

EchoPaw is a Swift 6 and SwiftUI offline mascot preview for Apple Silicon Macs running macOS 15 or later.

## Build and run

```sh
./scripts/run-native.sh
```

Quit a running older build first. This script builds the shared Xcode scheme and opens the local ad hoc-signed app.

## Try the wolf

1. In **Dashboard**, choose **Preview talking**. A bundled sound drives the mouth. **Mute speech** stops the sound while idle blinking continues.
2. In **Character**, choose **Preview blink**. In the inspector, select two PNGs or import a folder with `idle.png` and `talking.png`. Add `blinking.png` and `talking-blinking.png` to a folder pack for closed eyes. Reduce Motion pauses automatic blinks.
3. Use **Choose output…** for System Default or an explicit device. A missing selection blocks playback until you choose a usable output.
4. **Show mascot window** opens the sprite-only panel. Choose it in OBS window capture. **Emergency stop** closes it, stops sound and mic listening, and latches speech mute. Resume and unmute deliberately.

Optional local mic controls live in Settings. The sample needs no microphone access, provider account or network service. **Window > Show component gallery** is available in Debug.

## Development checks

```sh
bun design-system/scripts/native-tokens.ts --check
xcodebuild -project apps/native/EchoPaw.xcodeproj -scheme EchoPaw \
  -destination 'platform=macOS,arch=arm64' -parallel-testing-enabled NO \
  -derivedDataPath apps/native/DerivedData test
```

See the [native evidence](../../docs/research/native-preview-validation.md) and [art provenance](../../docs/research/starter-wolf-art.md).
