# Native interface

The implemented workspace has Dashboard, Character and standard Settings. Dashboard keeps playback and session controls beside the preview. Character has its own inspector. The capture window contains the sprite alone. [Native evidence](../research/native-preview-validation.md)

The editing layout draws on a central canvas with playback controls and separate tool options. The reference screens were inspected directly. [Jitter on Mobbin](https://mobbin.com/screens/c1a132d2-1608-4f0e-bbe9-407971863344?utm_source=codex&utm_medium=ai-assistant&utm_source_platform=mcp) · [OpenAI Platform on Mobbin](https://mobbin.com/screens/09970017-5714-437b-8ba6-01d0ad9afdec?utm_source=codex&utm_medium=ai-assistant&utm_source_platform=mcp) · [Apple NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)

## Future destinations

Proposed SwiftUI layout reviewed against Apple’s guidance on 2026-11-18. Use one main `NavigationSplitView`, familiar toolbar commands and a normal Mac window. Group the sidebar by task. Put appearance, shortcuts and updates in the standard Settings window, reachable through **EchoPaw > Settings**. An optional menu bar item mirrors important actions and opens Dashboard. The separate OBS output window shows the character content only. [Interactive Dashboard prototype](../../apps/docs/src/content/docs/start/interface-preview.mdx)

```text
╭──────────────────────────────────────────────────────────────────╮
│ EchoPaw          Preview mode                     Emergency stop │
├─────────────────────┬────────────────────────────────────────────┤
│ Dashboard           │ Dashboard                                  │
│                     │                                            │
│ Mascot              │  ┌───────────────────┐  Session            │
│   Character         │  │                   │  Mode     Balanced │
│   The Brain         │  │ Character preview │  Speech   Ready    │
│                     │  │                   │  Mic      Off      │
│ Stream              │  └───────────────────┘  Twitch   Unlinked │
│   Twitch            │  [Preview reaction]     Queue    Empty    │
│   Reactions         │                                            │
│   OBS Setup         │  [Advanced Setup]        [Open overlay]   │
│                     │                                            │
│ Sound and services  │  [Mute speech]          [Pause AI]        │
│   Voice & AI        │                                            │
│   Microphone        │                                            │
│   Audio Output      │                                            │
│                     │                                            │
│ Safety and privacy  │                                            │
│   PackGuard         │                                            │
│   Budgets           │                                            │
│   Logs & Privacy    │                                            │
╰─────────────────────┴────────────────────────────────────────────╯
```

Visible session states include Preview, Ready and Session active. Show connection, OBS-capture verification, audio mute, AI pause and mic activity independently. Report Twitch broadcast state only when a reliable source confirms it, with **Unknown** otherwise. The toolbar, native menu and dashboard all call the same emergency stop. Resume is deliberate and shows the state it will restore.

| Screen | Main action | Content and recovery |
| --- | --- | --- |
| Dashboard | Preview reaction or arm a session | Status, current character, next queue item and usage estimate. Link blocking status to the relevant setting. Show a completed stop immediately and keep Resume explicit. |
| Character | Import or edit pack | Idle/talking previews and validation, placement inspector with numeric fields, optional states and export. Image controls have keyboard equivalents. On failed import retain the current pack. |
| The Brain | Edit personality and preview | Identity, speaking style, phrase examples and explicit context. Reveal data sent in a preview. Put viewer-memory permissions and deletion in Logs & Privacy. |
| Twitch | Connect a role | Separate broadcaster and bot identities with scopes, connect/disconnect, optional outgoing chat, event simulation. Show reconnect or missing scope in the affected row. |
| Voice & AI | Validate a key, test a voice | Keychain-backed masked controls, model and voice options, commercial eligibility, per-test usage warning. Distinguish public chat permitted, personal cloud test and unavailable. |
| Reactions | Choose mode and inspect a trigger | Four modes, trigger groups, output, cooldown, queue and cost allowance. Preview an event without posting or speaking on stream. Group advanced overrides to avoid a wall of controls. |
| Microphone | Choose input or disable listening | Activity and keyword controls with independent states, readable level, permission and data path, test phrase and push-to-talk where available. |
| Audio Output | Select and test | System Default or specific output, actual route, level and test clip. Show fallback choices explicitly after loss and leave speech paused until a valid route is selected or restored per the audio design. |
| PackGuard | Choose content preset or test a rule | Always-on protections, policy state, blocklists and action options. Preview the effect without generating or transmitting a message. |
| OBS Setup | Follow and verify capture steps | Open overlay, visual/audio instructions, separate checks for video alpha and audio isolation, then local recording confirmation. Avoid declaring live compatibility before user confirmation. |
| Budgets | Set caps | Usage/estimate and limits with provider rate date, next reset and most recent counted request. Unknown rate disables automatic paid streaming. |
| Logs & Privacy | Inspect or clear local data | Safe reason codes, retention, viewer memory opt-in and forget tools. Show what is in a diagnostic export before the user saves or shares it. |
| General Settings | Change app preferences | Appearance, on-launch behavior, update channel, optional menu bar, shortcuts, resume onboarding and About. Show shortcut conflicts where configured. |

## Interaction and accessibility

- Use native controls with labels, current values and visible focus. Keep tab order meaningful through sidebar, heading, fields and actions. On a narrow window collapse the sidebar and keep all commands available through the menu.
- Use standard Command-Comma for Settings and app-menu shortcuts for stop, mute, pause, and preview after conflict testing. Optional global shortcuts are a separate decision. Provide a button and menu command for every critical operation.
- Pair indicators with plain text such as **Mic off**, **Listening locally**, **Speech muted**, and **Cloud checks unavailable**. Never rely on color, animation, or audio alone. Visual metering can update continuously while VoiceOver announces meaningful changes only.
- Make click targets at least 28 × 28 pt in custom controls. Check light/dark palettes, Increase Contrast, Reduce Motion, Full Keyboard Access, VoiceOver and Voice Control. Keep critical copy visible as text scales and the app window shrinks.
- Use a plain label to identify the overlay window in the app and keep it out of the normal Tab sequence. Use an in-app editor to move or scale using keys or numeric fields. Keep overlay content separate from private setup, logs, and credentials.
- Mute, AI pause, and microphone off are different controls. Visible **Emergency stop** is immediate, has no confirmation dialog and holds stopped until a distinct action. A disconnect or provider outage shows the smallest useful recovery action.

[Apple accessibility guidance](https://developer.apple.com/design/human-interface-guidelines/accessibility) · [VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover) · [Keyboard navigation](https://developer.apple.com/design/human-interface-guidelines/keyboards/) · [Settings](https://developer.apple.com/design/human-interface-guidelines/settings) · [Setup flows](setup.md)
