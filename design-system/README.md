# EchoPaw design system

Edit [tokens.css](tokens.css). The docs import this file directly. Its brand colors, spacing, corners and component dimensions generate the checked-in native [Swift tokens](../apps/native/EchoPaw/Core/DesignSystem/Tokens.generated.swift).

```sh
bun design-system/scripts/native-tokens.ts
bun design-system/scripts/native-tokens.ts --check
```

The generator checks required colors and resolves CSS aliases. The docs check also fails on native token drift. Preserve native control sizes, system accent, focus rings and disabled labels. Branded surfaces use adaptive navy or paper, Montserrat headings and Roboto body. The font licenses travel with the app.

## Native components

| Component | Use and states |
| --- | --- |
| Preview surface | Displays a cached pose on an adaptive landscape. The landscape belongs to the editor. The separate OBS panel draws the sprite alone. Increase Contrast strengthens the stage edge. Reduce Motion pauses automatic blinks. |
| Status row | Pairs a symbol and service name with readable connection text. VoiceOver reads the row together. |
| Session controls | Play the bundled sound, mute speech or pause automatic responses. Disabled controls reflect emergency stop, mute and unavailable routes. Resume leaves speech muted and AI paused. |
| Device picker | Uses a native menu. Keeps a disconnected device selected and shows the recovery message next to playback settings. |
| Character inspector | Owns folder import, starter selection and optional blink settings. The two-image fallback explains missing artwork. |

Open **Window > Show component gallery** in a Debug build for the live controls and labelled status examples. See the [usage and contrast guide](../docs/product/design-system.md). Repository organization, sidebar selection, a debug gallery, and generated-token checks follow patterns inspected in [WolfWave](https://github.com/MrDemonWolf/wolfwave/tree/2a9629d497b12b14ee4a357b6b4519749f95143d/design-system). EchoPaw supplies its own implementation, palette and artwork.
