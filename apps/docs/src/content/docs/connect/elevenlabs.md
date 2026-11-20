---
title: Save an ElevenLabs key
---

1. Sign in to ElevenLabs and create a dedicated key in [API Keys](https://elevenlabs.io/app/api/api-keys). You can limit its permissions and credit usage. [Authentication guide](https://elevenlabs.io/docs/api-reference/authentication)
2. Give the key **Voices read** access. Under **Settings** in the sidebar, select **API Keys**. Choose **Add key…** beside ElevenLabs, paste the key and choose **Check and save**.
3. Look for **Key saved**. EchoPaw checks the voice-list endpoint before writing to this Mac’s Keychain. This checks read access without synthesizing speech. **Preview talking** plays the bundled local sample line. [List voices](https://elevenlabs.io/docs/api-reference/voices/search)

**Replace…** updates the key in this Mac’s Keychain. **Remove…** deletes the local copy. Revoke it in the ElevenLabs dashboard to invalidate it everywhere.

Cloud speech and voice selection are pending. Use ElevenLabs Free only for private noncommercial testing unless ElevenLabs grants you other rights. Before a monetized stream, confirm commercial rights for your plan and selected voice. [Plans and commercial licensing](https://elevenlabs.io/pricing)
