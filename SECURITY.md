# Security Policy

## Scope

Focus is an offline-first app. User data is stored locally using Hive.  
Current security scope includes:

- Local data storage safety
- Dependency hygiene
- Release artifact integrity

## Data Handling

- Focus does not require user accounts.
- Focus does not send analytics/telemetry by default.
- Task and preference data are stored on-device in app support storage.

## Supported Versions

Security fixes are applied to the latest public release branch/tag.

## Reporting a Vulnerability

If you find a security issue, do not open a public issue with exploit details first.

1. Email: `security@appaxaap.com` (or open a private security advisory on GitHub)
2. Include:
   - Affected version/tag
   - Platform (Linux/Windows/Android)
   - Reproduction steps
   - Impact assessment
3. You will receive an acknowledgment and mitigation timeline.

## Release Integrity

For each release, publish checksums (`sha256sum`) for distributables and verify before install.
