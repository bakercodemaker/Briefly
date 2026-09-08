# Publish Briefly as a local-first portfolio project

## Status

Accepted — 2026-09-08

## Context

Briefly was previously evaluated as a publicly deployed demonstration. The selected free-tier host introduced long waits when the application had to wake or rebuild, so the result was not reliably live for reviewers. The Gemini API key also has quota limits and should not be shared through a public generation workflow.

The completed product is a single-owner Personal Workspace with local SQLite storage, a local Solid Queue process, and a server-side Gemini API key. A live public deployment would add hosting and credential constraints without improving the core portfolio evidence. Screenshots already communicate the locked workspace, the main workflow, and a completed Brief.

## Decision

Publish Briefly as a downloadable local-first portfolio project rather than a hosted public service.

- Keep the Personal Workspace as the sole product mode.
- Keep Gemini configuration in local environment variables and never commit API keys.
- Document native local setup and retain Docker Compose as an optional local path.
- Use screenshots and the README as the public demonstration surface.
- Do not provide a shared public generation endpoint or promise a live hosted demo.

## Consequences

Reviewers can run and inspect the application without depending on a sleeping host, a public database, or another person's Gemini quota. The trade-off is that reviewers must install the local dependencies and provide their own Gemini API key to generate new Briefs. The repository should explain those limitations clearly.
