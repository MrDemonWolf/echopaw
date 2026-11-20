---
title: Save an OpenAI key
---

1. Create a dedicated project key in your [OpenAI API dashboard](https://platform.openai.com/api-keys). Keep the key private.
2. Give the key read access to **Models**. In **Settings > API Keys**, choose **Add key…** beside OpenAI, paste the key and choose **Check and save**.
3. Look for **Key saved**. EchoPaw checks the model-list endpoint before writing to this Mac’s Keychain. The check uses no text generation and establishes only the key’s current access to the model list. If a replacement fails the check, the previous key stays saved.

![API Keys settings showing Key saved, Replace and Remove for a synthetic OpenAI key.](../../../../../../docs/onboarding/screenshots/api-keys.png)

Use **Replace…** to check a new key or **Remove…** to delete the local copy. To invalidate a key everywhere, revoke it in the OpenAI dashboard. Cloud dialogue, moderation and model selection are pending. [OpenAI key guide](https://developers.openai.com/api/docs/guides/api-keys) · [Model list endpoint](https://developers.openai.com/api/reference/resources/models/methods/list/)
