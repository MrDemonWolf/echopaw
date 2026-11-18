# EchoPaw for macOS

Swift 6 and SwiftUI app plan for Apple Silicon on macOS 15 or later. The Xcode project and targets are pending the planning review.

The [native architecture](../../docs/architecture/native.md) maps the proposed layout to WolfWave's committed Xcode project, shared scheme, `Core`, `Views`, `Services`, `Resources`, and separate test folder. Use `EchoPaw.xcodeproj` as the project source, `EchoPaw/` for app code and resources, and `EchoPawTests/` for deterministic unit tests.

## First build after scaffolding

Run from the repository root on an Apple Silicon Mac with the selected full Xcode toolchain.

```sh
xcodebuild -version
xcodebuild -list -project apps/native/EchoPaw.xcodeproj
xcodebuild -project apps/native/EchoPaw.xcodeproj -scheme EchoPaw -destination 'platform=macOS,arch=arm64' test
```

The initial app and unit tests should run on a clean checkout without provider credentials. Use a signed render-only build on a macOS 15 Mac to verify the [character pack](../../docs/architecture/character-packs.md), transparent window capture and [audio routes](../../docs/architecture/audio-routing.md) before enabling providers. The commands are planned entry points and have not been run against an EchoPaw Xcode project.
