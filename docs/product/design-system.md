# EchoPaw design system

See the [light appearance screenshot](../onboarding/screenshots/design-system-light.png) for the palette and component examples in the docs.

The [shared stylesheet](../../design-system/tokens.css) is the source for the docs and generated native tokens. See the [native component catalog and generation commands](../../design-system/README.md). Native menus and form controls use platform styling. The [public examples](../../apps/docs/src/content/docs/reference/design-system.mdx) use the same palette.

## Foundations

| Foundation | Use |
| --- | --- |
| Color | Navy 900 `#0A1633`, Navy 800 `#0D2A56`, Navy 700 `#0D4D8C`, Blue 600 `#1178B8`, Blue 500 `#1795D2`, Blue 400 `#3AAEE3`. Use darker navy for copy, bright blue as an accent, and off-white surfaces in light appearance. Status colors are functional and carry text labels. |
| Typography | Montserrat 600–700 for branded headings, Roboto 400–700 for branded reading and examples. Use system typography for native menus, controls, status items and settings forms. Use tabular numerals for time and costs without changing body font. |
| Spacing | Base scale 4, 8, 12, 16 and 24. Prefer 8–12 between related controls and 16–24 between sections. Measure native UI in points and the docs in rem relative to the user's base size. Let labels wrap. |
| Corners | Approximate 8 for controls, 16 for panels and 24 for feature surfaces in branded custom UI. In SwiftUI, use the platform control style for standard controls. |
| Motion | Use a 150 ms transition where movement explains a change. With Reduce Motion, use an instant change and keep the same state label. Stop and mute apply immediately irrespective of animation. |
| Icon and art | Use SF Symbols for familiar native actions with readable labels. The [app icon](../../assets/icons/README.md) pairs wolf ears with a speech bubble. A character pack preview reflects the user's own artwork or a clearly identified demo. |

## Native semantic roles

| Role | Mapping and behavior |
| --- | --- |
| Window, raised surface | Use window and control background roles in ordinary native regions. Apply `--ep-surface` and `--ep-surface-raised` direction to branded content or when a custom view needs controlled contrast. |
| Text, secondary text | Use primary and secondary system labels for common scenes. For branded surfaces, pair `--ep-text` and `--ep-text-secondary` with the intended surface in each appearance. |
| Accent, link and focus | Use native accent/selection behavior and visible system focus rings. In custom areas, use `--ep-action-bg` with `--ep-action-text` and `--ep-action-border`; links use `--ep-link` and an underline in prose. Use `--ep-focus` with clear separation from the adjacent surface. |
| Boundary and state | Use `--ep-border` for essential custom control boundaries. Use `--ep-ready-*`, `--ep-pending-*`, and `--ep-error-*` in text-labelled outcomes. Add icons only when they improve scanning. |
| Emergency action | Use `--ep-stop-*` in custom branded views. Native app supplies a labelled **Emergency stop** command with a command-menu and optional menu bar path. Keep it separate from ordinary deletion, mute, and AI pause. |

## Component states

| State | Criterion | Treatment |
| --- | --- | --- |
| Resting | Control can run now | One primary action per task. Use a secondary action for deliberate alternatives such as changing output. |
| Hover, pressed, focus | pointer, activation or keyboard focus | Keep native feedback in native controls. Custom controls preserve fill or outline contrast and add a visible focus ring. Focus never depends on hover. |
| Selected or enabled | Current persisted choice | Use persistent selection text, native checkmarks or an accessible pressed/checked value. Pending changes remain distinguishable from saved choices. |
| Verifying | Work in progress | Name the check, retain prior settings, and give Cancel where it can safely stop. Treat provider timeouts as an explicit state. |
| Ready | The relevant check passed | Report what passed, such as **Audio output verified**. Keep Preview, role authorization and actual broadcast status explicit. |
| Needs attention | User action can unblock work | Give a concise cause and one nearby action such as **Choose another output**. Offer Retry only when meaningful. Keep previously valid settings. |
| Unavailable | Required permission, information or device is absent | Give a reason next to the disabled control and link to its recovery if available. Maintain readable labels at every contrast setting. |
| Stopped | Emergency action has latched | Confirm current output state with **Stopped** text and announce one change. Discard queued work. Resume is a separate action requiring safe current conditions. |

## Contrast and verification

Static sRGB contrast ratios are rounded to two decimal places. Native materials, actual font weight and system accent selections need independent validation.

| Pair | Light | Dark |
| --- | ---: | ---: |
| Main text on page background | 16.77:1 | 14.50:1 |
| Secondary text on page background | 7.03:1 | 9.40:1 |
| Link on page background | 8.02:1 | 12.22:1 |
| Primary button text on bright blue | 7.10:1 | 7.10:1 |
| Required control border against raised background | 4.20:1 | 4.39:1 |
| Primary button boundary against raised background | 7.71:1 | 6.68:1 |
| Focus ring against raised background | 7.71:1 | 6.68:1 |
| Ready label on Ready fill | 7.06:1 | 8.01:1 |
| Verifying label on Verifying fill | 7.02:1 | 7.58:1 |
| Error label on Error fill | 7.84:1 | 7.64:1 |
| Emergency stop text on button fill | 8.72:1 | 10.65:1 |

- [ ] For custom views, meet WCAG AA equivalents for text and significant control boundaries. Check focus indicators against both the adjacent surface and selected control.
- [ ] Use macOS keyboard traversal, VoiceOver and Voice Control for all settings, menus, emergency commands and alternate numerical character placement controls.
- [ ] Test light/dark, Increase Contrast, Reduce Motion, zoomed text, and a narrow window. Try recovery states and stop while a fixture reaction is active.
- [ ] Confirm status, error, and selection meaning without color, sound, or animation. Rate-limit spoken status announcements and avoid announcing every meter tick.

[Apple accessibility guidance](https://developer.apple.com/design/human-interface-guidelines/accessibility) · [Apple macOS design guidance](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) · [W3C contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) · [W3C non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) · [Screen map](../onboarding/screen-map.md)

## Rehearsal dashboard

Show transparent pixels over a subtle checkerboard in the app preview with playback controls directly below it. Let the preview take the remaining window height. Dock playback and the audio destination across the full detail width, stacking them when their labels need more room. Keep recent activity collapsed until requested. Reserve the toolbar for session-wide actions.

The November 20, 2026 pass used the preview and transport placement in [Riverside](https://mobbin.com/screens/5f2ce98e-e3ac-4746-a64f-b1bc76d4f1cc) and [VEED](https://mobbin.com/screens/ed45c8a5-f3a0-4fe0-a1ce-9f625a0be353), alongside the [OBS rehearsal workflow](https://obsproject.com/kb/quick-start-guide). See the [running EchoPaw dashboard](../onboarding/screenshots/rehearsal-dashboard.png).

WolfWave uses a native split view with grouped destinations and a typed selection for navigation. EchoPaw uses that pattern in its main workspace. The sidebar, Setup Guide, and Command-Comma act on the same selection. [WolfWave settings source](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/apps/native/WolfWave/Views/SettingsView.swift)
