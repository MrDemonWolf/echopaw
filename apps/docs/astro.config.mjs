import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

export default defineConfig({
  site: "https://echopaw.mrdemonwolf.dev",
  integrations: [
    starlight({
      title: "EchoPaw",
      logo: { src: "../../assets/icons/echopaw.svg" },
      disable404Route: true,
      description: "Setup and troubleshooting for the planned EchoPaw macOS streaming companion.",
      social: [{ icon: "github", label: "GitHub", href: "https://github.com/MrDemonWolf/echopaw" }],
      customCss: [
        "@fontsource-variable/montserrat/wght.css",
        "@fontsource-variable/roboto/wght.css",
        "./src/styles/brand.css",
      ],
      sidebar: [
        { label: "Start here", items: ["start/five-minute-setup", "start/install", "start/advanced-setup", "start/interface-preview"] },
        { label: "Connect services", items: ["connect/twitch-broadcaster", "connect/twitch-bot", "connect/openai", "connect/elevenlabs"] },
        { label: "Character", items: ["character/import", "character/images", "character/expressions", "character/props-outfits"] },
        { label: "Stream setup", items: ["stream/microphone", "stream/keyword", "stream/audio", "stream/obs", "stream/stream-deck"] },
        { label: "Reference", items: ["reference/packguard", "reference/cost", "reference/troubleshooting", "reference/faq", "reference/privacy", "reference/design-system"] },
        { label: "Developers", items: ["develop/installation", "develop/contributing", "develop/releases"] },
      ],
    }),
  ],
});
