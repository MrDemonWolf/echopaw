# EchoPaw app icon

Wolf ears signal the mascot and a blue speech bubble signals its voice. The navy tile makes the mark distinct on light and dark surfaces. The native app icon, documentation header and favicon use the same mark.

- [SVG master](echopaw.svg)
- [Flat artwork on light and dark surfaces at actual sizes](icon-preview.png)
- [Native macOS appearances rendered with Icon Composer](icon-composer-preview.png)
- Transparent source layers, back to front: [speech bubble](layers/01-speech-bubble.svg), [wolf ears](layers/02-wolf-ears.svg).

## Edit the native icon

Open [AppIcon.icon](../../apps/native/EchoPaw/Resources/AppIcon.icon) in Icon Composer from Xcode’s Open Developer Tool menu. The document has a navy canvas, separate groups for the blue speech bubble and wolf ears, and the platform mask. Keep both SVGs on the same 1024 px canvas when changing the mark. Update the [SVG master](echopaw.svg) and the two source layers above when making corresponding web artwork changes.

Xcode uses `AppIcon.icon` for the app icon and generates the raster fallback for older macOS releases. Xcode 27.2 compiled the layered icon and generated the fallback with the macOS 15.0 deployment target. Appearance previews were exported with Icon Composer’s `ictool`. Confirm the installed icon in Finder, the Dock and Spotlight on macOS 15 when testing the release. [Apple’s Icon Composer guide](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
