# Privacy

> [!CAUTION]
> **Archived project.** Development stopped on 2026-08-28 because no paid Apple
> Developer Program licence was available. A Personal Team build was installed
> on a physical Mac but rejected by TIS discovery, so live composition was not
> tested.

Google粵拼forMac is an online-first input source.

> [!NOTE]
> This document describes the archived implementation's intended data flow. The
> paid Apple Developer workflow exists in source, but the paid deployment was
> not actually tested on a machine and the input source was never activated for
> typing. Runtime privacy behavior is therefore code-reviewed and test-backed
> where possible, not live-typing verified.

## Data sent

While composing Cantonese, the current romanized query and already selected phrase context may be sent to:

```text
https://inputtools.google.com/request
```

This is required to obtain Google-ranked Cantonese candidates. Do not use this input source for text you are unwilling to send to that service.

## Local data

Candidate responses are cached in the app sandbox as SQLite data for up to 30 days. The cache supports faster responses and previously retrieved candidates while offline.

## Not collected by this project

The project contains no analytics, advertising SDK, account system, telemetry endpoint, or intentional composition logging. macOS and Google remain subject to their own privacy policies.
