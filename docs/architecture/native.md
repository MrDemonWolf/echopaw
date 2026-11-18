# Native macOS architecture

Research checked 2026-11-18. Apple Silicon, macOS 15+, Swift 6 language mode, SwiftUI and Keychain are locked. The ownership and implementation sequence below are proposed. A signed prototype must verify system behavior on macOS 15 before feature work expands.

## Application structure

Use a checked-in `apps/native/EchoPaw.xcodeproj` with a shared `EchoPaw` scheme, an `EchoPaw` macOS app target and an `EchoPawTests` unit-test target. Configure Swift 6 language mode in both targets. Use explicit isolation for app state and service boundaries so the project remains legible as features arrive. [Apple Xcode project setup](https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app), [Swift 6 migration](https://developer.apple.com/videos/play/wwdc2024/10169/).

### WolfWave reference

Reviewed the committed tree at `2a9629d497b12b14ee4a357b6b4519749f95143d` on 2026-11-18. WolfWave tracks `apps/native/WolfWave.xcodeproj/project.pbxproj` and shared schemes. Its app and test directory membership uses Xcode file-system-synchronized groups. Native CI and release workflows use that project directly with `xcodebuild`. Searches of its committed native tree, workflows and Makefile found no XcodeGen setup. EchoPaw follows the checked-in project convention and uses separate synchronized roots for app and tests. Verify target membership so test fixtures never enter the shipped app. [WolfWave project](https://github.com/MrDemonWolf/wolfwave/tree/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/WolfWave.xcodeproj), [Native contributor guide](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/AGENTS.md), [CI workflows](https://github.com/MrDemonWolf/wolfwave/tree/2a9629d497b12b14ee4a357b6b4519749f95143d/.github/workflows).

```text
apps/native/
  README.md
  EchoPaw.xcodeproj/
    project.pbxproj
    xcshareddata/xcschemes/EchoPaw.xcscheme
  EchoPaw/
    EchoPawApp.swift
    Core/                    Session state, value types, settings and local paths
    Views/
      Dashboard/
      Character/
      Onboarding/
    Services/
      Characters/            Import, decode and validate packs
      Audio/                 Playback and Core Audio device observation
      Capture/               AppKit mascot panel and lifecycle
    Resources/
      Assets.xcassets/
      SampleCharacter/       Licensed two-state art for offline preview
  EchoPawTests/
    CharacterImportTests.swift
    SessionTests.swift
```

This is the target layout for the first native slices. Add provider-specific `Services/Twitch`, `Services/OpenAI` and `Services/ElevenLabs`, and local `Core/PackGuard` and `Core/Reactions`, as their gates are reached. Use `EchoPawTests/Fixtures` for synthetic import and event data when the first fixtures are needed. Add `EchoPawUITests` with a separate shared XCUITest scheme when the offline onboarding flow is stable. Use Swift Testing for new unit tests and XCTest for UI automation. The app target bundles its own sample art and assets. Keep icon master sources under `assets/icons`, published guidance under `apps/docs`, and engineering plans under root `docs`. [WolfWave source layout](https://github.com/MrDemonWolf/wolfwave/tree/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/WolfWave), [Apple Xcode testing](https://developer.apple.com/documentation/xcode/testing).

Follow WolfWave's separation of development and release identity before storing real data. Proposed bundle IDs are `com.mrdemonwolf.echopaw.dev` for Debug and `com.mrdemonwolf.echopaw` for Release, pending owner reservation. Give Debug distinct display name, Keychain service accounts and Application Support paths. Give unit tests test-only storage and fixture networking. Keep credentials in Keychain, release secrets in CI, and any shared `.xcconfig` limited to nonsecret build settings. Keep signing, DMG, notarization and appcast steps outside the app source, modeled on WolfWave's `scripts/codesign-app.sh`, `scripts/create-dmg.sh`, `scripts/notarize-dmg.sh` and `scripts/generate-appcast.sh` when release work begins. [WolfWave scripts](https://github.com/MrDemonWolf/wolfwave/tree/2a9629d497b12b14ee4a357b6b4519749f95143d/scripts), [EchoPaw distribution plan](distribution.md).

EchoPaw keeps its macOS 15 floor while the inspected WolfWave project targets macOS 26. Start with a normal SwiftUI window and a small AppKit capture bridge. WolfWave's accessory-mode lifecycle, widget, generated resource pipeline, Make wrappers and broad app-target MainActor default solve needs of its mature app. EchoPaw starts with native Xcode commands, explicit isolation and a file placed only when its feature is implemented. Use a single owner for Application Support path resolution. Fail safely when durable storage is unavailable for packs and budget state instead of persisting them to temporary storage. [WolfWave app entry point](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/WolfWave/WolfWaveApp.swift), [WolfWave storage convention](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/WolfWave/Core/AppContainer.swift).

### Runtime ownership

| Owner | Responsibility | Boundary |
| --- | --- | --- |
| App shell | Dashboard, settings, menu bar, onboarding and global stop status | Main-actor `@Observable` UI state, injected by the app into scenes. Views own transient selection and focus with `@State`. |
| Session coordinator | Arming, source events, mute, pause, output routing, cancellation and review | Serializes decisions and publishes small immutable snapshots. UI views do not call providers directly. |
| Reaction scheduler and PackGuard | Admit bounded work, enforce policy and issue one output approval | Pure rules where possible. Reserve work and spend before asynchronous provider calls. Recheck approval and generation before output. |
| Twitch, OpenAI and ElevenLabs adapters | HTTP and WebSocket IO, structured errors and usage | Async `URLSession`, narrowly typed inputs and outputs. Service states remain independent. |
| Audio input and output | Route selection, PCM or encoded clip playback, streaming buffers and device changes | Isolated device ownership and bounded handoff between callbacks and app state. [Audio](audio-routing.md) and [microphone](microphone.md). |
| Character renderer | Composites cached sprites and presents the capture window | One AppKit coordinator owns the panel and hosting view. SwiftUI owns editable character state. [Character packs](character-packs.md). |
| Local storage | Settings, copied assets, optional memories and budget counters | UserDefaults for simple preferences, Application Support for packs, Keychain for secrets. Delay database adoption until a feature needs transactional persistence. |

A checked, approved event flows from input to PackGuard, scheduler reservation, The Brain when needed, output moderation, and then a final output gate. Play one speech item at a time. Tie the talking sprite to actual playback, including stop and final drain, with an explicit state event from audio output. The renderer never infers speech from the queue or a provider request.

Use SwiftUI Observation to publish only the state a view reads. Multisecond connections and playback belong to the session coordinator and survive settings navigation. Keep audio meter updates coarse and local to the meter. Use structured tasks for bounded work and explicitly owned, cancelled tasks for connection lifetimes. After a suspension, revalidate the session revision, stop state and output generation before resuming a side effect. Account conservatively for calls that may have reached a provider before cancellation. SwiftUI and AppKit objects are main-actor-owned. Pass typed `Sendable` events across actors and keep framework buffers within a dedicated callback boundary. No network, decoding, logging or UI updates in real-time callbacks. [Observation migration](https://developer.apple.com/documentation/swiftui/migrating-from-the-observable-object-protocol-to-the-observable-macro), [Swift concurrency and isolation](https://developer.apple.com/videos/play/wwdc2025/268/).

## Windows and lifecycle

- Use a normal app window for Dashboard and setup, a SwiftUI `Settings` scene for general preferences, and a `MenuBarExtra` for speech mute, pause, listening status, emergency stop and opening Dashboard. Keep a Dock and app-menu path even if the extra is removed. The normal window may close during a session, while Quit cancels input, output, sockets and pending work. Start in an unarmed state after launch, quit recovery or restart. [SwiftUI menu bar and settings](https://developer.apple.com/documentation/swiftui/building-and-customizing-the-menu-bar-with-swiftui), [MenuBarExtra lifecycle](https://developer.apple.com/documentation/swiftui/menubarextra).
- Prototype a named borderless, nonopaque `NSPanel` with a clear background and shadow disabled. Use an `NSHostingView` for the render content. Keep a fixed canvas and optional click-through. Editing lives in Dashboard, with a visible way to show, move and hide the panel. Capture panel visibility, sleep, spaces, display changes and source re-selection are separate tests. [AppKit windows](https://developer.apple.com/documentation/appkit/nswindow), [Click-through](https://developer.apple.com/documentation/appkit/nswindow/ignoresmouseevents).
- In OBS use macOS Screen Capture in Window Capture mode and select the dedicated `EchoPaw Mascot` window. Turn off cursor capture. OBS owns macOS screen recording permissions. EchoPaw presents content for external capture and does not need to capture the display itself. Verify the captured result with a checkerboard in OBS across 1× and Retina displays. The window being transparent on the desktop does not establish that OBS preserves alpha. If needed, validate an explicit keyed background and OBS Chroma Key first. Judge edge quality against the intended art. Defer live browser sources and frame/image-sequence export until a measured capture problem justifies them. [OBS macOS Screen Capture](https://obsproject.com/kb/macos-screen-capture-source), [Apple ScreenCaptureKit sample](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-in-macos), [OBS Chroma Key](https://obsproject.com/kb/chroma-key-filter).

## Accessibility and persistence

Use native controls and menu commands with visible focus, labels and text status. Provide keyboard access to every setting and a numeric alternative to drag, scale and rotate. Keep VoiceOver announcements for status transitions, not live meter frames. Test reduced motion, increased contrast, visible selection with color filters, full keyboard navigation and VoiceOver. App shortcuts ship without Stream Deck. Optional background hotkeys need a separate minimum-OS spike for registration, conflicts, permissions and key release. [Apple accessibility guidelines](https://developer.apple.com/design/human-interface-guidelines/accessibility), [SwiftUI accessibility fundamentals](https://developer.apple.com/documentation/swiftui/accessibility-fundamentals).

Use Keychain generic password items with distinct service/account identifiers for broadcaster OAuth, bot OAuth and provider keys. Use consistent Keychain selection on reads and writes. Verify key access across a signed app upgrade and an account disconnect. Keep logs free of secrets and raw input by default. Character import copies selected files into the app-owned directory, with scope access only during reading. A later feature that deliberately references external files can justify security-scoped bookmarks and stale-reference recovery. Decide hardened runtime and sandbox behavior against the signed release, microphone access and optional IPC requirements. [Apple Keychain implementations](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains), [Apple App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), [Apple URL and bookmark access](https://developer.apple.com/documentation/foundation/nsurl/).

## Prototype evidence and proposed targets

After the planning review, use the [native build commands](../../apps/native/README.md) to verify the shared scheme and unit tests from a clean checkout with no keys or local config. Inspect the signed archive for the expected arm64 executable, macOS 15 deployment target, intended bundle ID and entitlements, and app resources. On a minimum-OS Mac, launch the signed app, import a two-state pack, check OBS capture and audio, and confirm that emergency stop prevents late output. Only then record hardware support. [Apple command-line tools](https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference).

Measure a signed release build on a base Apple Silicon Mac with macOS 15 and on a current supported release. Log machine, macOS, OBS version, audio device, scene resolution and sample count. Record process memory and CPU with Instruments and timestamps via signposts. Separate offline timing from provider round trips. Baseline OBS alone before a run with EchoPaw.

| Case | Initial target |
| --- | --- |
| Offline cold launch to usable Dashboard, 10 launches | p95 ≤ 2 s |
| Minimal idle/talking pack, established connection and microphone off, 15 min | Physical footprint p95 < 150 MB and mean CPU < 2% of one core |
| Playback start to talking pose in OBS recording, 30 transitions | p95 ≤ 100 ms |
| Emergency stop command to silence on wired output, 30 trials | p95 ≤ 150 ms |
| 60 min recording with 100 fixture utterances and reconnects | Zero overlapping clips, zero stale output after stop, no sustained memory growth > 20 MB from steady state |

No native code or benchmarks exist in this planning slice. Run the render-only capture spike, audio routing spike, signed release smoke test and accessible setup checks before claiming support.
