# Security policy

EchoPaw is in planning. This policy covers the planned native app, optional Stream Deck plugin, docs site and release/update infrastructure. No supported production release exists yet.

## Report privately

Email [security@mrdemonwolf.com](mailto:security@mrdemonwolf.com) using the existing MrDemonWolf security contact. GitHub private vulnerability reporting can be another route once maintainers enable it and verify the **Report a vulnerability** button appears. Keep vulnerability details out of public issues.

Include the affected revision or version, observed impact, relevant environment, and sanitized evidence sufficient for maintainers to investigate. Remove live secrets and other people’s data. Maintainers coordinate disclosure and credit preferences in the private thread.

## Trust boundaries

- Treat chat, event payloads, model output, imported packs, IPC callers, local files and downloaded update data as untrusted. Trust only scoped credentials for their authenticated role.
- API keys and OAuth credentials belong in Keychain. Logs, exports, pack imports and IPC must never return them. Validate broadcaster and bot identity and scopes separately.
- Require PackGuard approval over final derived content before TTS and outgoing chat. If a mandatory check is unavailable, keep live output closed. Budget and emergency stop gates apply across every caller.
- Local voice activity stays on device. Mic and cloud transcription controls require explicit permission and visible state. Retain no recordings by default.
- Accept only bounded, validated pack files and narrow, authenticated IPC commands. Updates need Developer ID signing and Sparkle signature verification as designed.
- Report unauthorized speech or chat, privacy leaks, credential exposure, bypass of required safety/budget controls, untrusted file handling, authorization failures, and update-chain integrity issues.

[Privacy draft](docs/legal/privacy.md) · [Planned update trust](docs/architecture/distribution.md) · [GitHub private reporting configuration](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/configure-vulnerability-reporting/configure-for-a-repository)
