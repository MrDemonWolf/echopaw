# EchoPaw design system

Edit [tokens.css](tokens.css) to change the shared brand palette, text and surface roles, focus, status, corners, spacing or motion. The [docs stylesheet](../apps/docs/src/styles/brand.css) imports these tokens and maps them to Starlight. Keep framework-specific styles with the site.

- [Usage, native roles, component states, and contrast](../docs/product/design-system.md)
- [Public swatches and component examples](../apps/docs/src/content/docs/reference/design-system.mdx)
- [App icon master and Icon Composer directions](../assets/icons/README.md)

The layout follows WolfWave’s top-level design system and single token source. EchoPaw currently has one buildable consumer, so the docs can import the CSS directly. When a Swift consumer exists and shared values need to stay synchronized, move those values to a typed source and generate platform outputs for CSS and Swift. Verify generated files together once that workflow exists. [WolfWave design-system README](https://github.com/MrDemonWolf/wolfwave/blob/2a9629d497b12b14ee4a357b6b4519749f95143d/design-system/README.md)
