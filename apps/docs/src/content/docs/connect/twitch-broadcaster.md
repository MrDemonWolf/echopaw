---
title: Connect the Twitch broadcaster
---

## Set the public client ID once

This source build needs a Twitch application registered as a **Public** client. Both the broadcaster and bot use its client ID. Use an EchoPaw registration you control.

1. Sign in to the [Twitch developer console](https://dev.twitch.tv/console/apps) with two-factor authentication enabled. Register an application or manage an existing public client.
2. If the registration form requests a redirect URL, Twitch’s example uses `http://localhost:3000`. Device sign-in completes on Twitch’s activation page and does not start a local web server.
3. Copy the **Client ID**. Under **Settings** in the EchoPaw sidebar, select **Twitch**. Paste the ID into **Public client ID** and choose **Save**. EchoPaw needs no client secret. [App registration](https://dev.twitch.tv/docs/authentication/register-app/) · [Device Code Grant](https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#device-code-grant-flow)

## Sign in as the channel owner

1. Choose **Connect broadcaster**. EchoPaw displays a short-lived code.
2. Choose **Open Twitch**. Check the account in your browser, enter the code if requested and approve. Only enter a code you just requested in EchoPaw.
3. Return to the **Twitch** page in EchoPaw and look for **Connected as** with your channel login. **Cancel sign-in** ends a pending attempt. If the code expires, start again.

The broadcaster sign-in requests identity only. Sign-in leaves live events, chat output and cloud replies off. To switch accounts, disconnect the saved role before connecting again. Review grants in [Twitch Connections](https://www.twitch.tv/settings/connections). [Connect the separate bot](/connect/twitch-bot/)
