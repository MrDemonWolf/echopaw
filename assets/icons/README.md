# App icon

Concept reviewed against Apple’s current guidance on 2026-11-18. The compact bubble reads as speech, the three pads as a paw, and the waveform inside the main pad as audio. The waveform is a secondary detail at the smallest sizes. Keep its heavier geometric shape and avoid extra outlines or text.

- [SVG master](echopaw.svg)
- [Light, dark and actual-size previews](icon-preview.png)
- Import layers in this order, back to front: [speech bubble](layers/01-speech-bubble.svg), [paw](layers/02-paw.svg), [waveform](layers/03-waveform.svg).

## Icon Composer setup

1. Create a new document for macOS using the 1024 × 1024 square layout. Set the full-bleed background in the tool, using a navy-900 to navy-700 gradient in Default and a darker navy-900 to navy-800 ramp in Dark.
2. Import the three SVG layers as transparent artwork. Match the master’s position using the grid if the importer trims transparent extents. Group the pads and waveform together above the bubble. Keep the flattened master’s rounded enclosure out of the import. macOS applies the platform mask.
3. Make the bubble the main material layer. Start with subtle edge/specular response, keep the dark pads opaque, and keep the waveform legible under both highlights and shadows. Adjust refraction and depth in Icon Composer. Preview the default, dark and mono appearance families, including clear/tinted variants the tool offers.
4. Save as `AppIcon.icon` and add it to the app target when the Xcode project exists. Xcode generates similar-looking imagery for previous OS releases. Verify the result on macOS 15 and on a Liquid Glass release. If the generated macOS 15 appearance fails, evaluate an AppIcon asset catalog with Apple’s required macOS sizes instead of assuming two icon sources will coexist.

Each foreground layer uses basic filled SVG shapes on the same 1024 × 1024 canvas. Apple supports SVG or PNG artwork imports, recommends vector where possible, and recommends applying visual effects in Icon Composer. The current standalone download lists macOS 26.4 or later as its authoring requirement. That is distinct from EchoPaw’s deployment target. [Apple Icon Composer](https://developer.apple.com/icon-composer/) · [Xcode icon workflow](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer) · [Apple App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons/)

## Readability check

The proof sheet places exports on light and dark surfaces at 160 px, then at 16, 32, 64 and 128 px at native scale. At 16 px the bubble reads first and the paw is small but distinguishable. At 32 px the paw is distinct and the wave is faint. At 64 px the waveform reads on both surfaces. Keep color from carrying the identity on its own. Recheck at 1× and 2× in Finder, Dock and Spotlight after the project integrates the icon. These are static concept renders. Composer materials, generated compatibility artwork, and Dock rendering remain unverified.
