import type { APIRoute } from "astro";
import icon from "../../../../assets/icons/echopaw.svg?raw";

export const GET: APIRoute = () => new Response(icon, {
  headers: { "Content-Type": "image/svg+xml" },
});
