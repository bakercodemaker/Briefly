# Keep Briefly local-first

## Status

Accepted — 2026-08-27

## Decision

Briefly is a local-first portfolio application, not a hosted SaaS. Native Rails with SQLite and Solid Queue is the supported runtime for durable local Brief generation. Docker Compose remains an optional local development path, while PostgreSQL, Render/Neon configuration, and hosted-production concerns are out of scope. The password-gated Personal Workspace is the sole product mode; README screenshots explain the completed experience to reviewers.

## Considered Options

- Docker and PostgreSQL as the required runtime stack
- Rails' in-process async adapter, accepting lost jobs on restart
- Hosted Render/Neon deployment

## Consequences

The project is portable and inspectable with a local SQLite database and an explicit jobs process. It does not target horizontal scale or public deployment. Docker can still help a contributor reproduce the local environment, but it is not required for the application architecture.
