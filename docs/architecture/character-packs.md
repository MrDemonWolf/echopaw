# EchoPaw character pack format

Specification proposal, 2026-11-18. An artist can start with a folder containing `idle.png` and `talking.png`. Export both with the same canvas, transparent background and registration. Align faces and body positions in the source art. The app icon and shipped example art have their own sources and licenses.

```text
Example Character/
  idle.png
  talking.png
  manifest.json       optional for basic import
  art/
    blink.png         optional
    muted.png         optional
    glasses.png       optional
    attentive.png     optional
    raincoat-idle.png optional
    raincoat-talking.png optional
```

## Format v1

The importer infers the canvas and title from the two files and folder name when the manifest is absent. The exporter writes a manifest to make shared packs self-describing. The required images remain at the folder root to keep manual inspection and editing simple.

```json
{
  "version": 1,
  "name": "Example Character",
  "canvas": { "width": 1024, "height": 1024 },
  "blink": { "image": "art/blink.png", "minimumMs": 3000, "maximumMs": 6500, "holdMs": 110 },
  "muted": "art/muted.png",
  "expressions": {
    "attentive": { "idle": "art/attentive.png" }
  },
  "outfits": {
    "raincoat": { "idle": "art/raincoat-idle.png", "talking": "art/raincoat-talking.png" }
  },
  "anchors": {
    "eyes": { "x": 0.5, "y": 0.38 }
  },
  "props": {
    "glasses": { "image": "art/glasses.png", "anchor": "eyes", "scale": 0.72, "rotationDegrees": 0 }
  },
  "attribution": "Artwork by Example Artist"
}
```

- `version` is the integer format version. Reject unsupported versions with an upgrade hint. `name` is a printable display string, maximum 80 graphemes. `canvas` width and height are positive integer pixels, with each dimension ≤2048 and the same dimensions as both required images. Unknown fields are inert.
- All art references are pack-relative PNG paths. Base, alternate full states, blink and mute share the full canvas dimensions. Individual props may be smaller. Anchor coordinates are normalized with top-left origin. Prop center aligns to its anchor, scale is relative to the asset's native pixel dimensions in the canvas, and positive rotation is clockwise in canvas coordinates. Missing prop anchor defaults to canvas center. Restrict edit inputs to finite values, positions within the canvas and scale 0.05–4.
- `expressions` and `outfits` are maps keyed by stable lowercase IDs with letters, digits, underscores or dashes. Each entry may specify `idle` and `talking` full-state replacements. An expression-specific pose wins when present, then the outfit pose, then the base pose. Render optional prop overlays in stable manifest-independent ID order initially. `attribution` is optional plain text, up to 500 graphemes. Display it on pack information and preserve it on export.
- `blink` timings are optional integers in milliseconds. Defaults are 3000–6500 between start times and 110 hold time. Constrain delays to 1000–30000 and hold to 60–400, with maximum ≥ minimum. Use the frame only in baseline idle when no other expression overrides it and Reduce Motion is off. A closed-eye PNG is sufficient for a two-state blink. Idle and talking alone cannot reveal reliable eye geometry or reconstruct closed-eye art. A simple whole-sprite movement is a separate effect.
- User-chosen mute always stops speech. In the renderer, custom mute art wins, then idle with an optional adjustable tape prop or visible mute indicator. If a requested optional pose or prop is missing or cannot decode, show a warning and continue with the next valid state. Missing or mismatched required art fails import and identifies the specific file with a repair hint. Keep the two required bitmaps ready and swap state from playback.

The first reader and editor can support the base files, canvas and attribution. Implement optional blink, expressions, outfits and props when their editor and export behavior pass checks. If a pack contains valid unsupported fields, show which features this build can display and preserve safe references and metadata when re-exporting. Future particle-like effects use fixed native presets with bounded duration and count. Omit external URLs, scripts, fonts, embedded actions and provider credentials.

## Import and export

1. Offer **Choose folder** and drag/drop of one folder. Preview required asset validation, alpha warnings, actual dimensions and mapped states before replacement. Use SwiftUI file import scope only during the copy and balance any successful start with a stop. The copied pack can survive moving or deleting the original. [Apple fileImporter](https://developer.apple.com/documentation/swiftui/view/fileimporter(ispresented:allowedcontenttypes:oncompletion:)), [Apple scoped URL access](https://developer.apple.com/documentation/foundation/nsurl/).
2. Stage files beneath an app-owned temporary directory adjacent to Application Support/EchoPaw/Characters. Validate regular source files and reject symlinks or non-regular entries on accepted paths. Reject absolute paths, dot segments, separators in individual names, drive prefixes, control characters, overlong components and case-folded/normalized collisions. Only copy referenced assets plus recognized base files. For explicit filenames, accept ASCII letters, numbers, dots, dashes and underscores. Verify opened files remain within the selected root using directory-relative no-follow reads, then inspect the staged copies. Persist a generated local UUID and atomically install the pack when all required files pass. Keep the previous pack active on cancellation, disk-full or validation failure.
3. Verify image content with Image I/O, including PNG type, dimensions and single-frame count before full decoding. Enforce proposed caps of 64 files, 16 MiB per PNG, 80 MiB total compressed and 64 KiB for the manifest. Bound decoded working art to 64 MiB at one time, avoid preloading optional states, and downsample previews separately. A single 2048 × 2048 RGBA8 image takes about 16 MiB before renderer/cache overhead. Additional backing surfaces count toward the app memory budget. Treat valid opaque art as an import warning and show the background issue against a checkerboard. [Apple Image I/O image sources](https://developer.apple.com/documentation/imageio/cgimagesource).
4. Export a new, portable folder with the referenced images, manifest and artwork attribution/license if supplied. Preserve original asset bytes after validation and keep a separate preview cache. Export excludes local IDs, secrets, Brain profiles, logs and viewer data. Folder export/import is the first portable pack format. Defer ZIP support until requested, with bounded inflating, path checks and archive entry validation before enabling it.

## Editor and checks

Lock the rendered canvas across all states. Add a checkerboard and toggle between idle and talking, a registration crosshair, and side-by-side warnings when visible bounds shift unexpectedly. Internal canvas is fixed and source placement in OBS is separate. For a prop or mute tape, offer drag/resize/rotate plus labeled X/Y, scale and rotation controls, arrow-key nudging and reset. State changes never resize or recenter the OBS canvas. Confirm keyboard-only operation and VoiceOver reading of position fields and validation errors.

Validate import/export round trips, absent or corrupt optional art, required size mismatch, cache eviction and no position shift. Include hostile test fixtures with symlinks, path escapes, duplicate paths, truncated images, oversized dimensions, APNG, unsupported versions and partial writes. Test representative transparent, semitransparent and opaque edges in the OBS spike. Pack limits and edge quality remain acceptance targets.
